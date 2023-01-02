{
  description = "A very basic flake";

  inputs = {
    devenv.url = "github:cachix/devenv";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, devenv, flake-utils }:
    {
      cleanSourceWithExts = { src, exts, craneLib }:
        let
          exts' = if builtins.isList exts then exts else [ exts ];
        in
        craneLib.cleanSourceWith
          {
            filter = path: type:
              let
                baseName = builtins.baseNameOf (toString path);
              in
              !(builtins.elem baseName exts') && type != "directory";
          }
          src;

      mkNextest = { src, craneLib, buildInputs, pkgs }:
        craneLib.mkCargoDerivation {
          inherit src buildInputs;

          cargoArtifacts = craneLib.buildDepsOnly {
            inherit src buildInputs;
            CARGO_PROFILE = "";
          };

          buildPhaseCargoCommand = ''
            mkdir -p $out
            ${pkgs.cargo-nextest}/bin/cargo-nextest archive --archive-file $out/archive.tar.zst
          '';
        };

      mkDevenvModules = pkgs: libs:

        with pkgs; [
          {
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
