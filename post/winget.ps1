<#
.SYNOPSIS
Install WinGet (if required) and specified packages
.PARAMETER Packages
Comma-separated list of packages to install
#>

# Copyright (C) 2023 Elliot Killick <elliotkillick@zohomail.eu>
# Licensed under the MIT License. See LICENSE file for details.

Param (
    [Parameter(Mandatory=$true)][String[]]$Packages
)

$host.UI.RawUI.WindowTitle = $PSCommandPath

if (!(Get-Command -ErrorAction SilentlyContinue winget)) {
    # Force Powershell 2 to use TLS 1.2
    if ([System.Net.SecurityProtocolType]::Tls12 -eq $null) {
        Write-Host "Enabling TLS 1.2 for PowerShell 2..."
        [System.Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([System.Net.SecurityProtocolType], 3072)
    }

    $wc = New-Object System.Net.WebClient

    # GitHub API always blocks empty user agents (default for WebClient)
    # Set a common user agent to avoid figerprinting
    if ([Microsoft.PowerShell.Commands.PSUserAgent] -ne $null) {
        $wc.Headers.Add('User-Agent', [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome)
    else {
        # PowerShell 2
        # Set user agent of most up-to-date Internet Explorer (before EOL) on Windows 7
        # Even the 64-bit iexplore.exe in "C:\Program Files" has a "WOW64" user agent
        $wc.Headers.Add('User-Agent', 'Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko')
    }

    # Download and extract WinGet MSIX bundle link
    # We could parse the JSON, but this is more secure
    $wc.DowloadString('https://api.github.com/repos/microsoft/winget-cli/releases/latest') -match 'https://github.com/microsoft/winget-cli/releases/download/v[0-9.]+/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
    $url = matches[0]

    # Create temporary file
    $file = [IO.Path]::GetTempFileName()

    (New-Object System.Net.WebClient).DownloadFile($url, $file)

    Add-AppxPackage -Path $file

    Remove-Item -Path $file
}

winget install --accept-source-agreements --accept-package-agreements --exact --id $Packages

# Install from terminal: https://github.com/microsoft/winget-cli/issues/2222
# MSIX Core: https://learn.microsoft.com/en-us/windows/msix/msix-core/msixcore
