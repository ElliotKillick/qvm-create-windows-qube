@echo off
title %~f0

:: Copyright (C) 2023 Elliot Killick <contact@elliotkillick.com>
:: Licensed under the MIT License. See LICENSE file for details.

rem Automatically run by answer file upon first boot after installation

set from_drive=D:
set to_drive=E:

if "%~d0" == "%from_drive%" (
    rem After changing the drive letter the batch file is on, the command processor will no longer be able to read from it line-by-line and close
    rem Therefore, we must run run.bat again on the same line
    start /min /wait cmd /c "%from_drive%\change-drive-letter.bat %from_drive% %to_drive%" & start /min cmd /c "%to_drive%\run.bat"
)
cd /d %to_drive% || exit

start wscript "allow-drivers.vbs"
start /min /wait cmd /c "trust-certificates.bat"
start /min cmd /c "install-qwt.bat"
start /min cmd /c "wait-for-shutdown.bat"
