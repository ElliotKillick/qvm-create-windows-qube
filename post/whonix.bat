@echo off
title %~f0

:: Copyright (C) 2019 Elliot Killick <elliotkillick@zohomail.eu>
:: Licensed under the MIT License. See LICENSE file for details.

rem Based on:
rem https://www.whonix.org/wiki/Other_Operating_Systems
rem https://www.whonix.org/wiki/Disable_TCP_and_ICMP_Timestamp

rem anon-vm tag is applied to this qube: https://www.whonix.org/wiki/Dev/Qubes#anon-vm_tag
rem Right now, this denies us access to the qubes.SetDate service

echo Disabling Internet Time Syncing...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" /v Type /t REG_SZ /d NoSync /f

echo Skewing clock by +/- 0 to 180 seconds...
rem Switched from +/- 1 to 30 skew recommend in the Whonix "Other Operating Systems" documentation to +/- 0 to 180 skew due to: https://forums.whonix.org/t/bootclockrandomization-always-moving-clock-plus-or-5-seconds/2200
rem Any clock skew is reset once the qube reboots so we must reapply the skew on every boot
rem Whonix does this for Whonix-Workstation with bootclockrandomization: https://github.com/Whonix/bootclockrandomization
schtasks /create /ru SYSTEM /sc onstart /tn "Skew Clock" /tr "powershell -Command Set-Date ((Get-Date).AddSeconds((Get-Random -InputObject (-180..180))))"
schtasks /run /tn "Skew Clock"

echo Disabling TCP timestamps...
netsh int tcp set global timestamps=disabled

echo Disabling ICMP timestamps...
netsh firewall set icmpsetting 13 disable

rem I checked what happens to clock skew on a suspend and resume:
rem     - The clock keeps its original skew
rem     - The clock jumps forward to make up for the time it was suspended
rem     - All seems good

rem Things to consider:
rem     - Does Windows send out traffic before running the "Skew Clock" task (Should not let Windows access the Internet until skew is applied)
rem     - There is no sdwdate equivalent for Windows
rem     - https://www.whonix.org/wiki/Network_Time_Synchronization#Summary
rem     - Potentially add host firewall rules like Whonix-Workstation does: https://github.com/Whonix/whonix-firewall/blob/master/usr/bin/whonix-host-firewall
