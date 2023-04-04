{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        });
    in {
      overlay = final: prev: {
        jpm = prev.jpm.overrideAttrs (old: rec {
          src = builtins.fetchGit {
            url = "https://github.com/janet-lang/jpm.git";
            rev = "6771439785aea36c76c5aec7c2d7f67df83c46bb";
          };
        });

        janet-nix = with final;
          stdenv.mkDerivation {
            name = "janet-nix";

            buildInputs = [ janet jpm ];

            src = ./.;

            buildPhase = ''
              # localize jpm dependency paths
              export JANET_PATH="$PWD/.jpm"
              export JANET_TREE="$JANET_PATH/jpm_tree"
              export JANET_LIBPATH="${pkgs.janet}/lib"
              export JANET_HEADERPATH="${pkgs.janet}/include/janet"
              export JANET_BUILDPATH="$JANET_PATH/build"
              export PATH="$PATH:$JANET_TREE/bin"
              mkdir -p "$JANET_TREE"
              mkdir -p "$JANET_BUILDPATH"

              jpm build
              jpm quickbin main.janet $name
            '';

            installPhase = ''
              mkdir -p $out/bin
              cp $name $out/bin/
              chmod +x $out/bin/$name
            '';
          };

        mkJanet = { name, version, src, entryPoint }:
          with final;
          let
            deps = (import (pkgs.runCommandLocal "run-janet-nix" {
              inherit src;
              buildInputs = [ janet-nix ];
            } ''
              cp $src/lockfile.jdn .
              janet-nix > $out
            ''));
            sources = (builtins.map builtins.fetchGit deps);

          in stdenv.mkDerivation {
            inherit name version sources src entryPoint;

            buildInputs = [ janet jpm ];

            buildPhase = ''
              # localize jpm dependency paths
              export JANET_PATH="$PWD/.jpm"
              export JANET_TREE="$JANET_PATH/jpm_tree"
              export JANET_LIBPATH="${pkgs.janet}/lib"
              export JANET_HEADERPATH="${pkgs.janet}/include/janet"
              export JANET_BUILDPATH="$JANET_PATH/build"
              export PATH="$PATH:$JANET_TREE/bin"
              mkdir -p "$JANET_TREE"
              mkdir -p "$JANET_BUILDPATH"
              mkdir -p "$PWD/.pkgs"

              # fetch packages from the lockfile, mount repos
              for source in $sources; do
                 cp -r "$source" "$PWD/.pkgs"
              done
              chmod +w -R "$PWD/.pkgs"

              # install each package
              for source in "$PWD/.pkgs/"*; do
                 pushd "$source"
                 jpm install
                 popd
              done

              jpm build
              jpm quickbin "$entryPoint" $name'';

            installPhase = ''
              mkdir -p $out/bin
              cp $name $out/bin/
              chmod +x $out/bin/$name
            '';
          };
      };

      templates.default = {
        path = ./templates/default;
        description = "A simple janet-nix project";
      };

      packages = forAllSystems (system: {
        janet-nix = nixpkgsFor.${system}.janet-nix;
        mkJanet = nixpkgsFor.${system}.mkJanet;
      });

      defaultPackage =
        forAllSystems (system: self.packages.${system}.janet-nix);

      devShell = forAllSystems (system:
        with nixpkgsFor.${system};
        mkShell {
          packages = [ janet jpm cntr ];
          buildInputs = [ janet ];
          shellHook = ''
            # localize jpm dependency paths
            export JANET_PATH="$PWD/.jpm"
            export JANET_TREE="$JANET_PATH/jpm_tree"
            export JANET_LIBPATH="${pkgs.janet}/lib"
            export JANET_HEADERPATH="${pkgs.janet}/include/janet"
            export JANET_BUILDPATH="$JANET_PATH/build"
            export PATH="$PATH:$JANET_TREE/bin"
            mkdir -p "$JANET_TREE"
            mkdir -p "$JANET_BUILDPATH"
          '';
        });
    };
}
