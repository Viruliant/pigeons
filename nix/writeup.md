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
