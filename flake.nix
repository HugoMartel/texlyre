{
  description = "Flake for TexLyre a LaTeX and Typst collaboration platform.";

  # Nixpkgs / NixOS version to use.
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";

    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
    }:
    let

      lib = nixpkgs.lib;

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;

    in

    {

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            # config.allowUnfree = true;
          };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nodejs
              yarn
              biome
              typescript-language-server
            ];
          };
        }
      ); # END devShells

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        rec {
          texlyre = pkgs.callPackage ./nix/package.nix { };
          default = texlyre;
        }
      ); # END packages

      nixosModules = rec {
        texlyre = import ./nix/nixos-module.nix self.packages;
        default = texlyre;
      }; # END nixosModules

      formatter = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          treefmtEval = treefmt-nix.lib.evalModule pkgs {
            # Used to find the project root
            projectRootFile = "flake.nix";

            # Which formatters to enable
            programs = {
              # Nix formatter
              nixfmt.enable = true;
              # Js/Ts formatter
              # TODO: use biome like in package.json
            };
          };
        in
        treefmtEval.config.build.wrapper
      ); # END formatter

    }; # END Outputs
}
