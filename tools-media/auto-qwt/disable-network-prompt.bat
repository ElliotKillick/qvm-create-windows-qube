@echo off
title %~f0

rem Disable network prompt because it's an unnecessary prompt that won't be interacted with
rem Also, on Windows Server 2012 R2+ it blocks allow-device-software.vbs from focusing on a window which causes the installation to halt

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff" /f
