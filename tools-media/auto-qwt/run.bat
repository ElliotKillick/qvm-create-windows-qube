@echo off
title %~f0

rem Automatically run by answer file upon first boot after installation

rem Change directory to location of this batch file
cd /d "%~dp0"

start cscript "allow-device-software.vbs"
start cmd /c "install-qwt.bat"
start cmd /c "wait-for-shutdown.bat"
