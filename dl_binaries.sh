#!/bin/sh
set -e

# This script downloads the binaries for the most recent version of TabNine.
# Infrastructure detection heavily inspired by https://github.com/tzachar/cmp-tabnine/blob/main/install.sh
version=${version:-$(curl -sS https://update.tabnine.com/bundles/version)}
if [ $# -gt 0 ]; then
    # Pass fully qualified names as positional arguments
    targets="$(printf '%s\n' "$@")"
else
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
fi

if [ -z "$targets" ]; then
    echo "Infrastructure detection failed. Installing all versions"
    targets='x86_64-apple-darwin
    x86_64-unknown-linux-musl
    aarch64-apple-darwin'
fi

rm -rf ./binaries

echo "$targets" | while read -r target; do
    mkdir -p "binaries/$version/$target"
    path=$version/$target
    echo "downloading $path"
    curl -fsS "https://update.tabnine.com/bundles/$path/TabNine.zip" -o "binaries/$path/TabNine.zip" ||
        continue
    unzip -o "binaries/$path/TabNine.zip" -d "binaries/$path"
    rm "binaries/$path/TabNine.zip"
    chmod +x "binaries/$path/"*
done
