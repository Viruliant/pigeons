# Files

`flake.nix` — root entry point using unstable nixpkgs and flake-parts; provides `nix build` and `nix develop`.
`nix/package.nix` — builds local code via `src = ../.`; the commented `fetchFromGitHub` block is used in the generated payload.
`nix/make-flake.sh` — after committing, pins source/hashes and writes the tarball-ready `flake_pigeons/` payload, then restores `package.nix`.
`nix/upd8cargohash.sh` — runs `nix build` from the repo root and patches `cargoHash` in `nix/package.nix` when it mismatches.
`nix/upd8cargolock.sh` — runs `cargo update` (or `generate-lockfile`) via nixpkgs cargo to refresh `./Cargo.lock`.
`nix/build.sh` — legacy non-flake `nix-build` helper; not needed for the flake workflow.

# Scenarios

**Local build:** run `nix build` (or `nix develop`) from the repo root.
**After a patch:** edit code, confirm `nix build`, then commit.
**Release payload:** run `./nix/make-flake.sh`, then `tar -czf flake_pigeons.tar.gz flake_pigeons`.
**From the tarball:** `cd /path/to/flake_pigeons && git init && git add . && nix build` (use `nix develop` for the shell), or include it as a subdir in another project.
**After Cargo.toml edits:** run `./nix/upd8cargolock.sh` then `./nix/upd8cargohash.sh`. Then `nix build` and `./nix/make-flake.sh` to refresh the payload.
**After Cargo.lock changes:** run `./nix/upd8cargohash.sh` to refresh `cargoHash` locally.

# Try custom versions of Pigeons Declaratively

Run `./nix/make-flake.sh` from the repo root, then copy the generated `flake_pigeons/` next to `configuration.nix`.

To run `pigeons` as a declarative NixOS service instead of using `pigeons service install`, import the module from the payload. It calls `pkgs.callPackage ./nix/package.nix { }` using the system's nixpkgs, so no flake evaluation is needed.

### 1. NixOS Module (`pigeons.nix`)

Commit and push your changes first: `make-flake.sh` pins the revision and source hash from the committed HEAD, and the generated payload fetches that revision from GitHub.

Run the make-flake.sh script to generate a `flake_pigeons` dir, place a copy of that dir next to your `configuration.nix`, and enable it in `configuration.nix` with

```nix
{
  imports = [
    ./flake_pigeons/pigeons.nix
  ];

  services.pigeons = {
    enable = true;
    sshPort = 22;
    telemetryEnabled = false;
  };
}

```

Run `nixos-rebuild switch` and your custom version should now be installed.

### Key Details to Keep in Mind

* **Fetching the source**: `package.nix` uses `fetchFromGitHub` with a pinned revision and hash, so the first build needs network access (or a cached store path). No flake evaluation or Git repo is required for the copied payload.
* **Persistent identity & telemetry**: `pigeons roost` persists keys by default so your endpoint ID stays consistent across restarts, and reads machine-wide settings from `/etc/pigeons/config.toml`.


* **Checking status & logs**: Once rebuilt, manage and inspect it with standard `systemd` commands (`systemctl status pigeons` and `journalctl -u pigeons -f`) rather than `pigeons service *`.