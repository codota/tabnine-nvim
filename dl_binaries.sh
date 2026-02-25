#!/bin/sh
set -e

TABNINE_UPDATE_SERVICE=${1:-"https://update.tabnine.com"}
NODE_VERSION="v24.12.0"
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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# This script downloads the binaries for the most recent version of TabNine.
# Infrastructure detection heavily inspired by https://github.com/tzachar/cmp-tabnine/blob/main/install.sh
version=${version:-$(curl -fsSL "$TABNINE_UPDATE_SERVICE/bundles/version")}
case $(uname -s) in
"Darwin")
  if [ "$(uname -m)" = "arm64" ]; then
    targets="aarch64-apple-darwin"
    node_installer_platform="macos-arm64"
  elif [ "$(uname -m)" = "x86_64" ]; then
    targets="x86_64-apple-darwin"
    node_installer_platform="macos-x64"
  fi
  ;;
"Linux")
  if [ "$(uname -m)" = "x86_64" ]; then
    targets="x86_64-unknown-linux-musl"
    node_installer_platform="linux-x64"
  elif [ "$(uname -m)" = "aarch64" ]; then
    targets="aarch64-unknown-linux-musl"
    node_installer_platform="linux-arm64"
  fi
  ;;
esac

if [ -z "$targets" ]; then
  echo "Target detection failed. Installing all targets"
  targets='x86_64-apple-darwin
    x86_64-unknown-linux-musl
    aarch64-unknown-linux-musl
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

# Download Node.js runtime using node-installer
if [ -n "$node_installer_platform" ]; then
  NODE_INSTALLER="$SCRIPT_DIR/node/installer/$node_installer_platform/tabnine-node-installer"
  if [ -f "$NODE_INSTALLER" ]; then
    echo "Downloading Node.js runtime using node-installer..."
    chmod +x "$NODE_INSTALLER"
    NODE_RUNTIME_DIR=$("$NODE_INSTALLER" "$TABNINE_UPDATE_SERVICE" "$NODE_VERSION" 2>/dev/null) || {
      echo "Warning: Failed to download Node.js runtime. Some features may not work."
    }
    if [ -n "$NODE_RUNTIME_DIR" ]; then
      echo "Node.js runtime installed at: $NODE_RUNTIME_DIR"
    fi
  else
    echo "Warning: node-installer not found at $NODE_INSTALLER"
  fi
fi
