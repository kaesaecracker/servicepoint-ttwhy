{
  description = "Flake for servicepoint-ttwhy";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    servicepoint = {
      url = "github:cccb/servicepoint";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      naersk,
      servicepoint,
    }:
    let
      lib = nixpkgs.lib;
      supported-systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems = lib.genAttrs supported-systems;
      make-rust-toolchain-core =
        pkgs:
        pkgs.symlinkJoin {
          name = "rust-toolchain-core";
          paths = with pkgs; [
            rustc
            cargo
            rustPlatform.rustcSrc
          ];
        };
    in
    rec {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages."${system}";
          rust-toolchain-core = make-rust-toolchain-core pkgs;
          naersk' = pkgs.callPackage naersk {
            cargo = rust-toolchain-core;
            rustc = rust-toolchain-core;
          };
        in
        rec {
          servicepoint-ttwhy = naersk'.buildPackage rec {
            src = ./.;
            nativeBuildInputs = with pkgs; [
              pkg-config
              makeWrapper
            ];
            strictDeps = true;
            buildInputs = with pkgs; [ lzma ];
          };

          default = servicepoint-ttwhy;
        }
      );

      legacyPackages = packages;

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages."${system}";
          rust-toolchain = pkgs.symlinkJoin {
            name = "rust-toolchain";
            paths = with pkgs; [
              (make-rust-toolchain-core pkgs)
              rustfmt
              clippy
              cargo-expand
            ];
          };
        in
        {
          default = pkgs.mkShell rec {
            inputsFrom = [ servicepoint.packages.${system}.servicepoint ];
            packages = [ rust-toolchain ];
            LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath (builtins.concatMap (d: d.buildInputs) inputsFrom)}";
            RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
          };
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages."${system}".nixfmt-rfc-style);
    };
}
