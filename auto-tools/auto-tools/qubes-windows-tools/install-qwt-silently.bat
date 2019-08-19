@echo off
title %~f0

cd "qubes-windows-tools"
for /f "tokens=*" %%a in ('dir /b qubes-tools-*.exe') do %%a /passive
