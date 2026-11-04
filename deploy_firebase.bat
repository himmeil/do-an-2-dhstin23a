@echo off
setlocal
cd /d "%~dp0"

if not exist "ca_nhan\dulieucanhan.env" (
  echo Khong tim thay ca_nhan\dulieucanhan.env.
  echo Hay tao thu muc ca_nhan va sao chep dulieucanhan.env.example vao do.
  echo Dien cau hinh ca nhan roi chay lai.
  exit /b 1
)

node scripts\validate_dulieucanhan_env.mjs
if errorlevel 1 exit /b 1

for /f "delims=" %%P in ('powershell -NoProfile -Command "(Get-Content ca_nhan\dulieucanhan.env -Raw | ConvertFrom-Json).FIREBASE_PROJECT_ID"') do set "FIREBASE_PROJECT_ID=%%P"
if not defined FIREBASE_PROJECT_ID (
  echo Khong doc duoc FIREBASE_PROJECT_ID tu ca_nhan\dulieucanhan.env.
  exit /b 1
)

echo Dang build Firebase Web; tinh nang tai ban do offline se bi tat...
call flutter build web --release --no-pub --dart-define-from-file=ca_nhan/dulieucanhan.env --dart-define=APP_MODE=firebase
if errorlevel 1 exit /b 1

echo Dang deploy Hosting...
call firebase deploy --only hosting --project "%FIREBASE_PROJECT_ID%"
if errorlevel 1 exit /b 1

echo Deploy hoan tat.
endlocal
