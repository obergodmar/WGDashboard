# NixOS

This repository exposes WGDashboard as a flake package and as a native NixOS
service. WireGuard and AmneziaWG implementations are deliberately supplied by
the host system instead of being bundled into WGDashboard.

```nix
{
  inputs.wgdashboard = {
    url = "github:obergodmar/WGDashboard/nixos";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Import `inputs.wgdashboard.nixosModules.default`, then configure the service:

```nix
{
  services.wgdashboard = {
    enable = true;
    dataDir = "/var/lib/wgdashboard/data";
    initialAdminPasswordFile = config.age.secrets.wgdashboard-password.path;

    settings = {
      Server.dashboard_language = "en-US";
      Peers.peer_global_DNS = "1.1.1.1,1.0.0.1";
    };

    protocols.amneziawg = {
      enable = true;
      package = pkgs.amneziawg-tools;
      kernelModulePackage = config.boot.kernelPackages.amneziawg;
      # userspaceImplementation = pkgs.amneziawg-go;
    };
  };
}
```

`initialAdminPasswordFile` is used only when the state directory has no account
configuration yet. Existing installations keep their password hash.

`settings` is rendered as an INI fragment and merged into `wg-dashboard.ini`
before every service start. Declared values override changes made through the
web interface; omitted values remain mutable. Never place secrets in `settings`
because the generated fragment is stored in the world-readable Nix store.
Password and TOTP lifecycle fields are rejected by the module. Change an
existing password and enroll or reset TOTP through WGDashboard's Account UI;
the initial password file is intentionally not a declarative password-rotation
mechanism.

The AmneziaWG tools, kernel module, and optional userspace implementation must
implement compatible protocol versions. AWG 3.x requires matching recent tools
and kernel/userspace support; the module intentionally does not pin these
packages. Protocol keys and complete tunnel configurations are runtime state and
must not be written as Nix option values, because Nix expressions and generated
store paths are not secret.

See [AMNEZIAWG.md](AMNEZIAWG.md) for the supported AWG 3.x fields and
compatibility requirements.

Interfaces recorded by WGDashboard are not started automatically unless
`services.wgdashboard.autostartInterfaces` is explicitly enabled.
