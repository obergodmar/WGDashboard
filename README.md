> [!WARNING]
> All users running WGDashboard v4.2.x or later and hosted on the public internet are strongly advised to update to the latest release immediately. For more information: [v4.3.2 Release](https://github.com/WGDashboard/WGDashboard/releases/tag/v4.3.2)

> [!TIP]
> 🎉 To help us better understand and improve WGDashboard’s performance, we’re launching the **WGDashboard Testing Program**. As part of this program, participants will receive free WireGuard VPN access to our server in Toronto, Canada, valid for **24 hours** or up to **1GB of total traffic**—whichever comes first. If you’d like to join, visit [https://wg.wgdashboard.dev/](https://wg.wgdashboard.dev/) for more details!


![](https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Posters/Banner.png)


<p align="center">
  <img alt="WGDashboard" src="https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Logos/Logo-2-Rounded-512x512.png" width="128">
</p>
<h1 align="center">
  <a href="https://wgdashboard.dev">WGDashboard</a>
</h1>
<p align="center">
    <img src="https://img.shields.io/badge/Made_With-Python-blue?style=for-the-badge&logo=python&logoColor=ffffff">
    <img src="https://img.shields.io/badge/Made_With-Vue.js-42b883?style=for-the-badge&logo=vuedotjs&logoColor=ffffff">
    <img src="https://img.shields.io/badge/License-Apache_License_2.0-D22128?style=for-the-badge&logo=apache&logoColor=ffffff">
</p>

<p align="center">
  <a href="https://github.com/WGDashboard/WGDashboard/releases/latest"><img src="https://img.shields.io/github/v/release/donaldzou/wireguard-dashboard?style=for-the-badge"></a>
  <a href="https://wakatime.com/badge/github/donaldzou/WGDashboard"><img src="https://wakatime.com/badge/user/45f53c7c-9da9-4cb0-85d6-17bd38cc748b/project/5334ae20-e9a6-4c55-9fea-52d4eb9dfba6.svg?style=for-the-badge" alt="wakatime"></a>
  <a href="https://hitscounter.dev"><img src="https://hitscounter.dev/api/hit?url=https%3A%2F%2Fgithub.com%2Fdonaldzou%2FWGDashboard&label=Visitor&icon=github&color=%230a58ca&style=for-the-badge"></a>
  <img src="https://img.shields.io/docker/pulls/donaldzou/wgdashboard?logo=docker&label=Docker%20Image%20Pulls&labelColor=ffffff&style=for-the-badge">
  <img src="https://github.com/WGDashboard/WGDashboard/actions/workflows/docker.yml/badge.svg?style=for-the-badge">
  <img src="https://github.com/WGDashboard/WGDashboard/actions/workflows/codeql-analyze.yaml/badge.svg">
</p>
<p align="center"><b>This project is supported by</b></p>
<p align="center">
  <a href="https://m.do.co/c/a84cb9aac585">
    <img src="https://opensource.nyc3.cdn.digitaloceanspaces.com/attribution/assets/SVG/DO_Logo_horizontal_blue.svg" width="201px">
  </a>
</p>
<p align="center">Monitoring WireGuard is not convenient, in most case, you'll need to login to your server and type <code>wg show</code>. That's why this project is being created, to view and manage all WireGuard configurations in an easy way.</p>
<p align="center">Though all these awesome features are present, we are still striving to make it <b>easy to install and use</b></p>

<p align="center"><b><i>This project is not affiliated to the official WireGuard Project</i></b></p>

<h3 align="center">Looking for help or want to chat about this project?</h4>
<p align="center">
  You can reach out at
</p>
<p align="center">
  <a align="center" href="https://discord.gg/72TwzjeuWm" target="_blank"><img src="https://img.shields.io/discord/1276818723637956628?labelColor=ffffff&style=for-the-badge&logo=discord&label=Discord"></a>
  <a align="center" href="https://www.reddit.com/r/WGDashboard/" target="_blank"><img src="https://img.shields.io/badge/Reddit-r%2FWGDashboard-FF4500?style=for-the-badge&logo=reddit"></a>
  <a align="center" href="https://app.element.io/#/room/#wgd:matrix.org" target="_blank"><img src="https://img.shields.io/badge/Matrix_Chatroom-%23WGD-000000?style=for-the-badge&logo=matrix"></a>
</p>
<h3 align="center">Want to support this project?</h4>
<p align="center">
  You can support via <br>
</p>
<p align="center">
  <a align="center" href="https://github.com/sponsors/WGDashboard" target="_blank"><img src="https://img.shields.io/badge/GitHub%20Sponsor-2e9a40?style=for-the-badge&logo=github"></a>
  <a align="center" href="https://buymeacoffee.com/donaldzou" target="_blank"><img src="https://img.shields.io/badge/Buy%20me%20a%20coffee-ffdd00?style=for-the-badge&logo=buymeacoffee&logoColor=000000"></a>
  <a align="center" href="https://patreon.com/c/DonaldDonnyZou/membership" target="_blank"><img src="https://img.shields.io/badge/Patreon-000000?style=for-the-badge&logo=patreon&logoColor=ffffff"></a>
</p>

<p align="center">
  <b>or, visit our merch store and support us by purchasing a merch for only $USD 17.00 (Including shipping worldwide & duties)</b>
</p>
<p align="center">
  <a align="center" href="https://merch.wgdashboard.dev" target="_blank"><img src="https://img.shields.io/badge/Merch%20from%20WGDashboard-926183?style=for-the-badge"></a>
</p>

<hr>
<h4 align="center">
  for more information, visit our
</h4>
<h1 align="center">
  <a href="https://wgdashboard.dev">Official Website</a>
</h1>

# Deployment with Nix flakes

This repository provides both a package and a native NixOS module. The module
runs WGDashboard directly under systemd; it does not use the Docker image or
bundle WireGuard and AmneziaWG implementations into the application.

Add WGDashboard to the consumer flake and make its `nixpkgs` input follow the
consumer's revision:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    wgdashboard = {
      url = "github:obergodmar/WGDashboard/nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, wgdashboard, ... }:
    {
      nixosConfigurations.vpn-host = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          wgdashboard.nixosModules.default
          (
            { config, pkgs, ... }:
            {
              services.wgdashboard = {
                enable = true;
                listenAddress = "127.0.0.1";
                port = 10086;
                dataDir = "/var/lib/wgdashboard/data";

                # Provision this runtime file with agenix, sops-nix, or another
                # secret manager before the first service start.
                initialAdminPasswordFile = "/run/secrets/wgdashboard-admin-password";

                # Non-secret values are reconciled into wg-dashboard.ini before
                # every service start. Settings omitted here remain editable in
                # the web interface.
                settings = {
                  Server = {
                    dashboard_language = "en-US";
                    dashboard_theme = "dark";
                  };
                  Peers.peer_global_DNS = "1.1.1.1,1.0.0.1";
                  Clients.sign_up = false;
                };

                protocols.amneziawg = {
                  enable = true;

                  # These packages come from the consumer's package set. An
                  # overlay can pin or replace them without rebuilding or
                  # patching WGDashboard itself.
                  package = pkgs.amneziawg-tools;
                  kernelModulePackage = config.boot.kernelPackages.amneziawg;

                  # For a userspace-only deployment, use these instead:
                  # kernelModulePackage = null;
                  # userspaceImplementation = pkgs.amneziawg-go;
                };
              };
            }
          )
        ];
      };
    };
}
```

`protocols.amneziawg.package`, `kernelModulePackage`, and
`userspaceImplementation` are deliberately consumer-controlled. This allows a
deployment to provide mutually compatible AmneziaWG tools, kernel, and
userspace versions through its own `nixpkgs` revision or overlays. AWG 3.x
requires compatible 3.x implementations on both ends of the tunnel.

The initial password file is read only while creating a new configuration. For
an existing installation that already has `wg-dashboard.ini`, set
`initialAdminPasswordFile = null`.

`services.wgdashboard.settings` generates an INI fragment and merges it into
the mutable `wg-dashboard.ini` before every service start. Declared keys are
therefore managed declaratively and override later UI changes, while omitted
keys remain under WGDashboard's control. Do not put passwords, tokens, tunnel
keys, or other secrets in `settings`: generated Nix store paths are world
readable. Supply bootstrap passwords through `initialAdminPasswordFile` and
keep complete tunnel configurations outside Nix expressions. Password and TOTP
lifecycle fields are rejected by the module. Change an existing password in
WGDashboard's Account settings. Enroll or reset TOTP through the web interface,
where the secret seed can be shown as a QR code and verified before MFA is
enabled.

Build and activate the host in the usual way:

```console
sudo nixos-rebuild switch --flake .#vpn-host
```

See [docs/NIXOS.md](docs/NIXOS.md) for all module options and
[docs/AMNEZIAWG.md](docs/AMNEZIAWG.md) for the supported AWG 3.x fields.


# Screenshots
<img src="https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Documentation%20Images/sign-in.png" alt=""/>
<img src="https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Documentation%20Images/cross-server.png" alt=""/>
<img src="https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Documentation%20Images/index.png" alt=""/>
<img src="https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Documentation%20Images/new-configuration.png" alt="" />
<img src="https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Documentation%20Images/settings.png" alt="" />
<img src="https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Documentation%20Images/light-dark.png" alt="" />
<img src="https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Documentation%20Images/configuration.png" alt=""/>
<img src="https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Documentation%20Images/add-peers.png" alt="" />
<img src="https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Documentation%20Images/ping.png" alt=""/>
<img src="https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Documentation%20Images/traceroute.png" alt=""/>
