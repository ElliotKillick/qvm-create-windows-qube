@echo off
title %~f0

rem Necessary to close "Qubes private disk image initalized as disk <drive>" prompt so installer will proceed to reboot computer
set app=prepare-volume.exe
:qwt_installing
tasklist /fi "IMAGENAME eq %app%" /fi "WINDOWTITLE eq Qubes Tools for Windows" | find "%app%" >nul
if %ERRORLEVEL%==0 (taskkill /im "%app%") else (timeout 1 /nobreak & goto qwt_installing)
