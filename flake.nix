{
  description = "Pigeons - carrier pigeons for your SSH connections";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  };
  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      perSystem = { system, pkgs, ... }:
        let
          pkg = pkgs.callPackage ./nix/package.nix { };
        in {
          packages.default = pkg;
          devShells.default = pkgs.mkShell { packages = [ pkg ]; };
        };
    };
}
