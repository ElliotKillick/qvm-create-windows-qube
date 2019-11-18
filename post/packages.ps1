<#
.SYNOPSIS
Installs Chocolatey and specified packages
.PARAMETER Packages
Comma-separated list of packages to pre-install (see available packages at: https://chocolatey.org/packages)
#>

Param (
    [Parameter(Mandatory=$true)][String[]]$Packages
)

# https://chocolatey.org/install
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

foreach ($package in $Packages)
{
    choco install -y $package
}
