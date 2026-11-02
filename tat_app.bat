@echo off
setlocal

echo Dang tat backend tren cong 8787 va Flutter Web tren cong 5000...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$titles='Dia Diem - Backend','Dia Diem - Flutter Web'; $all=Get-CimInstance Win32_Process; $processes=Get-Process | Where-Object { $titles -contains $_.MainWindowTitle } | Select-Object -ExpandProperty Id -Unique; $processes=@($processes)+@($all | Where-Object { $_.CommandLine -match 'run_backend.bat|run_web.bat' } | Select-Object -ExpandProperty ProcessId); $ports=8787,5000; $processes=@($processes)+@(Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $ports -contains $_.LocalPort } | Select-Object -ExpandProperty OwningProcess -Unique); function Stop-Tree([int]$rootId) { foreach ($child in $all | Where-Object { $_.ParentProcessId -eq $rootId }) { Stop-Tree ([int]$child.ProcessId) }; if ($rootId -and $rootId -ne $PID) { Stop-Process -Id $rootId -Force -ErrorAction SilentlyContinue; Write-Output ('Da tat PID ' + $rootId) } }; foreach ($processId in ($processes | Select-Object -Unique)) { Stop-Tree ([int]$processId) }"
echo Da tat cac tien trinh dang lang nghe cong 8787 va 5000.
echo Da dong cac tien trinh backend va Flutter Web.
endlocal
