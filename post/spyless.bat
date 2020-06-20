@echo off
title %~f0

rem Answer file disables Customer Experience Improvement Program (CEIP) and Windows Error Reporting (WER) but do it again in case a custom answer file is in use
reg add "HKLM\SOFTWARE\Microsoft\SQMClient\Windows" /v CEIPEnable /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f

rem In Windows 10 answer files, ProtectYourPC changes settings in the Settings application to disable telemetry in Windows
rem This is opposed to its function in previous versions of Windows where it configured automatic updates
rem https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-oobe-protectyourpc

rem Set telemetry level to "Security" which is the lowest possible
rem Levels of telemetry: https://docs.microsoft.com/en-us/windows/privacy/configure-windows-diagnostic-data-in-your-organization
rem This telemetry level is disallowed on Windows 10 Pro or lesser editions of Windows 10 made for typical end users
rem The Windows installation must be some type of Enterprise edition of Windows 10 or Windows Server 2016+
rem Otherwise, the telemetry level is locked in at the next level up, which is "Basic"
rem Still doesn't disable everything: https://www.softscheck.com/en/privacy-analysis-windows-10-enterprise-telemetry-level-0/
rem Does disabling DiagTrack mitigate the information leaks in the above article?
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f

rem The DiagTrack service is used for sending Windows telemetry data to Microsoft
sc config DiagTrack start= disabled

rem This disables the bulk of the telemetry, at least for what is necessary in a VM, while providing zero impact on user experience
rem For Windows 7, I think this is sufficient, but for Windows 10 I will recommend the following if you're looking to go further

rem I recommend this script because it's based on official Microsoft documentation (See .NOTES section):
rem https://github.com/cryps1s/DARKSURGEON/blob/master/configuration/configuration-scripts/Set-WindowsTelemetrySettings.ps1

rem Of course, the best option is to air gap Windows or refrain from using it
