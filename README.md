# janet-nix
[nix flake](https://nixos.wiki/wiki/Flakes) helpers for [Janet](https://janet-lang.org/) projects using [jpm](https://janet-lang.org/docs/jpm.html) (Janet Project Manager).

Should be considered alpha.

## Prerequisites

Install dependencies for the current project and create a lockfile:

```bash
jpm deps
jpm make-lockfile
git add lockfile.jdn
```

## Usage

Use `mkJanet` to create derivations for executables:

```nix
{
  packages = forAllSystems (system: {
    my-new-program = janet-nix.packages.${system}.mkJanet {
      name = "my-new-program";
      src = ./.;
      quickbin = "init.janet";
    };
  });
}
```

Build and run:

```bash
nix build .
nix run .
```

### API

`mkJanet` accepts the following parameters. All are optional aside from `name`, `src` and one of either `quickbin`, `main` or `bin`

- `name` output binary
- `src` source path or repo, passed to `mkDerivation`
- `version` passed to `mkDerivation`
- `buildInputs` additional nix packages
- `extraDeps` additional Janet sources, see [Tips](#tips)
- `quickbin` an entry point for `jpm quickbin`
- `main` specify Janet code to use as the entry point to `jpm quickbin`
- `bin` specify a binary from `$JANET_TREE/bin` to use as result

## Templates

Create a minimal Janet project with dev shell and build derivation:

```bash
nix flake new --template github:turnerdev/janet-nix ./my-new-project
cd ./my-new-project
git init
git add .
```

Alternatively, use the `full` template to include other development tools ([jfmt](https://github.com/andrewchambers/jfmt) and [judge](https://github.com/ianthehenry/judge) as of now): 

```bash
nix flake new --template github:turnerdev/janet-nix#full ./my-new-project
```

## Tips

**Missing `lockfile.jdn`**

When wrapping third-party repos, you may find that `lockfile.jdn` is missing. To work around this, first check-out the repo in question to a temporary directory, build the lock file as normal and then run:

```bash
nix run github:turnerdev/janet-nix
```

To generate a list of nix sources from the lockfile. You can pass this list to `mkJanet` with the `extraDeps` attribute.

# Changelog

## v0.1.0
- **Breaking change:** Renamed `entry` to `quickbin`
- Added alternative entry points
  - `main` to provide Janet code to act as the entry to `jpm quickbin`
  - `bin` to specify a binary from `$JANET_TREE/bin` to use as result
- `extraDeps` to pass dependencies directly to `mkJanet`, useful for building third-party repos without a `lockfile.jdn`

# License
MIT
