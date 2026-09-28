{
  description = "WGDashboard with a native NixOS service module";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          wgdashboard = pkgs.callPackage ./nix/package.nix { src = self; };
        in
        {
          inherit wgdashboard;
          default = wgdashboard;
        }
      );

      nixosModules = rec {
        wgdashboard = import ./nix/module.nix { inherit self; };
        default = wgdashboard;
      };

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          package = self.packages.${system}.wgdashboard;
          nixos-module = pkgs.testers.runNixOSTest (
            import ./nix/tests/wgdashboard.nix {
              inherit pkgs;
              module = self.nixosModules.wgdashboard;
            }
          );
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
