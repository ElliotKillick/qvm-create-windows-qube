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
for %%s in ("BFE" "SSDPSRV" "lmhosts" "VSS" "MpsSvc") do (
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

echo Deleting shadow copies...
rem Some have already been created during installation of Windows, drivers, etc.
vssadmin delete shadows /all /quiet

echo Disabling system protection (Restore points)...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v RPSessionInterval /t REG_DWORD /d 0 /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SPP\Clients" /f

echo Disabling remote assistance...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance" /v fAllowToGetHelp /t REG_DWORD /d 0 /f

echo Disabling tasks in Task Scheduler...
set task_dir=\Microsoft\Windows
for %%t in ("%task_dir%\Application Experience\AitAgent" "%task_dir%\Autochk\Proxy" "%task_dir%\Customer Experience Improvement Program\Consolidator" "%task_dir%\Customer Experience Improvement Program\KernelCeipTask" "%task_dir%\Customer Experience Improvement Program\UsbCeip" "%task_dir%\Defrag\ScheduledDefrag" "%task_dir%\Defrag\ScheduledDefrag" "%task_dir%\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" "%task_dir%\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver" "%task_dir%\Maintenance\WinSAT" "%task_dir%\SystemRestore\SR" "%task_dir%\WindowsBackup\ConfigNotification") do (
    schtasks /change /tn %%t /disable
)

rem QWT installer has already enabled the "Power" service and configured settings as suggested
echo Disabling hibernation...
rem powercfg -h off fails when Qubes GUI driver is installed because of legacy driver "VgaSave"
rem We instead edit the registry key directly as a workaround causing %SystemDrive%\hiberfil.sys to be deleted on next boot
powercfg -h off || reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v HibernateEnabled /t REG_DWORD /d 0 /f
