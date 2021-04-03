@echo off
title %~f0

:: Copyright (C) 2019 Elliot Killick <elliotkillick@zohomail.eu>
:: Licensed under the MIT License. See LICENSE file for details.

cd installer
for /f "tokens=*" %%a in ('dir /b qubes-tools-*.exe') do start %%a /passive
