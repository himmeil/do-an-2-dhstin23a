@echo off
setlocal
set "PROJECT_DIR=%~dp0"

echo Dang khoi dong backend tai http://localhost:8787 ...
start "Dia Diem - Backend" /D "%PROJECT_DIR%backend" cmd /k "call run_backend.bat"

echo Cho backend san sang...
set "HEALTH_OK="
for /L %%I in (1,1,20) do (
  curl.exe --fail --silent --max-time 2 --output NUL http://localhost:8787/health 2>NUL
  if not errorlevel 1 (
    set "HEALTH_OK=1"
    goto :backend_ready
  )
  timeout /t 1 /nobreak >nul
)

echo Khong the ket noi backend. Kiem tra cua so "Dia Diem - Backend".
exit /b 1

:backend_ready
echo Backend da san sang.
echo Dang build va khoi dong Flutter Web tai http://localhost:5000 ...
start "Dia Diem - Flutter Web" /D "%PROJECT_DIR%" cmd /k "call run_web.bat"
echo Ung dung da duoc bat.
echo Dong cua so nay khong tat ung dung. Hay chay tat_app.bat de tat dung tien trinh.
endlocal
