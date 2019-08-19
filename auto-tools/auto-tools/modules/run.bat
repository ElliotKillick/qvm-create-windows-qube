@echo off
title %~f0

for /f "usebackq tokens=*" %%a in ("enabled") do cd "%%a" && start cmd /c run.bat && cd ..
