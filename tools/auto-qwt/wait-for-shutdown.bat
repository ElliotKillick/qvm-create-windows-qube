@echo off
title %~f0

:: Copyright (C) 2023 Elliot Killick <contact@elliotkillick.com>
:: Licensed under the MIT License. See LICENSE file for details.

rem Close "Qubes private disk image initalized as disk <drive>" prompt so installer will proceed to reboot computer
set app=prepare-volume.exe
:qwt_installing
tasklist /fi "IMAGENAME eq %app%" /fi "WINDOWTITLE eq Qubes Tools for Windows" | find "%app%" >nul
if %ERRORLEVEL%==0 (taskkill /im "%app%") else (timeout 1 /nobreak >nul & goto qwt_installing)
