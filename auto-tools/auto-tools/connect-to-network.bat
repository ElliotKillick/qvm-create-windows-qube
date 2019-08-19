@echo off
title %~f0

rem Qubes Windows Tools configures networking automatically but without it we must configure networking statically ourselves

rem Configure static IP addresses
netsh interface ipv4 set address "Local Area Connection" static 10.137.0.48 255.255.0.0 10.137.0.8

rem Set primary and secondary DNS servers
netsh interface ipv4 set dnsservers "Local Area Connection" static 84.200.69.80 validate=no
netsh interface ipv4 add dnsservers "Local Area Connection" 84.200.70.40 validate=no

rem Set network location; 0 = Public, 1 = Private; Doesn't work for the Work location
rem Will be confifured upon reboot
rem for /f "tokens=* usebackq" %%f in (`reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles"`) do (
rem      set profile=%%f
rem )
rem reg add "%profile%" /v Category /t REG_DWORD /d 1 /f
