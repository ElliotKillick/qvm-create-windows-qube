@echo off
title %~f0

rem This file is yours to customize and add what ever custom commands you would like to it

rem Post QWT scripts
set post_iso_drive=D:
set "packages="

cd /d %post_iso_drive%

rem Optimizing Windows...
start /min /wait cmd /c optimize.bat

rem Disabling Windows telemetry...
start /min /wait cmd /c spyless.bat

rem Applying Whonix recommended settings for a Windows-Whonix-Workstation...
start /min /wait cmd /c whonix.bat

if not "%packages%"=="" (
rem Installing packages...
powershell -ExecutionPolicy Bypass -Command .\\packages.ps1 %packages% <nul
)

shutdown /s /t 0
