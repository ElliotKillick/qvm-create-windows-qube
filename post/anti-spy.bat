@echo off
title %~f0

rem Answer file disables Customer Experience Improvement Program (CEIP) and Windows Error Reporting (WER)

rem In Windows 10, ProtectYourPC disables more telemetry (It functions differently from previous Windows versions where it configured automatic updates)
rem https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-oobe-protectyourpc

rem Set telemetry level to "Security" which is the lowest possible
rem Levels of telemetry: https://docs.microsoft.com/en-us/windows/privacy/configure-windows-diagnostic-data-in-your-organization
rem Only works on Windows 10 Enterprise, Education, Mobile Enterprise, and IoT Core editions, and Windows Server 2016 or higher
rem Still doesn't disable everything: https://www.softscheck.com/en/privacy-analysis-windows-10-enterprise-telemetry-level-0/
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f

rem The DiagTrack service is used for sending telemetry data to Microsoft
rem This disables sending all telemetry data
sc config DiagTrack start= disabled
