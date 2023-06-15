@echo off
title %~f0

:: Copyright (C) 2023 Elliot Killick <contact@elliotkillick.com>
:: Licensed under the MIT License. See LICENSE file for details.

rem Certificates are added so there won't be a "Would you like to install this device software?" prompt during install
for %%c in (certificates\*.cer) do (
    certutil -addstore -f "TrustedPublisher" "%%c"
)
