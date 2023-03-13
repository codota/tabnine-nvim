#!/usr/bin/env -S pwsh -noprofile -nologo

# This script downloads the binaries for the most recent version of TabNine.

$version = invoke-webrequest -uri 'https://update.tabnine.com/bundles/version' -usebasicparsing
$targets = @(
    'i686-pc-windows-gnu'
    'x86_64-apple-darwin'
    'x86_64-pc-windows-gnu'
    'x86_64-unknown-linux-musl'
    'aarch64-apple-darwin'
)

if (test-path -path "binaries/$version") {
    remove-item -path binaries -recurse -force | out-null
    mkdir binaries/$version -force | out-null
}

$targets | foreach-object {
    $target = $_
    $path = "$version/$target"

    if (!(test-path -path "binaries/$version/$target")) { mkdir "binaries/$version/$target" -force | out-null }

    echo "downloading $path"    
    invoke-webrequest -uri "https://update.tabnine.com/bundles/$path/TabNine.zip" -outfile "binaries/$path/TabNine.zip"

    if ($PSVersionTable.PSEdition -ne "Core") { 
      expand-archive -path "binaries/$path/TabNine.zip" -destinationpath "binaries/$path" 
    } else { 
      expand-archive -path "binaries/$path/TabNine.zip" -outputpath "binaries/$path" 
    }

    remove-item -path "binaries/$path/TabNine.zip"
}
