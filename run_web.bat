@echo off
setlocal
title Dia Diem - Flutter Web
cd /d "%~dp0"

:build
cls
echo ========================================
echo       DIA DIEM - FLUTTER WEB
echo ========================================
echo Website: http://localhost:5000
for /f "tokens=5" %%P in ('netstat -ano ^| findstr /R /C:":5000 .*LISTENING"') do (
  if not "%%P"=="0" (
    echo Cong 5000 dang duoc dung boi PID %%P. Hay chay tat_app.bat truoc.
    goto :menu
  )
)
echo Dang build Flutter Web...
call flutter build web --no-pub
if errorlevel 1 (
  echo.
  echo Build that bai. Sua loi roi chon R de build lai.
  goto :menu
)

echo Dang phuc vu build\web tren cong 5000...
echo Mo trinh duyet tai http://localhost:5000
set "PYTHON_EXE="
for /f "delims=" %%P in ('where python 2^>nul ^| findstr /v /i "WindowsApps"') do if not defined PYTHON_EXE set "PYTHON_EXE=%%P"
if not defined PYTHON_EXE (
  echo Khong tim thay Python that trong PATH. Hay cai Python va bo chon App execution aliases.
  goto :menu
)
"%PYTHON_EXE%" -m http.server 5000 --directory build\web --bind 127.0.0.1
if errorlevel 1 (
  echo.
  echo Khong the chay web server. Kiem tra Python va cong 5000.
)

:menu
echo.
echo [R] Reload: build lai Flutter Web
echo [Q] Thoat cua so Flutter Web
choice /c RQ /n /m "Chon: "
if errorlevel 2 goto :exit
if errorlevel 1 goto :build

:exit
endlocal
exit /b
