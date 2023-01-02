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

  outputs = { self, nixpkgs, devenv, fenix, flake-utils }:
    {
      mkNextest = src: craneLib: buildInputs:
        craneLib.mkCargoDerivation {
          inherit src buildInputs;

          cargoArtifacts = craneLib.buildDepsOnly {
            inherit src buildInputs;
            CARGO_PROFILE = "";
          };

          buildPhaseCargoCommand = ''
            mkdir -p $out
            cargo nextest archive --archive-file $out/archive.tar.zst
          '';
        };

      mkDevenvModules = pkgs:

        with pkgs; [
          {
            # env.RUSTFLAGS = (builtins.map (a: ''-L ${a}/lib'') nativeBuildInputs) ++ (lib.optionals stdenv.isDarwin (with darwin.apple_sdk; [
            env.RUSTFLAGS = (lib.optionals stdenv.isDarwin (with darwin.apple_sdk; [
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
