#!/bin/sh
set -e

TABNINE_UPDATE_SERVICE=${1:-"https://update.tabnine.com"}
DEPENDS='unzip curl' # list of dependencies (commands)
HAS_ALL_DEPS=1       # 1 = present, 0 = missing
for dep in ${DEPENDS}; do
  if ! command -v "$dep" >/dev/null 2>/dev/null; then # if command not accessible
    echo "ERROR: $dep is required to download Tabnine binaries. Please install $dep and run this again." >&2
    HAS_ALL_DEPS=0
  fi
done
if [ "${HAS_ALL_DEPS}" -eq 0 ]; then # missing something.
  exit 1
fi

# This script downloads the binaries for the most recent version of TabNine.
# Infrastructure detection heavily inspired by https://github.com/tzachar/cmp-tabnine/blob/main/install.sh
version=${version:-$(curl -fsSL "$TABNINE_UPDATE_SERVICE/bundles/version")}
case $(uname -s) in
"Darwin")
  if [ "$(uname -m)" = "arm64" ]; then
    targets="aarch64-apple-darwin"
  elif [ "$(uname -m)" = "x86_64" ]; then
    targets="x86_64-apple-darwin"
  fi
  ;;
"Linux")
  if [ "$(uname -m)" = "x86_64" ]; then
    targets="x86_64-unknown-linux-musl"
  fi
  ;;
esac

if [ -z "$targets" ]; then
  echo "Target detection failed. Installing all targets"
  targets='x86_64-apple-darwin
    x86_64-unknown-linux-musl
    aarch64-apple-darwin'
fi

rm -rf ./binaries

echo "$targets" | while read -r target; do
  mkdir -p "binaries/$version/$target"
  path=$version/$target
  echo "downloading $path"
  curl -fsSL "$TABNINE_UPDATE_SERVICE/bundles/$path/TabNine.zip" -o "binaries/$path/TabNine.zip" ||
    continue
  unzip -o "binaries/$path/TabNine.zip" -d "binaries/$path"
  rm "binaries/$path/TabNine.zip"
  chmod +x "binaries/$path/"*
done
