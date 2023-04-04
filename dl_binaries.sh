#!/bin/sh
set -e

# This script downloads the binaries for the most recent version of TabNine.
# Infrastructure detection heavily inspired by https://github.com/tzachar/cmp-tabnine/blob/main/install.sh
version=${version:-$(curl -sS https://update.tabnine.com/bundles/version)}
case $(uname -s) in
"Darwin")
    if [ "$(uname -m)" = "arm64" ]; then
        targets="aarch64-apple-darwin"
    else
        targets="$(uname -m)-apple-darwin"
    fi
    ;;
"Linux")
    targets="$(uname -m)-unknown-linux-musl"
    ;;
*)
    echo "Infrastructure detection failed. Installing all versions"
    targets='x86_64-apple-darwin
    x86_64-unknown-linux-musl
    aarch64-apple-darwin'
    ;;
esac

rm -rf ./binaries

echo "$targets" | while read -r target; do
    mkdir -p "binaries/$version/$target"
    path=$version/$target
    echo "downloading $path"
    curl -sS "https://update.tabnine.com/bundles/$path/TabNine.zip" >"binaries/$path/TabNine.zip"
    unzip -o "binaries/$path/TabNine.zip" -d "binaries/$path"
    rm "binaries/$path/TabNine.zip"
    chmod +x "binaries/$path/"*
done
