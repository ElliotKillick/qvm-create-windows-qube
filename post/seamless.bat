@echo off
title %~f0

rem Enables seamless mode permanently across reboots

reg add "HKLM\SOFTWARE\Invisible Things Lab\Qubes Tools\qga" /v SeamlessMode /t REG_DWORD /d 1 /f
