@echo off
title %~f0

rem Automatically run by answer file upon first boot after installation

cd /d D:

rem Not necessary because network configuration is done automatically once Qubes Windows Tools is installed
rem start cmd /c "connect-to-network.bat"
start cmd /c "cd chocolatey && "get-packages.bat""
rem Run now because it take one restart for this setting to take effect
start cmd /c "cd qubes-windows-tools && "allow-unsigned-drivers.bat""
start cmd /c "cd qubes-windows-tools && "install-qwt-startup-task.bat""
start cmd /c "cd updates && "install-updates.bat""

rem If the PPID of any cmd.exe is equal to the PID of this process we will wait for them to exit and then shutdown
for /f "tokens=2 usebackq" %%p in (`tasklist /v /fi "IMAGENAME eq cmd.exe" ^| findstr /l %~f0`) do set PID=%%p
:jobs_running
wmic process where (parentprocessid="%PID%" and name="cmd.exe") | findstr /l "No Instance(s) Available." >nul
if %ERRORLEVEL%==0 timeout 5 /nobreak && goto jobs_running

shutdown /s /t 0
