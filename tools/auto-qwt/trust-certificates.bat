@echo off
title %~f0

rem Certificates are added so there won't be a "Would you like to install this device software?" prompt during install
certutil -addstore -f "TrustedPublisher" "driver-certificates/qubes-test-cert.cer"
certutil -addstore -f "TrustedPublisher" "driver-certificates/the-linux-foundation.cer"
