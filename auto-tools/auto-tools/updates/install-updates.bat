@echo off
title %~f0

rem Install Servicing Stack then Convenience Rollup
wusa "updates\Windows6.1-KB3020369-x64.msu" /quiet /norestart
wusa "updates\windows6.1-kb3125574-v4-x64_2dafb1d203c8964239af3048b5dd4b1264cd93b9.msu" /quiet /norestart

rem Enable download and installation with no user interaction or notification
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v AUOptions /t REG_DWORD /d 4 /f
net start wuauserv
sc config wuauserv start= auto

rem Nobody likes random reboots
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /ve /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /ve /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoRebootWithLoggedOnUsers /t REG_DWORD /d 1 /f
