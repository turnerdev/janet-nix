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
              jpm quickbin main.janet quickbin-out
            '';

            installPhase = ''
              mkdir -p $out/bin
              mv quickbin-out $out/bin/$name
              chmod +x $out/bin/$name
            '';
          };

        mkJanet = { name, src, main ? null, quickbin ? null, version ? null
          , bin ? null, buildInputs ? [ ], extraDeps ? [ ] }:
          with final;
          let
            deps = (import (pkgs.runCommandLocal "run-janet-nix" {
              inherit src;
              buildInputs = [ janet-nix ];
            } ''
              if [ -f "$src/lockfile.jdn" ]; then
                cp $src/lockfile.jdn .
                janet-nix > $out
              else
                echo "[]" > $out
              fi
            ''));
            sources = (builtins.map builtins.fetchGit (deps ++ extraDeps));
          in stdenv.mkDerivation {
            inherit name version src main quickbin bin sources;

            buildInputs = [ janet jpm ] ++ buildInputs;

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
              jpm install

              # if passed a main script, copy it into the project and use it for quickbin
              if [ -n "$main" ]; then
                quickbin=janet-nix-main.janet
                echo "$main" > $quickbin
              fi

              if [ -n "$quickbin" ]; then
                jpm quickbin "$quickbin" quickbin-out
              fi
            '';

            installPhase = ''
              mkdir -p $out/bin

              # if we have quickbin output, use that as the result
              if [ -f "quickbin-out" ]; then
                mv quickbin-out $out/bin/$name

              # else if a binary is explicitly passed to mkJanet, use that
              elif [ -n "$bin" ]; then
                mv "$JANET_TREE/bin/$bin" $out/bin/$name
              fi

              chmod +x $out/bin/$name
            '';
          };
      };

      templates = {
        default = {
          path = ./templates/default;
          description = "A simple janet-nix project";
        };
        full = {
          path = ./templates/full;
          description = "A janet-nix project with dev tools";
        };
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
