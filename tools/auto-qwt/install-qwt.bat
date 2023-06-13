@echo off
title %~f0

:: Copyright (C) 2023 Elliot Killick <contact@elliotkillick.com>
:: Licensed under the MIT License. See LICENSE file for details.

cd installer || exit
for %%i in (qubes-tools-*.exe qubes-tools-*.msi) do (
    start %%i /passive
)
