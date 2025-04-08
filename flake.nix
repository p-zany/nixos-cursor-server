{
  description = "NixOS Windsurf server";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    {
      nixosModule = self.nixosModules.default; # Deprecrated, but perhaps still in use.
      nixosModules.default = import ./modules/windsurf-server;
      nixosModules.home = self.homeModules.default; # Backwards compatiblity.
      homeModules.default = import ./modules/windsurf-server/home.nix; # Consistent with homeConfigurations.
    }
    // (let
      inherit (flake-utils.lib) defaultSystems eachSystem;
    in
      eachSystem defaultSystems (system: let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs.lib) hasSuffix optionalAttrs;
        auto-fix-windsurf-server = pkgs.callPackage ./pkgs/auto-fix-windsurf-server.nix { };
      in
        # The package depends on `inotify-tools` which is only available on Linux.
        optionalAttrs (hasSuffix "-linux" system) {
          packages = {
            inherit auto-fix-windsurf-server;
            default = auto-fix-windsurf-server;
          };
          checks = {
            inherit auto-fix-windsurf-server;
          };
        }));
}
