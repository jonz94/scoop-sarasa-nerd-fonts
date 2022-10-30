#Requires -Version 3

<#
.SYNOPSIS
    Generate manifests of patched fonts.
.PARAMETER OverwriteExisting
    Whether to overwrite existing manifests.
.EXAMPLE
    PS BUCKETROOT> .\bin\generate-manifests.ps1
    Generate manifests only if the desired manifest does not exist.
.EXAMPLE
    PS BUCKETROOT> .\bin\generate-manifests.ps1 -OverwriteExisting
    Force re-generate all manifests.
#>
Param (
    [switch]$OverwriteExisting
)

function Export-FontManifest {
    Param (
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [ValidateNotNullOrEmpty()]
        [switch]$IsTTC,
        [switch]$OverwriteExisting
    )

    $path = "$PSScriptRoot\..\bucket\${Name}.json"
    $filter = if ($IsTTC) { "'*.ttc'" } else { "'*.ttf'" }
    $projectName = if ($IsTTC) { 'ttc-sarasa-gothic-nerd-fonts' } else { 'Sarasa-Gothic-Nerd-Fonts' }

    $templateData = [ordered]@{
        "version"       = "0.0"
        "homepage"      = "https://github.com/jonz94/Sarasa-Gothic-Nerd-Fonts"
        "license"       = "OFL-1.1"
        "url"           = " "
        "hash"          = " "
        "installer"     = @{
            "script" = @(
                '$currentBuildNumber = [int] (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber',
                '$windows10Version1809BuildNumber = 17763',
                '$isPerUserFontInstallationSupported = $currentBuildNumber -ge $windows10Version1809BuildNumber',
                'if (!$isPerUserFontInstallationSupported -and !$global) {',
                '    scoop uninstall $app',
                '    Write-Host ""',
                '    Write-Host " Error " -Background DarkRed -Foreground White -NoNewline',
                '    Write-Host ""',
                '    Write-Host " Cannot install ''$app'' for current user." -Foreground DarkRed',
                '    Write-Host ""',
                '    Write-Host " Reason " -Background DarkCyan -Foreground White -NoNewline',
                '    Write-Host ""',
                '    Write-Host " For Windows version before Windows 10 Version 1809 (OS Build 17763)," -Foreground DarkCyan',
                '    Write-Host " font can only be installed for all users." -Foreground DarkCyan',
                '    Write-Host ""',
                '    Write-Host " Suggestion " -Background Magenta -Foreground White -NoNewline',
                '    Write-Host ""',
                '    Write-Host " Use the following commands to install ''$app'' for all users." -Foreground Magenta',
                '    Write-Host ""',
                '    Write-Host "        scoop install sudo"',
                '    Write-Host "        sudo scoop install -g $app"',
                '    Write-Host ""',
                '    exit 1',
                '}',
                '$fontInstallDir = if ($global) { "$env:windir\Fonts" } else { "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" }',
                '$registryRoot = if ($global) { "HKLM" } else { "HKCU" }',
                '$registryKey = "${registryRoot}:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"',
                'New-Item $fontInstallDir -ItemType Directory -ErrorAction SilentlyContinue | Out-Null',
                "Get-ChildItem `$dir -Filter $filter | ForEach-Object {",
                '    $value = if ($isFontInstallationForAllUsers) { $_.Name } else { "$fontInstallDir\$($_.Name)" }',
                '    New-ItemProperty -Path $registryKey -Name $_.Name.Replace($_.Extension, '' (TrueType)'') -Value $value -Force | Out-Null',
                '    Copy-Item $_.FullName -Destination $fontInstallDir',
                '}'
            )
        }
        "pre_uninstall" = @(
            '$fontInstallDir = if ($global) { "$env:windir\Fonts" } else { "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" }',
            "Get-ChildItem `$dir -Filter $filter | ForEach-Object {",
            '    Get-ChildItem $fontInstallDir -Filter $_.Name | ForEach-Object {',
            '        try {',
            '            Rename-Item $_.FullName $_.FullName -ErrorVariable LockError -ErrorAction Stop',
            '        } catch {',
            '            Write-Host ""',
            '            Write-Host " Error " -Background DarkRed -Foreground White -NoNewline',
            '            Write-Host ""',
            '            Write-Host " Cannot uninstall ''$app''." -Foreground DarkRed',
            '            Write-Host ""',
            '            Write-Host " Reason " -Background DarkCyan -Foreground White -NoNewline',
            '            Write-Host ""',
            '            Write-Host " The ''$app'' is currently being used by another application," -Foreground DarkCyan',
            '            Write-Host " so it cannot be deleted." -Foreground DarkCyan',
            '            Write-Host ""',
            '            Write-Host " Suggestion " -Background Magenta -Foreground White -NoNewline',
            '            Write-Host ""',
            '            Write-Host " Close all applications (e.g. vscode) that are using ''$app''," -Foreground Magenta',
            '            Write-Host " and then try again." -Foreground Magenta',
            '            Write-Host ""',
            '            exit 1',
            '        }',
            '    }',
            '}'
        )
        "uninstaller"   = @{
            "script" = @(
                '$fontInstallDir = if ($global) { "$env:windir\Fonts" } else { "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" }',
                '$registryRoot = if ($global) { "HKLM" } else { "HKCU" }',
                '$registryKey = "${registryRoot}:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"',
                "Get-ChildItem `$dir -Filter $filter | ForEach-Object {",
                '    Remove-ItemProperty -Path $registryKey -Name $_.Name.Replace($_.Extension, '' (TrueType)'') -Force -ErrorAction SilentlyContinue',
                '    Remove-Item "$fontInstallDir\$($_.Name)" -Force -ErrorAction SilentlyContinue',
                '}'
            )
        }
        "checkver"      = [ordered]@{
            "github" = "https://github.com/jonz94/${projectName}"
            "regex"  = "releases/tag/(?:v|V)?([\d.-]+)"
        }
        "autoupdate"    = @{
            "url" = "https://github.com/jonz94/${projectName}/releases/download/v`$version/${Name}.zip"
        }
    }

    if (! (Test-Path $path)) {
        # Create the manifest if it doesn't exist
        ConvertTo-Json -InputObject $templateData | Set-Content -LiteralPath $path -Encoding UTF8
    } elseif ($OverwriteExisting) {
        ConvertTo-Json -InputObject $templateData | Set-Content -LiteralPath $path -Encoding UTF8 -Force
    }

    # Use scoop's checkver script to autoupdate the manifest
    & $PSScriptRoot\checkver.ps1 $Name -u

    # Sleep to avoid 429 errors from github's REST API
    Start-Sleep 1
}

$styles = @("fixed", "fixed-slab", "mono", "mono-slab", "term", "term-slab", "gothic", "ui")
$orthographies = @("cl", "hc", "j", "k", "sc", "tc")

$fontNames = @()

foreach ($style in $styles) {
    foreach ($orthography in $orthographies) {
        $fontNames += "sarasa-${style}-${orthography}-nerd-font"
    }
}

# Generate manifests for all TTF Fonts
$fontNames | ForEach-Object {
    Export-FontManifest -Name $_ -OverwriteExisting:$OverwriteExisting
}

# Generate manifests for TTC Font
Export-FontManifest -Name "sarasa-nerd-font-ttc" -IsTTC -OverwriteExisting:$OverwriteExisting
