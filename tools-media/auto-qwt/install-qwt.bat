@echo off
title %~f0

cd installer
for /f "tokens=*" %%a in ('dir /b qubes-tools-*.exe') do start %%a /passive
