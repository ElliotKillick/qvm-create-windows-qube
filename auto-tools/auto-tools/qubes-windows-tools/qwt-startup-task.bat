@echo off
title %~f0

rem Change directory from shell:startup
cd /d D:\qubes-windows-tools

rem Updates must be installed or Qubes Windows Tools install will fail
for /f %%i in ('wmic qfe list /format:list ^| findstr HotFixID ^| find /v /c ""') do set updates=%%i
if %updates% geq 4 (
    rem Certificates are added so there won't be a "Would you like to install this device software?" prompt during install
    start /wait cmd /c "add-certificates-to-trusted-publishers.bat"
    start cmd /c "install-qwt-silently.bat"

    rem Necessary to close "Qubes private disk image initalized as disk <drive>" prompt so installer will proceed to reboot computer
    rem It looks for "prepare-volume.exe" and if found, waits 20 seconds, then (hopefully after it's done making the volume), kills it
    set app=prepare-volume.exe
    :loop
    tasklist /FI "IMAGENAME eq %app%" 2>NUL | find /I /N "%app%">NUL
    set err=%ERRORLEVEL%
    timeout 20 /nobreak
    if "%err%"=="0" (taskkill /im "%app%") else goto loop

    rem Batch file deletes itself
    (goto) 2>nul & del "%~f0"
)
