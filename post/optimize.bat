@echo off
title %~f0

:: Copyright (C) 2023 Elliot Killick <contact@elliotkillick.com>
:: Licensed under the MIT License. See LICENSE file for details.

rem Based on: https://www.qubes-os.org/doc/windows-template-customization/

echo Disabling unwanted features...
for %%f in ("WindowsGadgetPlatform" "TabletPCOC" "MSRDC-Infrastructure" "Printing-XPSServices-Features" "Xps-Foundation-Xps-Viewer") do (
    dism /norestart /online /disable-feature /featurename:%%f
)

echo Enabling never automatically check for updates...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /ve /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /ve /f
rem This method of doing it was taken from how Microsoft does it with the "sconfig" command in Windows Server
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /f

echo Enabling never automatically reboot for updates with logged on users...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoRebootWithLoggedOnUsers /t REG_DWORD /d 1 /f
rem On newer versions of Windows 10, Microsoft intentionally breaks this feature to force users into automatically rebooting for updates at any time
rem To disable automatic rebooting for updates anyway, simply make MusNotification.exe unable to start (this method is popular)
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MusNotification.exe" /v Debugger /t REG_SZ /d "cmd.exe"

rem echo Adjusting visual effects for best performance...
rem Severely reduces Windows 7 appearance but on Windows 10 it's acceptable
rem Does noticeably increase performance
rem reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f

echo Disabling Windows activation notifications...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform\Activation" /v NotificationDisabled /t REG_DWORD /d 1 /f

echo Disabling Action Center tray icon and notifications...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v HideSCAHealth /t REG_DWORD /d 1 /f

echo Disabling Windows Defender Security Center notifications...
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender Security Center\Notifications" /v DisableNotifications /t REG_DWORD /d 1 /f

echo Disabling Windows SmartScreen...
rem Explorer, Internet Explorer, Edge and Store respectively
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d Off /f
reg add "HKCU\Software\Microsoft\Internet Explorer\PhishingFilter" /v EnabledV9 /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\PhishingFilter" /v EnabledV9 /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v EnableWebContentEvaluation /t REG_DWORD /d 0 /f

echo Disabling Windows Defender...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f || (
    rem Fails due to Tamper Protection which is enabled by default on newer versions of Windows 10 to stop malware from programmatically disabling Windows Defender
    rem To bypass Tamper Protection and disable Windows Defender anyway, we remove all permissions from the WinDefend service registry key by disabling permission inheritance
    rem Tamper Protection disallows deletion of the below registry key but is fine with us changing the permissions on it
    rem This simple method causes starting Windows Defender to fail on the next boot
    rem The ownership change is not necessary, it's just so a user can easily re-enable Windows Defender without getting SYSTEM privileges
    rem This change is not detected by sfc /scannow, however, may be reset by a Windows update
    rem To re-enable Windows Defender, open the advanced permission settings on the registry key below and click "Enable Inheritance" then change the owner to "SYSTEM"

    rem The Microsoft Security Response Center (MSRC) does not consider this to be a security vulnerability because it requires administrator privileges and "a malicious administrator can do much worse things"
    rem I expected this, but reported it anyway just to be sure
    rem Additionally, it's perfectly reasonable for an enterprise administrator to want to disable Windows Defender across all their Windows machines programmatically
    powershell -Command "$path = 'HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend'; $acl = Get-Acl -Path $path; $acl.SetOwner((New-Object System.Security.Principal.NTAccount('Builtin', 'Administrators'))); $acl.SetAccessRuleProtection($true, $false); Set-Acl -Path $path -AclObject $acl"
)

echo Deleting shadow copies...
rem Some may have already been created during installation of Windows, drivers, etc.
vssadmin delete shadows /all /quiet

echo Disabling system protection (restore points)...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v RPSessionInterval /t REG_DWORD /d 0 /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SPP\Clients" /f

echo Disabling remote assistance...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance" /v fAllowToGetHelp /t REG_DWORD /d 0 /f

echo Disabling password expiry...
net accounts /maxpwage:unlimited

echo Allowing all inbound and outbound traffic through firewall...
rem Security-wise this is okay because the VM connects to sys-firewall or sys-whonix as its NetVM which acts as its firewall
netsh advfirewall set allprofiles firewallpolicy allowinbound,allowoutbound

echo Disabling unwanted tasks in Task Scheduler...
set win_task_dir=\Microsoft\Windows
for %%t in ("%win_task_dir%\Defrag\ScheduledDefrag" "%win_task_dir%\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver" "%win_task_dir%\Maintenance\WinSAT" "%win_task_dir%\SystemRestore\SR" "%win_task_dir%\WindowsBackup\ConfigNotification") do (
    schtasks /change /tn %%t /disable
)

rem The QWT installer has already enabled the "Power" service and configured settings as suggested:
rem https://github.com/QubesOS/qubes-installer-qubes-os-windows-tools/blob/master/power_settings.bat

echo Disabling hibernation...
powercfg -h off || (
    rem Fails when Qubes GUI driver is installed because of legacy driver "VgaSave"
    rem We instead edit the registry key directly as a workaround causing hiberfil.sys to be deleted on the next boot as opposed to now
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v HibernateEnabled /t REG_DWORD /d 0 /f
)
