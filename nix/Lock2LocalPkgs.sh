#!/usr/bin/env bash
set -euo pipefail

# Pins nixpkgs in flake.lock to the local NixOS revision so builds 
# reuse already-available packages instead of downloading a fresh 
# snapshot. If a later `nix build` fails, restore the original 
# lockfile with `git restore --worktree -- ':(top)flake.lock'`
# (works from any subdirectory).

# Locate the flake root by walking up from the script's directory, so this
# works when the script lives in the repo root or in the nix/ subdirectory,
# and regardless of the caller's working directory.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
flake_root="$script_dir"
while [[ ! -f "$flake_root/flake.nix" && "$flake_root" != "/" ]]; do
  flake_root="$(dirname "$flake_root")"
done
if [[ ! -f "$flake_root/flake.nix" ]]; then
  echo "error: could not find flake.nix above $script_dir" >&2
  exit 1
fi
cd "$flake_root"

Lock2LocalPkgs (){
  rev=$(nixos-version --json | jq -r '.nixpkgsRevision')

  if [[ -z "$rev" ]]; then
    echo "Failed to extract nixpkgsRevision" >&2
    exit 1
  fi

  echo "Updating flake to nixpkgs revision: $rev"

  nix flake update \
    --override-input nixpkgs "github:NixOS/nixpkgs/${rev}"
}

Lock2LocalPkgs

# `git restore --source=HEAD -- ':(top)flake.lock'` 
# `git restore --worktree -- ':(top)flake.lock'`