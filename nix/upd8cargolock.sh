#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -f ./Cargo.toml ]; then
  echo "error: ./Cargo.toml not found" >&2
  exit 1
fi

if [ -f ./Cargo.lock ]; then
  echo "updating ./Cargo.lock with cargo update"
  nix shell github:NixOS/nixpkgs/nixos-unstable#cargo --command cargo update "$@"
else
  echo "generating ./Cargo.lock with cargo generate-lockfile"
  nix shell github:NixOS/nixpkgs/nixos-unstable#cargo --command cargo generate-lockfile "$@"
fi
