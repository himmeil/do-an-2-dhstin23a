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
if not exist "dulieucanhan.env" (
  echo Khong tim thay dulieucanhan.env.
  echo Hay sao chep dulieucanhan.env.example thanh dulieucanhan.env va dien cau hinh Firebase cua ban.
  goto :menu
)
call :ensure_backend
if errorlevel 1 goto :menu
for /f "tokens=5" %%P in ('netstat -ano ^| findstr /R /C:":5000 .*LISTENING"') do (
  if not "%%P"=="0" (
    echo Cong 5000 dang duoc dung boi PID %%P.
    echo Backend da san sang; neu trang web dang mo, hay tai lai trang bang F5.
    goto :menu
  )
)
echo Dang build Flutter Web...
call flutter build web --no-pub --dart-define-from-file=dulieucanhan.env
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
goto :menu

:ensure_backend
curl.exe --fail --silent --max-time 2 --output NUL http://localhost:8787/health 2>NUL
if not errorlevel 1 exit /b 0

echo Backend chua chay. Dang khoi dong backend tai http://localhost:8787 ...
start "Dia Diem - Backend" /D "%~dp0backend" cmd /k "call run_backend.bat"
for /L %%I in (1,1,20) do (
  curl.exe --fail --silent --max-time 2 --output NUL http://localhost:8787/health 2>NUL
  if not errorlevel 1 exit /b 0
  timeout /t 1 /nobreak >nul
)
echo Khong the ket noi backend. Kiem tra cua so "Dia Diem - Backend".
exit /b 1

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
