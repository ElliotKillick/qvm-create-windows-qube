@echo off
title %~f0

rem Automatically run by answer file upon first boot after installation

cd /d D:

rem Not necessary because network configuration is done automatically once Qubes Windows Tools is installed
rem start cmd /c "connect-to-network.bat"
start cmd /c "cd modules && "run.bat""
rem Run now because it take one restart for this setting to take effect
start cmd /c "cd qubes-windows-tools && "allow-unsigned-drivers.bat""
start cmd /c "cd qubes-windows-tools && "install-qwt-startup-task.bat""
start /wait cmd /c "cd updates && "install-updates.bat""

shutdown /s /t 0
