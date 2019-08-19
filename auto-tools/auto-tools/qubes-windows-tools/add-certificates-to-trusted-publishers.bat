@echo off
title %~f0

certutil -addstore -f "TrustedPublisher" "driver-certificates/base64-encoded/qubes-test-cert.cer"
certutil -addstore -f "TrustedPublisher" "driver-certificates/base64-encoded/the-linux-foundation.cer"
