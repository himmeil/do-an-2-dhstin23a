@echo off
setlocal
title Dia Diem - Backend
cd /d "%~dp0"

:start
cls
echo ========================================
echo       DIA DIEM - BACKEND LOCAL
echo ========================================
echo Backend: http://localhost:8787
echo.
npm.cmd start

if errorlevel 1 (
  echo.
  echo Backend da dung do co loi.
) else (
  echo.
  echo Backend da dung.
)

:menu
echo.
echo [R] Reload backend
echo [Q] Thoat cua so backend
choice /c RQ /n /m "Chon: "
if errorlevel 2 goto :exit
if errorlevel 1 goto :start

:exit
endlocal
exit /b
