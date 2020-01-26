@echo off
title %~f0

rem Based on:
rem https://www.whonix.org/wiki/Other_Operating_Systems
rem https://www.whonix.org/wiki/Disable_TCP_and_ICMP_Timestamps

echo Disabling Internet Time Syncing...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" /v Type /t REG_SZ /d NoSync /f

rem https://www.whonix.org/wiki/Dev/Qubes#anon-vm_tag
rem anon-vm tag is set on this VM so I don't think it's necessary to delete qubes.setDateTime RPC service as done here:
rem https://phabricator.whonix.org/T397 (As can be seen in T398 and by observing a whonix-ws AppVM this service now just logs the event to check for possible regressions)
rem It looks like that issue should not even be open anymore?
rem Also, in Dom0 at /etc/qubes-rpc/policy/qubes.SetDate anon-vm tagged VMs are denied access to the service so that confirms that we are not able to access that service

echo Skewing clock by +/- 0 to 180 seconds...
rem Switched to +/- 0 to 180 skew from +/- 1 to 30 skew which is the skew the Whonix "Other Operating Systems" documentation suggests due to: https://forums.whonix.org/t/bootclockrandomization-always-moving-clock-plus-or-5-seconds/2200
rem <nul is for a Windows 7 bug that causes PowerShell not to exit, on newer versions of Windows this bug is fixed
powershell -Command Set-Date ((Get-Date).AddSeconds((Get-Random -InputObject (-180..180)))) <nul

rem Any clock skew is reset once the qube is rebooted so we must reapply the skew on every boot
rem Whonix also seems to do this for Whonix-Workstation with bootclockrandomization (https://github.com/Whonix/bootclockrandomization): https://groups.google.com/forum/#!topic/qubes-devel/aN3IOv6JmKw
schtasks /create /ru SYSTEM /sc onstart /tn "Skew Clock" /tr "powershell -Command Set-Date ((Get-Date).AddSeconds((Get-Random -InputObject (-180..180))))"

rem I checked what would happen on a suspend/resume
rem     - The clock keeps it's original skew
rem     - The clock jumps forward to make up for the time it was suspended
rem     - All seems good
rem Things to consider (https://www.whonix.org/wiki/Network_Time_Synchronization#Summary):
rem     - Does Windows send out traffic before running the clock skew task (Should not let Windows access Internet until skew is applied)
rem     - There is no sdwdate equivalent for Windows

echo Disabling TCP timestamps...
netsh int tcp set global timestamps=disabled

echo Disable ICMP timestamps...
netsh firewall set icmpsetting 13 disable
