@echo off
title %~f0

:: Copyright (C) 2019 Elliot Killick <elliotkillick@zohomail.eu>
:: Licensed under the MIT License. See LICENSE file for details.

rem Change drive letter of auto-qwt from D: to E: so QWT can install the private volume on D: (Purely cosmetic)

(echo select volume %1
echo assign letter=%2
) | diskpart
