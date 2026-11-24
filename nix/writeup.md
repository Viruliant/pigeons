# Files

`flake.nix` — root entry point using unstable nixpkgs and flake-parts; provides `nix build` and `nix develop`.
`nix/package.nix` — builds local code via `src = ../.`; the commented `fetchFromGitHub` block is used in the generated payload.
`nix/make-flake.sh` — after committing, pins source/hashes and writes the tarball-ready `../flake/` payload, then restores `package.nix`.
`nix/upd8cargo.sh` — copies `../flake/nix/Cargo.lock` back to the repo and syncs `cargoHash` into `package.nix`.
`nix/build.sh` — legacy non-flake `nix-build` helper; not needed for the flake workflow.

# Scenarios

**Local build:** run `nix build` (or `nix develop`) from the repo root.
**After a patch:** edit code, confirm `nix build`, then commit.
**Release payload:** run `./nix/make-flake.sh` and tarball `../flake/`.
**After Cargo.toml edits:** regenerate `Cargo.lock` with cargo, run `nix build`, then `./nix/make-flake.sh` to refresh the payload.
**After Cargo.lock changes in the payload:** run `./nix/upd8cargo.sh` to copy it back and sync `cargoHash`.
