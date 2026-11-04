@echo off
setlocal
cd /d "%~dp0"

if not exist "dulieucanhan.env" (
  echo Khong tim thay dulieucanhan.env.
  echo Hay tao file nay tu dulieucanhan.env.example va dien cau hinh Firebase cua ban.
  exit /b 1
)

for /f "delims=" %%P in ('powershell -NoProfile -Command "(Get-Content dulieucanhan.env -Raw | ConvertFrom-Json).FIREBASE_PROJECT_ID"') do set "FIREBASE_PROJECT_ID=%%P"
if not defined FIREBASE_PROJECT_ID (
  echo Khong doc duoc FIREBASE_PROJECT_ID tu dulieucanhan.env.
  exit /b 1
)

echo Dang build Firebase Web; tinh nang tai ban do offline se bi tat...
call flutter build web --release --no-pub --dart-define-from-file=dulieucanhan.env --dart-define=APP_MODE=firebase
if errorlevel 1 exit /b 1

echo Dang deploy Hosting...
call firebase deploy --only hosting --project "%FIREBASE_PROJECT_ID%"
if errorlevel 1 exit /b 1

echo Deploy hoan tat.
endlocal
