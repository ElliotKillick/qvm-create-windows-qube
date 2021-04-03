@echo off
title %~f0

:: Copyright (C) 2019 Elliot Killick <elliotkillick@zohomail.eu>
:: Licensed under the MIT License. See LICENSE file for details.

rem Certificates are added so there won't be a "Would you like to install this device software?" prompt during install
certutil -addstore -f "TrustedPublisher" "driver-certificates/qubes-test-cert.cer"
certutil -addstore -f "TrustedPublisher" "driver-certificates/the-linux-foundation.cer"
