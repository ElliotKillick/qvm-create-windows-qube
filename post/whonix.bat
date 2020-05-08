@echo off
title %~f0

rem Based on:
rem https://www.whonix.org/wiki/Other_Operating_Systems
rem https://www.whonix.org/wiki/Disable_TCP_and_ICMP_Timestamp

rem anon-vm tag is applied to this qube: https://www.whonix.org/wiki/Dev/Qubes#anon-vm_tag
rem Right now, this denies us access to the qubes.SetDate service: dom0:/etc/qubes-rpc/policy/qubes.SetDate

echo Disabling Internet Time Syncing...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" /v Type /t REG_SZ /d NoSync /f

echo Skewing clock by +/- 0 to 180 seconds...
rem Switched from +/- 1 to 30 skew recommend in the Whonix "Other Operating Systems" documentation to +/- 0 to 180 skew due to: https://forums.whonix.org/t/bootclockrandomization-always-moving-clock-plus-or-5-seconds/2200
rem <nul is for a Windows 7 bug that causes PowerShell not to exit when used from CMD
powershell -Command Set-Date ((Get-Date).AddSeconds((Get-Random -InputObject (-180..180)))) <nul

rem Any clock skew is reset once the qube is rebooted so we must reapply the skew on every boot
rem Whonix does this for Whonix-Workstation with bootclockrandomization: https://github.com/Whonix/bootclockrandomization
schtasks /create /ru SYSTEM /sc onstart /tn "Skew Clock" /tr "powershell -Command Set-Date ((Get-Date).AddSeconds((Get-Random -InputObject (-180..180))))"

echo Disabling TCP timestamps...
netsh int tcp set global timestamps=disabled

echo Disabling ICMP timestamps...
netsh firewall set icmpsetting 13 disable

rem I checked what happens on a suspend/resume:
rem     - The clock keeps its original skew
rem     - The clock jumps forward to make up for the time it was suspended
rem     - All seems good
rem Things to consider (https://www.whonix.org/wiki/Network_Time_Synchronization#Summary):
rem     - Does Windows send out traffic before running the "Skew Clock" task (Should not let Windows access Internet until skew is applied)
rem     - There is no sdwdate equivalent for Windows
