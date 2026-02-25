#!/usr/bin/env -S pwsh -noprofile -nologo

# This script downloads the binaries for the most recent version of TabNine.

$TABNINE_UPDATE_SERVICE="https://update.tabnine.com"
$NODE_VERSION="v24.12.0"

if ($args.count -gt 0) {
    $TABNINE_UPDATE_SERVICE=$args[0]
}

if ($null -ne $env:version) {
    $version=$Env:version
}
else {
    $version = invoke-webrequest -uri "$TABNINE_UPDATE_SERVICE/bundles/version" -usebasicparsing
}

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if ([Environment]::Is64BitOperatingSystem) {
    $targets = @(
        'x86_64-pc-windows-gnu'
    )
    if ([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture -eq "Arm64") {
        $node_installer_platform = "windows-arm64"
    } else {
        $node_installer_platform = "windows-x64"
    }
}
else {
    $targets = @(
        'i686-pc-windows-gnu'
    )
    $node_installer_platform = "windows-x64"
}

if (test-path -path "binaries/$version") {
    remove-item -path binaries -recurse -force | out-null
    New-Item -Path "binaries/$version" -ItemType Directory -force | out-null
}

$targets | foreach-object {
    $target = $_
    $path = "$version/$target"

    if (!(test-path -path "binaries/$version/$target")) { New-Item -Path "binaries/$version/$target" -ItemType Directory -force | out-null }

    Write-Output "downloading $path"
    invoke-webrequest -uri "$TABNINE_UPDATE_SERVICE/bundles/$path/TabNine.zip" -outfile "binaries/$path/TabNine.zip"
    # Stop this iteration if the download failed
    if (!(Test-Path "binaries/$path/TabNine.zip" -PathType Leaf)) {return}

    expand-archive "binaries/$path/TabNine.zip" "binaries/$path"

    remove-item -path "binaries/$path/TabNine.zip"
}

# Download Node.js runtime using node-installer
$NODE_INSTALLER = Join-Path $ScriptDir "node/installer/$node_installer_platform/tabnine-node-installer.exe"
if (Test-Path $NODE_INSTALLER -PathType Leaf) {
    Write-Output "Downloading Node.js runtime using node-installer..."
    try {
        $NODE_RUNTIME_DIR = & $NODE_INSTALLER $TABNINE_UPDATE_SERVICE $NODE_VERSION 2>$null
        if ($NODE_RUNTIME_DIR) {
            Write-Output "Node.js runtime installed at: $NODE_RUNTIME_DIR"
        }
    }
    catch {
        Write-Warning "Failed to download Node.js runtime. Some features may not work."
    }
}
else {
    Write-Warning "node-installer not found at $NODE_INSTALLER"
}
