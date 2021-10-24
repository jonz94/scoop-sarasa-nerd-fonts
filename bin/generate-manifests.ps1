﻿$templateString = @"
{
    "version": "0.0",
    "homepage": "https://github.com/jonz94/Sarasa-Gothic-Nerd-Fonts",
    "license": "OFL-1.1",
    "url": " ",
    "hash": " ",
    "checkver": "github",
    "autoupdate": {
        "url": "https://github.com/jonz94/Sarasa-Gothic-Nerd-Fonts/releases/download/v`$version/%name.zip"
    },
    "installer": {
        "script": [
            "`$currentBuildNumber = [int] (Get-ItemProperty \"HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\").CurrentBuildNumber",
            "`$windows1809BuildNumber = 17763",
            "`$isPerUserFontInstallationSupported = `$currentBuildNumber -ge `$windows1809BuildNumber",
            "`$isFontInstallationForAllUsers = `$global -or !`$isPerUserFontInstallationSupported",
            "if (`$isFontInstallationForAllUsers -and !(is_admin)) {",
            "    error \"Administrator rights are required to install `$app.\"",
            "    exit 1",
            "}",
            "`$fontInstallDir = if (`$isFontInstallationForAllUsers) { \"`$env:windir\\Fonts\" } else { \"`$env:LOCALAPPDATA\\Microsoft\\Windows\\Fonts\" }",
            "`$registryRoot = if (`$isFontInstallationForAllUsers) { \"HKLM\" } else { \"HKCU\" }",
            "`$registryKey = \"`${registryRoot}:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts\"",
            "if (!`$isFontInstallationForAllUsers) {",
            "    New-Item `$fontInstallDir -ItemType Directory -ErrorAction SilentlyContinue | Out-Null",
            "}",
            "Get-ChildItem `$dir -Filter '*.ttf' | ForEach-Object {",
            "    Copy-Item `$_.FullName -Destination `$fontInstallDir",
            "    Get-ChildItem `$fontInstallDir -Filter `$_.Name | ForEach-Object {",
            "        `$value = if (`$isFontInstallationForAllUsers) { `$_.Name } else { `$_.FullName }",
            "        New-ItemProperty -Path `$registryKey -Name `$_.Name.Replace(`$_.Extension, ' (TrueType)') -Value `$value -Force | Out-Null",
            "    }",
            "}"
        ]
    },
    "uninstaller": {
        "script": [
            "`$currentBuildNumber = [int] (Get-ItemProperty \"HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\").CurrentBuildNumber",
            "`$windows1809BuildNumber = 17763",
            "`$isPerUserFontInstallationSupported = `$currentBuildNumber -ge `$windows1809BuildNumber",
            "`$isFontInstallationForAllUsers = `$global -or !`$isPerUserFontInstallationSupported",
            "if (`$isFontInstallationForAllUsers -and !(is_admin)) {",
            "    error \"Administrator rights are required to uninstall `$app.\"",
            "    exit 1",
            "}",
            "`$fontInstallDir = if (`$isFontInstallationForAllUsers) { \"`$env:windir\\Fonts\" } else { \"`$env:LOCALAPPDATA\\Microsoft\\Windows\\Fonts\" }",
            "`$registryRoot = if (`$isFontInstallationForAllUsers) { \"HKLM\" } else { \"HKCU\" }",
            "`$registryKey = \"`${registryRoot}:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts\"",
            "Get-ChildItem `$dir -Filter '*.ttf' | ForEach-Object {",
            "    Get-ChildItem `$fontInstallDir -Filter `$_.Name | ForEach-Object {",
            "        try {",
            "            Rename-Item `$_.FullName `$_.FullName -ErrorVariable LockError -ErrorAction Stop",
            "        } catch {",
            "            error \"'`$app' is being used by another process.\"",
            "            error \"Please close all applications (e.g. vscode) that are using '`$app' before uninstall or upgrade.\"",
            "            exit 1",
            "        }",
            "    }",
            "}",
            "Get-ChildItem `$dir -Filter '*.ttf' | ForEach-Object {",
            "    Remove-ItemProperty -Path `$registryKey -Name `$_.Name.Replace(`$_.Extension, ' (TrueType)') -Force -ErrorAction SilentlyContinue",
            "    Remove-Item \"`$fontInstallDir\\`$(`$_.Name)\" -Force -ErrorAction SilentlyContinue",
            "}",
            "Write-Host \"The '`$app' Font family has been uninstalled and will not be present after restarting your computer.\" -Foreground Magenta"
        ]
    }
}
"@

$styles = @("fixed", "fixed-slab", "mono", "mono-slab", "term", "term-slab", "gothic", "ui")
$orthographies = @("cl", "hc", "j", "k", "sc", "tc")

$fontNames = @()

foreach($style in $styles) {
  foreach($orthography in $orthographies) {
    $fontNames += "sarasa-${style}-${orthography}-nerd-font"
  }
}

# Generate manifests
$fontNames | ForEach-Object {
    # Create the manifest if it doesn't exist
    $path = "$PSScriptRoot\..\bucket\${_}.json"
    if (!(Test-Path $path)) {
        $templateString -replace "%name", $_ | Out-File -FilePath $path -Encoding utf8
    }

    # Use scoop's checkver script to autoupdate the manifest
    & $psscriptroot\checkver.ps1 $_ -u

    # Sleep to avoid 429 errors from github's REST API
    Start-Sleep 1
}
