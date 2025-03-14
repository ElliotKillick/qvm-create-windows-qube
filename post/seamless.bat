@echo off
title %~f0

:: Copyright (C) 2023 Elliot Killick <contact@elliotkillick.com>
:: Licensed under the MIT License. See LICENSE file for details.

rem Enable seamless mode persistently across reboots

rem old QWT
reg add "HKLM\SOFTWARE\Invisible Things Lab\Qubes Tools\qga" /v SeamlessMode /t REG_DWORD /d 1 /f
rem new QWT
reg add "HKLM\SOFTWARE\Invisible Things Lab\Qubes Tools" /v SeamlessMode /t REG_DWORD /d 1 /f
