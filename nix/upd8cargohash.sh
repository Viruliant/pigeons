#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

NIX_FILE="nix/package.nix"
LOG="$(mktemp)"

get_attr() {
  local name="$1" file="$2"
  sed -n "s/^[[:space:]]*${name}[[:space:]]*=[[:space:]]*\"\([^\"]*\)\"[[:space:]]*;/\1/p" "$file"
}

update_hash_attr() {
  local attr="$1" hash="$2"
  sed -i "s|\(^[[:space:]]*${attr}[[:space:]]*=[[:space:]]*\"\)[^\"]*\([[:space:]]*\"[[:space:]]*;\)|\1${hash}\2|" "$NIX_FILE"
  echo "updated ${attr} = ${hash}"
}

if [ ! -f ./Cargo.lock ]; then
  echo "error: ./Cargo.lock not found" >&2
  exit 1
fi

echo "checking cargoHash against ./Cargo.lock..."
nix build --no-link 2>&1 | tee "$LOG" >/dev/null || true

got=$(sed -n 's/.*got:[[:space:]]*\(sha256-[A-Za-z0-9+/=]\+\).*/\1/p' "$LOG" | tail -1)

if [ -z "$got" ]; then
  echo "cargoHash is already up to date."
  exit 0
fi

update_hash_attr "cargoHash" "$got"
echo "rebuilding with new cargoHash..."
nix build --no-link 2>&1 | tail -20 || true
