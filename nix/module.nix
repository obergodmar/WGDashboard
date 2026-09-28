{ self }:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.wgdashboard;
  settingsFormat = pkgs.formats.ini { };
  settingsFile = settingsFormat.generate "wgdashboard-settings.ini" cfg.settings;
  forbiddenSettings = {
    Account = [
      "password"
      "totp_key"
      "enable_totp"
      "totp_verified"
    ];
    Database = [ "password" ];
    Email = [ "email_password" ];
  };
  configuredForbiddenSettings = lib.concatMap (
    section:
    let
      configuredKeys = builtins.attrNames (cfg.settings.${section} or { });
    in
    map (key: "${section}.${key}") (
      builtins.filter (
        forbiddenKey: lib.any (configuredKey: lib.toLower configuredKey == forbiddenKey) configuredKeys
      ) forbiddenSettings.${section}
    )
  ) (builtins.attrNames forbiddenSettings);
  stateDirectory = "/var/lib/wgdashboard";
  bindAddress =
    if lib.hasInfix ":" cfg.listenAddress then
      "[${cfg.listenAddress}]:${toString cfg.port}"
    else
      "${cfg.listenAddress}:${toString cfg.port}";
  initializeCommand = lib.escapeShellArgs (
    [
      (lib.getExe' cfg.package "wgdashboard-initialize")
      "--configuration-path"
      cfg.dataDir
      "--settings-file"
      settingsFile
    ]
    ++ lib.optionals (cfg.initialAdminPasswordFile != null) [
      "--password-file"
      "%d/initial-admin-password"
    ]
    ++ [
      "--username"
      cfg.initialAdminUsername
      "--listen-address"
      cfg.listenAddress
      "--port"
      (toString cfg.port)
      "--wireguard-path"
      cfg.protocols.wireguard.configurationDirectory
      "--amneziawg-path"
      cfg.protocols.amneziawg.configurationDirectory
    ]
  );
in
{
  options.services.wgdashboard = {
    enable = lib.mkEnableOption "WGDashboard";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.wgdashboard;
      defaultText = lib.literalExpression "inputs.wgdashboard.packages.${pkgs.system}.wgdashboard";
      description = "WGDashboard package to run.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address on which WGDashboard listens.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 10086;
      description = "TCP port on which WGDashboard listens.";
    };

    openFirewall = lib.mkEnableOption "opening the WGDashboard TCP port in the firewall";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = stateDirectory;
      description = "Directory containing WGDashboard's mutable configuration and databases.";
    };

    initialAdminUsername = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = ''
        Administrator username written when WGDashboard is initialized for the first time.
        Changing this option does not modify an existing installation.
      '';
    };

    initialAdminPasswordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        File containing the administrator password used when WGDashboard is initialized for
        the first time. The password must be at least eight bytes long. Changing this file does
        not modify an existing installation. This may be `null` only when `dataDir` already
        contains an initialized `wg-dashboard.ini` file.
      '';
    };

    settings = lib.mkOption {
      inherit (settingsFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          Server = {
            dashboard_language = "en-US";
            dashboard_theme = "dark";
          };
          Peers.peer_global_DNS = "1.1.1.1,1.0.0.1";
          Clients.sign_up = false;
        }
      '';
      description = ''
        Non-secret settings merged into `wg-dashboard.ini` before every service start.
        Values declared here take precedence over changes made through the web interface;
        settings omitted here remain mutable. Passwords, tokens, tunnel keys, and other
        secrets must not be placed here because the generated INI fragment is stored in
        the world-readable Nix store. Account password and TOTP lifecycle fields, database
        password, and email password are rejected explicitly.
      '';
    };

    autostartInterfaces = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Start interfaces recorded in WGDashboard's mutable autostart list when the service starts.
        This is disabled by default so that enabling the module cannot unexpectedly activate an
        existing tunnel configuration.
      '';
    };

    protocols = {
      wireguard = {
        package = lib.mkPackageOption pkgs "wireguard-tools" { };

        configurationDirectory = lib.mkOption {
          type = lib.types.path;
          default = "${stateDirectory}/wireguard";
          description = "Directory containing WireGuard interface configuration files.";
        };
      };

      amneziawg = {
        enable = lib.mkEnableOption "AmneziaWG protocol support";

        package = lib.mkPackageOption pkgs "amneziawg-tools" { };

        configurationDirectory = lib.mkOption {
          type = lib.types.path;
          default = "${stateDirectory}/amneziawg";
          description = "Directory containing AmneziaWG interface configuration files.";
        };

        kernelModulePackage = lib.mkOption {
          type = lib.types.nullOr lib.types.package;
          default = config.boot.kernelPackages.amneziawg;
          defaultText = lib.literalExpression "config.boot.kernelPackages.amneziawg";
          description = ''
            AmneziaWG kernel module package. Set this to a custom package to select another
            compatible protocol implementation, or to `null` when using a userspace implementation.
          '';
        };

        userspaceImplementation = lib.mkOption {
          type = lib.types.nullOr lib.types.package;
          default = null;
          example = lib.literalExpression "pkgs.amneziawg-go";
          description = ''
            Optional userspace AmneziaWG implementation used by `awg-quick` when a kernel
            implementation is unavailable.
          '';
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = configuredForbiddenSettings == [ ];
        message = ''
          services.wgdashboard.settings contains fields that must not be stored in the Nix store
          or managed without their runtime lifecycle: ${lib.concatStringsSep ", " configuredForbiddenSettings}
        '';
      }
      {
        assertion =
          lib.all (directory: directory == stateDirectory || lib.hasPrefix "${stateDirectory}/" directory)
            [
              cfg.dataDir
              cfg.protocols.wireguard.configurationDirectory
              cfg.protocols.amneziawg.configurationDirectory
            ];
        message = "services.wgdashboard data directories must be inside ${stateDirectory}";
      }
    ];

    warnings = lib.optional (
      cfg.openFirewall
      && lib.elem cfg.listenAddress [
        "127.0.0.1"
        "::1"
      ]
    ) "services.wgdashboard.openFirewall is enabled, but listenAddress is a loopback address.";

    boot.kernelModules = [
      "wireguard"
    ]
    ++ lib.optional (
      cfg.protocols.amneziawg.enable && cfg.protocols.amneziawg.kernelModulePackage != null
    ) "amneziawg";

    boot.extraModulePackages = lib.optional (
      cfg.protocols.amneziawg.enable && cfg.protocols.amneziawg.kernelModulePackage != null
    ) cfg.protocols.amneziawg.kernelModulePackage;

    networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.port;

    systemd.tmpfiles.rules = map (directory: "d ${directory} 0700 root root -") [
      cfg.dataDir
      cfg.protocols.wireguard.configurationDirectory
      cfg.protocols.amneziawg.configurationDirectory
    ];

    systemd.services.wgdashboard = {
      description = "WGDashboard web interface";
      documentation = [ "https://docs.wgdashboard.dev/" ];
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      path = [
        pkgs.iproute2
        cfg.protocols.wireguard.package
      ]
      ++ lib.optional cfg.protocols.amneziawg.enable cfg.protocols.amneziawg.package
      ++ lib.optional (
        cfg.protocols.amneziawg.enable && cfg.protocols.amneziawg.userspaceImplementation != null
      ) cfg.protocols.amneziawg.userspaceImplementation;

      environment = {
        CONFIGURATION_PATH = cfg.dataDir;
        WGDASHBOARD_ASSET_PATH = "${cfg.package}/share/wgdashboard";
        WGDASHBOARD_AUTOSTART_INTERFACES = lib.boolToString cfg.autostartInterfaces;
        WGDASHBOARD_BIND = bindAddress;
      }
      //
        lib.optionalAttrs
          (cfg.protocols.amneziawg.enable && cfg.protocols.amneziawg.userspaceImplementation != null)
          {
            WG_QUICK_USERSPACE_IMPLEMENTATION = lib.getExe cfg.protocols.amneziawg.userspaceImplementation;
          };

      serviceConfig = {
        Type = "simple";
        WorkingDirectory = cfg.dataDir;
        StateDirectory = "wgdashboard";
        StateDirectoryMode = "0700";
        LoadCredential = lib.optional (
          cfg.initialAdminPasswordFile != null
        ) "initial-admin-password:${cfg.initialAdminPasswordFile}";
        ExecStartPre = initializeCommand;
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
        UMask = "0077";

        AmbientCapabilities = [
          "CAP_NET_ADMIN"
          "CAP_NET_RAW"
        ];
        CapabilityBoundingSet = [
          "CAP_NET_ADMIN"
          "CAP_NET_RAW"
        ];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = cfg.protocols.amneziawg.userspaceImplementation == null;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ stateDirectory ];
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
      };
    };
  };
}
