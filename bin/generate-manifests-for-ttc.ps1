$templateString = @"
{
    "version": "0.0",
    "homepage": "https://github.com/jonz94/Sarasa-Gothic-Nerd-Fonts",
    "license": "OFL-1.1",
    "url": " ",
    "hash": " ",
    "checkver": "github",
    "autoupdate": {
        "url": "https://github.com/jonz94/ttc-sarasa-gothic-nerd-fonts/releases/download/v`$version/sarasa-nerd-font-ttc.zip"
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
            "New-Item `$fontInstallDir -ItemType Directory -ErrorAction SilentlyContinue | Out-Null",
            "Get-ChildItem `$dir -Filter '*.ttc' | ForEach-Object {",
            "    `$value = if (`$isFontInstallationForAllUsers) { `$_.Name } else { \"`$fontInstallDir\\`$(`$_.Name)\" }",
            "    New-ItemProperty -Path `$registryKey -Name `$_.Name.Replace(`$_.Extension, ' (TrueType)') -Value `$value -Force | Out-Null",
            "    Copy-Item `$_.FullName -Destination `$fontInstallDir",
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
            "Get-ChildItem `$dir -Filter '*.ttc' | ForEach-Object {",
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
            "Get-ChildItem `$dir -Filter '*.ttc' | ForEach-Object {",
            "    Remove-ItemProperty -Path `$registryKey -Name `$_.Name.Replace(`$_.Extension, ' (TrueType)') -Force -ErrorAction SilentlyContinue",
            "    Remove-Item \"`$fontInstallDir\\`$(`$_.Name)\" -Force -ErrorAction SilentlyContinue",
            "}",
            "Write-Host \"The '`$app' Font family has been uninstalled and will not be present after restarting your computer.\" -Foreground Magenta"
        ]
    }
}
"@

$name = "sarasa-nerd-font-ttc"

# Create the manifest if it doesn't exist
$path = "$PSScriptRoot\..\bucket\${name}.json"
if (!(Test-Path $path)) {
    $templateString | Out-File -FilePath $path -Encoding utf8
}

# Use scoop's checkver script to autoupdate the manifest
& $psscriptroot\checkver.ps1 $name -u
