{
  description = "A very basic flake";

  inputs = {
    devenv.url = "github:cachix/devenv";
    flake-utils.url = "github:numtide/flake-utils";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, devenv, flake-utils, fenix }:
    {
      cleanSourceWithExts = { src, exts, pkgs, craneLib }:
        let
          exts' = if builtins.isList exts then exts else [ exts ];
        in
        pkgs.lib.cleanSourceWith
          {
            inherit src;
            filter = path: type:
              let
                baseName = builtins.baseNameOf (toString path);
              in
              (craneLib.filterCargoSources path type) || (!(builtins.elem baseName exts') && type != "directory");
          };

      mkNextest = { src, craneLib, buildInputs, pkgs }:
        craneLib.mkCargoDerivation {
          inherit src;

          buildInputs = buildInputs ++ [
            pkgs.cargo-nextest
          ];

          cargoArtifacts = craneLib.buildDepsOnly {
            inherit src buildInputs;
            CARGO_PROFILE = "";
          };

          buildPhaseCargoCommand = ''
            mkdir -p $out
            cargo nextest archive --archive-file $out/archive.tar.zst
          '';
        };

      mkDevenvModules = { pkgs, libs, rustToolchain }:

        with pkgs; [
          {
            languages.rust = {
              enable = true;
              # version = rustVersion;
              packages = {
                rust-src = rustToolchain;
                rustc = rustToolchain;
                cargo = rustToolchain;
                rustfmt = rustToolchain;
                clippy = rustToolchain;
              };
            };

            env.RUSTFLAGS = (builtins.map (a: ''-L ${a}/lib'') libs) ++ (lib.optionals stdenv.isDarwin (with darwin.apple_sdk; [
              "-L framework=${frameworks.Security}/Library/Frameworks"
            ]));

            scripts.cargo-udeps.exec = ''
              PATH=${fenix.packages.${system}.latest.rustc}/bin:$PATH
              ${pkgs.cargo-udeps}/bin/cargo-udeps $@
            '';
          }
        ];
    };
}
