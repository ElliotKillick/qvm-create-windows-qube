@echo off
title %~f0

rem Change directory from shell:startup
cd /d D:\qubes-windows-tools

start /wait cmd /c "trust-certificates.bat"
start cmd /c "install-qwt.bat"
start cmd /c "wait-for-shutdown.bat"

rem Batch file deletes itself
(goto) 2>nul & del "%~f0"
