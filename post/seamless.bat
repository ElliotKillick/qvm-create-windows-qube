@echo off
title %~f0

rem Enable seamless mode persistently across boots

reg add "HKLM\SOFTWARE\Invisible Things Lab\Qubes Tools\qga" /v SeamlessMode /t REG_DWORD /d 1 /f
