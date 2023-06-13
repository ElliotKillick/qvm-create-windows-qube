<#
.SYNOPSIS
Install Chocolatey and specified packages
.PARAMETER Packages
Comma-separated list of packages to install (see available packages at: https://chocolatey.org/packages)
#>

# Copyright (C) 2023 Elliot Killick <contact@elliotkillick.com>
# Licensed under the MIT License. See LICENSE file for details.

Param (
    [Parameter(Mandatory=$true)][String[]]$Packages
)

$host.UI.RawUI.WindowTitle = $PSCommandPath

# Force Powershell 2 to use TLS 1.2
if ([System.Net.SecurityProtocolType]::Tls12 -eq $null) {
    Write-Host "Enabling TLS 1.2 for PowerShell 2 (please ignore Chocolatey if it claims that TLS 1.0 is in use)..."
    [System.Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([System.Net.SecurityProtocolType], 3072)
}

# https://chocolatey.org/install
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install -y $Packages
