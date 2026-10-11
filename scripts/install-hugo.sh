#!/usr/bin/env bash
set -euo pipefail

# Installs locally; no system changes, theme downloads, or sudo required.
HUGO_VERSION=0.147.9
case "$(uname -s)/$(uname -m)" in
  Linux/x86_64) platform=linux-amd64 ;;
  Linux/aarch64|Linux/arm64) platform=linux-arm64 ;;
  Darwin/x86_64|Darwin/arm64) platform=darwin-universal ;;
  *) echo 'Unsupported platform. Install Hugo Extended from gohugo.io/installation/.' >&2; exit 1 ;;
esac

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target="$repo_dir/.tools/bin/hugo"
if [[ -x "$target" ]] && "$target" version | grep -q "v${HUGO_VERSION}.*+extended"; then
  "$target" version
  exit 0
fi

download_dir="$(mktemp -d)"
trap 'rm -rf "$download_dir"' EXIT
archive="hugo_extended_${HUGO_VERSION}_${platform}.tar.gz"
release="https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}"
curl --fail --location --silent --show-error "$release/$archive" -o "$download_dir/$archive"
curl --fail --location --silent --show-error "$release/hugo_${HUGO_VERSION}_checksums.txt" -o "$download_dir/checksums.txt"
awk -v filename="$archive" '$2 == filename || $2 == "*" filename { print }' "$download_dir/checksums.txt" > "$download_dir/selected-checksum.txt"
test -s "$download_dir/selected-checksum.txt"
if command -v sha256sum >/dev/null; then
  (cd "$download_dir" && sha256sum --check selected-checksum.txt)
else
  (cd "$download_dir" && shasum -a 256 --check selected-checksum.txt)
fi
mkdir -p "$repo_dir/.tools/bin"
tar -xzf "$download_dir/$archive" -C "$repo_dir/.tools/bin" hugo
"$target" version
