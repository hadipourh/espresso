{
  description = "Nix package for expresso and development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {

        packages = {
          default = self.packages.${system}.espresso;
          espresso = pkgs.callPackage ./default.nix { };
        };

        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs; [
              clang-tools
              cmake
              cmake-format
              prettier
              shfmt
            ];
          };
        };

      }
    ))
    // {

      overlay = self.overlays.default;

      overlays = {
        default = self.overlays.espresso;
        espresso = final: prev: { espresso = prev.callPackage ./default.nix {}; };
      };

    };
}
