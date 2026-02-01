@echo off
chcp 65001 >nul
title MyEduApp - Kurulum
echo.
echo ========================================
echo MyEduApp - Otomatik Kurulum
echo ========================================
echo.
echo Bu kurulum icin yonetici yetkisi gereklidir.
echo.
echo PowerShell yonetici olarak aciliyor...
echo.

powershell -ExecutionPolicy Bypass -NoProfile -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -NoProfile -File \"%~dp0KURULUM.ps1\"' -Verb RunAs"

timeout /t 2 >nul
