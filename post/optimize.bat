@echo off
title %~f0

rem Based on: https://www.qubes-os.org/doc/windows-template-customization

echo Disabling features...
for %%f in ("WindowsGadgetPlatform" "TabletPCOC" "MSRDC-Infrastructure" "Printing-XPSServices-Features" "Xps-Foundation-Xps-Viewer") do (
    dism /norestart /online /disable-feature /featurename:%%f
)

echo Disabling services...
rem Some of the services listed on the above documentation are already disabled and as a result not included here (Some such as the "Disk Defragmenter" or "defragsvc" service are set to disabled (in this case from manual) by QWT upon installation)
rem Result of diabling "Themes" seems to be the same as adjusting visual effects below (However, with it disabled now someone would also have to manually enable the Themes service to get themes back)
for %%s in ("SSDPSRV" "lmhosts" "VSS") do (
    sc config %%s start= disabled
)

echo Enabling never check for updates...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v AUOptions /t REG_DWORD /d 1 /f

echo Enabling never automatically reboot for updates...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /ve /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /ve /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoRebootWithLoggedOnUsers /t REG_DWORD /d 1 /f

rem echo Adjusting visual effects for best performance...
rem Severely reduces the appearance of Windows, however, does noticeably increase performance
rem reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f

echo Disabling Action Center tray icon and notifications...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v HideSCAHealth /t REG_DWORD /d 1 /f

echo Disabling firewall notifications...
for %%p in ("Public" "Standard" "Domain") do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\%%~pProfile" /v DisableNotifications /t REG_DWORD /d 1 /f
)

echo Disabling Windows SmartScreen...
rem Internet Explorer, Explorer, Edge and Store respectively
reg add "HKCU\Software\Microsoft\Internet Explorer\PhishingFilter" /v EnabledV9 /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d Off /f
reg add "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\PhishingFilter" /v EnabledV9 /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v EnableWebContentEvaluation /t REG_DWORD /d 0 /f

echo Disabling Windows Defender...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f || (
    rem Fails due to Tamper Protection which is enabled by default in latest versions of Windows 10
    rem To bypass it and disable Windows Defender anyway we remove all permissions from the WinDefend service registry key (The ownership changing is not necessary, it's just so the change can be easily reverted without getting SYSTEM)
    rem This change is not detected by sfc /scannow, however, may be reset by a Windows update
    rem To restore permissions, open permission info on the key below and change the owner to "SYSTEM" then click "Enable Inheritance"
    powershell -Command "$path = 'HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend\'; $acl = Get-Acl -Path $path; $acl.SetOwner((New-Object System.Security.Principal.NTAccount('Builtin', 'Administrators'))); $acl.SetAccessRuleProtection($true, $false); Set-Acl -Path $path -AclObject $acl"
)

echo Deleting shadow copies...
rem Some have already been created during installation of Windows, drivers, etc.
vssadmin delete shadows /all /quiet

echo Disabling system protection (Restore points)...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v RPSessionInterval /t REG_DWORD /d 0 /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SPP\Clients" /f

echo Disabling remote assistance...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance" /v fAllowToGetHelp /t REG_DWORD /d 0 /f

echo Allowing all inbound and outbound traffic through firewall...
netsh advfirewall set allprofiles firewallpolicy allowinbound,allowoutbound

echo Disabling tasks in Task Scheduler...
set task_dir=\Microsoft\Windows
for %%t in ("%task_dir%\Defrag\ScheduledDefrag" "%task_dir%\Defrag\ScheduledDefrag" "%task_dir%\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver" "%task_dir%\Maintenance\WinSAT" "%task_dir%\SystemRestore\SR" "%task_dir%\WindowsBackup\ConfigNotification") do (
    schtasks /change /tn %%t /disable
)

rem QWT installer has already enabled the "Power" service and configured settings as suggested
echo Disabling hibernation...
rem powercfg -h off fails when Qubes GUI driver is installed because of legacy driver "VgaSave"
rem We instead edit the registry key directly as a workaround causing %SystemDrive%\hiberfil.sys to be deleted on next boot
powercfg -h off || reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v HibernateEnabled /t REG_DWORD /d 0 /f
