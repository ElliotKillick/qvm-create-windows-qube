@echo off
title %~f0

rem Change drive letter of auto-qwt from D: to E: so QWT can install the private image on D: (Purely cosmetic)

(echo select volume 0
echo assign letter=%1
) | diskpart
