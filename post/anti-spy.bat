@echo off
title %~f0

rem Answer file disables Customer Experience Improvement Program (CEIP) and Windows Error Reporting (WER)

rem In Windows 10 answer files, ProtectYourPC flips switches in the Settings application to disable telemetry in Windows (It functions differently from previous Windows versions where it configured automatic updates)
rem https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-oobe-protectyourpc

rem Set telemetry level to "Security" which is the lowest possible
rem Levels of telemetry: https://docs.microsoft.com/en-us/windows/privacy/configure-windows-diagnostic-data-in-your-organization
rem Doesn't work on Windows 10 Pro or lesser editions of Windows 10 made for typical end users (Must be some type of Enterprise edition of Windows 10 or Windows Server 2016+)
rem Still doesn't disable everything: https://www.softscheck.com/en/privacy-analysis-windows-10-enterprise-telemetry-level-0/ (Does disabling DiagTrack service mitigate this?)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f

rem The DiagTrack service is used for sending Windows telemetry data to Microsoft
rem This disables sending of all Windows telemetry data to Microsoft
sc config DiagTrack start= disabled

rem This disables the bulk of the telemetry, at least for what is necessary in a VM, while providing zero impact on user experience
rem If you're looking to go further I recommend this script which is based on official Microsoft documentation (See .NOTES section): https://github.com/cryps1s/DARKSURGEON/blob/master/configuration/configuration-scripts/Set-WindowsTelemetrySettings.ps1
rem Of course, the best option is to air gap Windows or refrain from using it
