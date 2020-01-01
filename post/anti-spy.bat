@echo off
title %~f0

rem Answer file disables Customer Experience Improvement Program (CEIP) and Windows Error Reporting (WER)

rem In Windows 10, ProtectYourPC disables more telemetry (It functions differently from previous Windows versions where it configured automatic updates)
rem https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-oobe-protectyourpc

rem The DiagTrack service is used for sending telemetry data to Microsoft
rem This opts out of even "Basic" telemetry
sc config DiagTrack start= disabled
