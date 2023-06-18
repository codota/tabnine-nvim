#!/usr/bin/env -S pwsh -noprofile -nologo

# This script downloads the binaries for the most recent version of TabNine.

$TABNINE_UPDATE_SERVICE="https://update.tabnine.com"
if ($args.count -gt 0) {
    $TABNINE_UPDATE_SERVICE=$args[0]
}

if ($null -ne $env:FOO) {
    $version=$Env:version
}
else {
    $version = invoke-webrequest -uri "$TABNINE_UPDATE_SERVICE/bundles/version" -usebasicparsing
}

if ((Get-WmiObject win32_operatingsystem | Select-Object osarchitecture).osarchitecture -eq "64-bit") {
    $targets = @(
        'x86_64-pc-windows-gnu'
    )
}
else {
    $targets = @(
        'i686-pc-windows-gnu'
    )
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
    if ($LastExitCode -eq 0) {return}

    expand-archive "binaries/$path/TabNine.zip" "binaries/$path" 

    remove-item -path "binaries/$path/TabNine.zip"
}
