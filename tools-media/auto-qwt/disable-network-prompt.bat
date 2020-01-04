@echo off
title %~f0

rem Disable network prompt because it's an unnecessary prompt that won't be interacted with (Purely cosmetic)

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff" /f
