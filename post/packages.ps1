<#
.SYNOPSIS
Install Chocolatey and specified packages
.PARAMETER Packages
Comma-separated list of packages to install (see available packages at: https://chocolatey.org/packages)
#>

# Copyright (C) 2019 Elliot Killick <elliotkillick@zohomail.eu>
# Licensed under the MIT License. See LICENSE file for details.

Param (
    [Parameter(Mandatory=$true)][String[]]$Packages
)

$host.UI.RawUI.WindowTitle = $PSCommandPath

# Force Powershell 2 to use TLS 1.2
[System.Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([System.Net.SecurityProtocolType], 3072)

# https://chocolatey.org/install
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install -y $Packages
