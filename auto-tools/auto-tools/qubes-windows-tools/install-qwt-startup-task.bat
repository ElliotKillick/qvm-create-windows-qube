@echo off
title %~f0

set startup_dir=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup

mkdir "%startup_dir%"
copy "qwt-startup-task.bat" "%startup_dir%"
