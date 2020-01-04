<#
.SYNOPSIS
Installs Chocolatey and specified packages
.PARAMETER Packages
Comma-separated list of packages to pre-install (see available packages at: https://chocolatey.org/packages)
#>

Param (
    [Parameter(Mandatory=$true)][String[]]$Packages
)

# Force Powershell 2 to use TLS 1.2
# https://social.technet.microsoft.com/Forums/en-US/fe02169c-30a5-43f5-b0fa-0c1002f7bd03/how-to-use-tls12-secuirty-in-powershell-20?forum=winserverpowershell
[System.Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([System.Net.SecurityProtocolType], 3072)

# https://chocolatey.org/install
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install -y $Packages
