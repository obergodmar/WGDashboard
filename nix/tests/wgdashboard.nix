{
  module,
  pkgs,
}:

{
  name = "wgdashboard";

  nodes = {
    machine = {
      imports = [ module ];

      services.wgdashboard = {
        enable = true;
        dataDir = "/var/lib/wgdashboard/data";
        initialAdminPasswordFile = "/etc/wgdashboard-password";
        protocols.amneziawg.enable = true;
        settings = {
          Server.dashboard_language = "ru-RU";
          Peers.peer_global_DNS = "1.1.1.1,1.0.0.1";
          Clients.sign_up = false;
        };
      };

      environment = {
        etc."wgdashboard-password" = {
          text = "correct horse battery staple";
          mode = "0400";
        };
        systemPackages = [
          pkgs.amneziawg-tools
          pkgs.curl
          pkgs.jq
          pkgs.wireguard-tools
        ];
      };

      assertions = [
        {
          assertion = pkgs.lib.versionAtLeast pkgs.amneziawg-tools.version "3.0";
          message = "The WGDashboard integration test requires AmneziaWG 3.x tools";
        }
      ];
    };

    existing = {
      imports = [ module ];

      services.wgdashboard = {
        enable = true;
        dataDir = "/var/lib/wgdashboard/data";
        initialAdminPasswordFile = null;
        settings.Server.dashboard_theme = "light";
      };

      systemd.services.seed-wgdashboard-state = {
        requiredBy = [ "wgdashboard.service" ];
        before = [ "wgdashboard.service" ];
        serviceConfig.Type = "oneshot";
        script = ''
          install -d -m 0700 /var/lib/wgdashboard/data
          printf '%s\n' \
            '[Account]' \
            'username = existing-admin' \
            'password = existing-password-hash' \
            '[Server]' \
            'dashboard_theme = dark' \
            > /var/lib/wgdashboard/data/wg-dashboard.ini
          chmod 0600 /var/lib/wgdashboard/data/wg-dashboard.ini
        '';
      };
    };
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("wgdashboard.service")
    machine.wait_for_open_port(10086)
    existing.wait_for_unit("wgdashboard.service")
    existing.wait_for_open_port(10086)
    existing.succeed(
      "grep --quiet '^username = existing-admin$' /var/lib/wgdashboard/data/wg-dashboard.ini"
    )
    existing.succeed(
      "grep --quiet '^wg_conf_path = /var/lib/wgdashboard/wireguard$' "
      "/var/lib/wgdashboard/data/wg-dashboard.ini"
    )
    machine.succeed("awg --version | grep --quiet 'v3\\.'")
    machine.succeed("test $(stat --format=%a /var/lib/wgdashboard/data/wg-dashboard.ini) = 600")
    machine.fail("grep --quiet 'correct horse battery staple' /var/lib/wgdashboard/data/wg-dashboard.ini")
    machine.succeed(
      "grep --quiet '^dashboard_language = ru-RU$' /var/lib/wgdashboard/data/wg-dashboard.ini"
    )
    machine.succeed(
      "grep --quiet '^peer_global_dns = 1.1.1.1,1.0.0.1$' /var/lib/wgdashboard/data/wg-dashboard.ini"
    )
    machine.succeed("grep --quiet '^sign_up = false$' /var/lib/wgdashboard/data/wg-dashboard.ini")
    existing.succeed(
      "grep --quiet '^dashboard_theme = light$' /var/lib/wgdashboard/data/wg-dashboard.ini"
    )

    machine.succeed(
      "private_key=$(wg genkey); "
      "printf '[Interface]\\nPrivateKey = %s\\nAddress = 10.23.42.1/24\\nListenPort = 51820\\n' "
      '"$private_key" > /var/lib/wgdashboard/wireguard/wgtest.conf'
    )
    machine.succeed(
      "private_key=$(awg genkey); header_key=$(awg genkey); peer_private=$(awg genkey); "
      "peer_public=$(printf '%s' \"$peer_private\" | awg pubkey); "
      "printf '%s' \"$peer_public\" > /tmp/awg-peer-public; "
      "printf '[Interface]\\nPrivateKey = %s\\nAddress = 10.23.43.1/24\\nListenPort = 51821\\nJc = 5\\nJmin = 10\\nJmax = 42\\nS1 = 32\\nS2 = 32\\nS3 = 32\\nS4 = 32\\nH1 = 1\\nH2 = 2\\nH3 = 3\\nH4 = 4\\nHeaderProtectionKey = %s\\nContentPaddingAddition = 0-64\\nRekeyAfterTime = 100-140\\nRekeyTimeout = 4-7\\nRejectAfterTime = 160-200\\nKeepaliveTimeout = 8-12\\nMaxHandshakeAttempts = 14-20\\nRandomTrailers = on\\nDisableCookies = off\\n\\n[Peer]\\nPublicKey = %s\\nAllowedIPs = 10.23.43.2/32\\nPersistentKeepalive = 20-30\\n' "
      '"$private_key" "$header_key" "$peer_public" > /var/lib/wgdashboard/amneziawg/awgtest.conf'
    )
    machine.succeed("chmod 600 /var/lib/wgdashboard/{wireguard/wgtest.conf,amneziawg/awgtest.conf}")

    machine.succeed(
      "curl --fail --silent --cookie-jar /tmp/wgdashboard-cookies "
      "--header 'Content-Type: application/json' "
      "--data '{\"username\":\"admin\",\"password\":\"correct horse battery staple\",\"totp\":\"\"}' "
      "http://127.0.0.1:10086/api/authenticate | jq --exit-status .status"
    )
    machine.succeed(
      "curl --fail --silent --cookie /tmp/wgdashboard-cookies "
      "http://127.0.0.1:10086/api/getWireguardConfigurations "
      "| jq --exit-status '(.data | map(.Name) | sort) == [\"awgtest\", \"wgtest\"]'"
    )
    machine.succeed(
      "curl --fail --silent --cookie /tmp/wgdashboard-cookies "
      "--get --data-urlencode id@/tmp/awg-peer-public "
      "http://127.0.0.1:10086/api/downloadPeer/awgtest "
      "| jq --raw-output --exit-status .data.file > /tmp/awg-peer.conf"
    )
    machine.succeed("grep --quiet '^HeaderProtectionKey = ' /tmp/awg-peer.conf")
    machine.succeed("grep --quiet '^ContentPaddingAddition = 0-64$' /tmp/awg-peer.conf")
    machine.succeed("grep --quiet '^PersistentKeepalive = 20-30$' /tmp/awg-peer.conf")

    machine.succeed(
      "curl --fail --silent --cookie /tmp/wgdashboard-cookies "
      "'http://127.0.0.1:10086/api/toggleWireguardConfiguration?configurationName=wgtest' "
      "| jq --exit-status .status"
    )
    machine.succeed("ip link show wgtest")

    machine.stop_job("wgdashboard.service")
    machine.succeed("ip link delete wgtest")
    machine.start_job("wgdashboard.service")
    machine.wait_for_unit("wgdashboard.service")
    machine.wait_for_open_port(10086)
    machine.fail("ip link show wgtest")

    machine.succeed(
      "curl --fail --silent --cookie-jar /tmp/wgdashboard-cookies "
      "--header 'Content-Type: application/json' "
      "--data '{\"username\":\"admin\",\"password\":\"correct horse battery staple\",\"totp\":\"\"}' "
      "http://127.0.0.1:10086/api/authenticate | jq --exit-status .status"
    )
    machine.succeed(
      "curl --fail --silent --cookie /tmp/wgdashboard-cookies "
      "'http://127.0.0.1:10086/api/toggleWireguardConfiguration?configurationName=awgtest' "
      "| jq --exit-status .status"
    )
    machine.succeed("ip link show awgtest")
    machine.succeed("awg showconf awgtest | grep --quiet '^ContentPaddingAddition = 0-64$'")
    machine.succeed("awg showconf awgtest | grep --quiet '^RandomTrailers = on$'")
    machine.succeed("awg showconf awgtest | grep --quiet '^PersistentKeepalive = 20-30$'")
    machine.succeed(
      "curl --fail --silent --cookie /tmp/wgdashboard-cookies "
      "'http://127.0.0.1:10086/api/toggleWireguardConfiguration?configurationName=awgtest' "
      "| jq --exit-status .status"
    )
    machine.fail("ip link show awgtest")
  '';
}
