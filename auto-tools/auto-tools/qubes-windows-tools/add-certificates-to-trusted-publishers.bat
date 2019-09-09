@echo off
title %~f0

certutil -addstore -f "TrustedPublisher" "driver-certificates/qubes-test-cert.cer"
certutil -addstore -f "TrustedPublisher" "driver-certificates/the-linux-foundation.cer"
