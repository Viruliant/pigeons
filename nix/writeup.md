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

after running make 

To run `pigeons` as a declarative NixOS service instead of using `pigeons service install`, you can define a NixOS module that runs `pigeons roost` under `systemd.services` using the package from `./flake_pigeons`.

### 1. NixOS Module (`pigeons.nix`)

After you modify the package.nix to point to your github and push your commit.

Run the make-flake.sh script to generate a `flake_pigeons` dir, place a copy of that dir next to your `configuration.nix`  and enable It in `configuration.nix` with

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

Do a rebuild switch and your custom version should now be installed.

### Key Details to Keep in Mind

* **Flake evaluation & lockfile**: Because `builtins.getFlake` evaluates `./flake_pigeons` as a flake, make sure `./flake_pigeons` has a `flake.lock` (or passes `--extra-experimental-features` / allows network access if generating one) and that your NixOS build permits evaluating the local flake path.
* **Persistent identity & telemetry**: `pigeons roost` persists keys by default so your endpoint ID stays consistent across restarts, and reads machine-wide settings from `/etc/pigeons/config.toml`.


* **Checking status & logs**: Once rebuilt, manage and inspect it with standard `systemd` commands (`systemctl status pigeons` and `journalctl -u pigeons -f`) rather than `pigeons service *`.

Would you like to adapt this to pass the flake input via `specialArgs` instead of `builtins.getFlake`, or configure a dedicated non-root user for the service?