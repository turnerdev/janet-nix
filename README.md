# janet-nix
[nix flake](https://nixos.wiki/wiki/Flakes) helpers for [Janet](https://janet-lang.org/) projects using the [jpm](https://janet-lang.org/docs/jpm.html) package manager.

Should be considered alpha.

## Prerequisites

Install dependencies for the current project create a lockfile:

```bash
jpm deps
jpm make-lockfile
```

## Usage

Use `mkJanet` to create derivations:

```nix
{
  packages = forAllSystems (system: {
    my-new-program = janet-nix.packages.${system}.mkJanet {
      name = "my-new-program";
      version = "0.0.1";
      src = ./.;
      entryPoint = ./init.janet;
    };
  });
}
```

Build and run:

```bash
nix build .
nix run .
```

## Templates

Create a minimal Janet project with dev shell and build derivation:

```bash
nix flake new --template github:turnerdev/janet-nix ./my-new-project
cd ./my-new-project
git init
git add .
```

# License
MIT