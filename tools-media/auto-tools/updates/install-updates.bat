@echo off
title %~f0

rem Install Servicing Stack then Convenience Rollup
wusa "msu-pkgs\Windows6.1-KB3020369-x64.msu" /quiet /norestart
wusa "msu-pkgs\windows6.1-kb3125574-v4-x64_2dafb1d203c8964239af3048b5dd4b1264cd93b9.msu" /quiet /norestart
