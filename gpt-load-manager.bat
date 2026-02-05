@echo off
setlocal enabledelayedexpansion

:: ==============================================================================
:: gpt-load - Windows Management Script (ASCII Art Title)
:: ==============================================================================

:: --- 变量设置 ---
set "WORK_DIR=gpt-load"
set "BINARY_NAME=gpt-load-windows-amd64.exe"
set "BINARY_PATH=%WORK_DIR%\%BINARY_NAME%"
set "REPO_URL=https://github.com/tbphp/gpt-load"
set "ENV_RAW_URL=https://raw.githubusercontent.com/LiquorXR/gpt-load-manager/main/.env.example"
set "VERSION=v1.16"

:: 设置代码页
chcp 65001 >nul

:main_loop
:: 状态检测
call :check_running_service
call :check_config_status
call :check_binary_status

:: 显示主界面 (带 ASCII 艺术字标题)
cls
powershell -NoProfile -Command ^
    "$host.UI.RawUI.WindowTitle = 'GPT-LOAD MANAGER';" ^
    "Write-Host '';" ^
    "Write-Host '    ██████╗ ██████╗ ████████╗      ██╗      ██████╗  █████╗ ██████╗ ' -ForegroundColor White;" ^
    "Write-Host '   ██╔════╝ ██╔══██╗╚══██╔══╝      ██║     ██╔═══██╗██╔══██╗██╔══██╗' -ForegroundColor White;" ^
    "Write-Host '   ██║  ███╗██████╔╝   ██║         ██║     ██║   ██║███████║██║  ██║' -ForegroundColor White;" ^
    "Write-Host '   ██║   ██║██╔═══╝    ██║         ██║     ██║   ██║██╔══██║██║  ██║' -ForegroundColor White;" ^
    "Write-Host '   ╚██████╔╝██║        ██║         ███████╗╚██████╔╝██║  ██║██████╔╝' -ForegroundColor White;" ^
    "Write-Host '    ╚═════╝ ╚═╝        ╚═╝         ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝ ' -ForegroundColor White;" ^
    "Write-Host '';" ^
    "Write-Host '  状态信息:' -ForegroundColor DarkGray;" ^
    "Write-Host '  --------------------------------------------------' -ForegroundColor DarkGray;" ^
    "Write-Host -NoNewline '  - 程序状态: '; Write-Host '%STATUS_TEXT%' -ForegroundColor %STATUS_COLOR%;" ^
    "Write-Host -NoNewline '  - 配置文件: '; Write-Host '%CONFIG_TEXT%' -ForegroundColor %CONFIG_COLOR%;" ^
    "Write-Host '  --------------------------------------------------' -ForegroundColor DarkGray;" ^
    "Write-Host '';" ^
    "Write-Host '  [1] 启动/重启服务 (Start/Restart Service) ' -ForegroundColor Green;" ^
    "Write-Host '  [2] 停止当前服务 (Stop Current Service)       ' -ForegroundColor Red;" ^
    "Write-Host '  [3] 检查并下载更新 (Check & Download Updates) ' -ForegroundColor White;" ^
    "Write-Host '  [4] 修改配置文件 (Edit Configuration)         ' -ForegroundColor White;" ^
    "Write-Host '  [5] 查看运行日志 (View Logs)                 ' -ForegroundColor White;" ^
    "Write-Host '  [6] 重置默认配置 (Reset Default Config)       ' -ForegroundColor DarkCyan;" ^
    "Write-Host '';" ^
    "Write-Host '  [0] 退出脚本 (Exit Script)                   ' -ForegroundColor Gray;" ^
    "Write-Host ' ──────────────────────────────────────────────────' -ForegroundColor DarkGray;"
echo.

set "choice="
set /p "choice= 请选择操作项 [0-6] : "

if "%choice%"=="1" goto op_start
if "%choice%"=="2" goto op_stop
if "%choice%"=="3" goto op_update
if "%choice%"=="4" goto op_edit_env
if "%choice%"=="5" goto op_logs
if "%choice%"=="6" goto op_reset_env
if "%choice%"=="0" exit

powershell -NoProfile -Command "Write-Host ' [错误] 无效输入，请重新选择。' -ForegroundColor Red"
timeout /t 2 >nul
goto main_loop

:: --- 操作逻辑块 ---

:op_start
cls
echo.
powershell -NoProfile -Command ^
    "$ProgressPreference = 'SilentlyContinue';" ^
    "Write-Host ' [1/3] 正在检查环境...' -ForegroundColor Cyan;" ^
    "if ('!BINARY_EXISTS!' -eq 'NO') { Write-Host ' [提示] 程序文件不存在，将自动下载。' -ForegroundColor Yellow };" ^
    "if ('!CONFIG_EXISTS!' -eq 'NO') { Write-Host ' [提示] 配置文件缺失，将自动获取。' -ForegroundColor Cyan };"

if "!BINARY_EXISTS!"=="NO" call :do_update_version_quiet
if "!CONFIG_EXISTS!"=="NO" call :check_env_file_quiet

if !running_count! gtr 0 (
    powershell -NoProfile -Command "Write-Host ' [2/3] 正在停止正在运行的服务...' -ForegroundColor Red"
    call :stop_service_quiet
    timeout /t 1 >nul
)

powershell -NoProfile -Command "Write-Host ' [3/3] 正在启动服务...' -ForegroundColor Green"
if not exist "%WORK_DIR%" mkdir "%WORK_DIR%"
pushd "%WORK_DIR%"
start "gpt-load-service" "%BINARY_NAME%"
popd
echo.
powershell -NoProfile -Command "Write-Host ' [成功] 服务已在独立窗口启动。' -ForegroundColor Green"
timeout /t 2 >nul
goto main_loop

:op_stop
cls
echo.
powershell -NoProfile -Command ^
    "Write-Host ' 正在请求停止所有 gpt-load 进程...' -ForegroundColor Yellow;" ^
    "taskkill /F /IM '%BINARY_NAME%' /T 2>$null;" ^
    "Write-Host ' [信息] 停止指令已发送。' -ForegroundColor Gray;"
echo.
echo 按任意键继续...
pause >nul
goto main_loop

:op_update
cls
echo.
if not exist "%WORK_DIR%" mkdir "%WORK_DIR%"
powershell -NoProfile -Command ^
    "$ProgressPreference = 'SilentlyContinue';" ^
    "Write-Host ' [检查更新] 正在连接 GitHub...' -ForegroundColor Cyan;" ^
    "$url = '%REPO_URL%/releases/latest';" ^
    "$resp = Invoke-WebRequest -Uri $url -Method Head -MaximumRedirection 0 -ErrorAction SilentlyContinue;" ^
    "if ($resp.Headers.Location) {" ^
    "  $tag = ($resp.Headers.Location -split '/')[-1];" ^
    "  Write-Host \" 正在下载版本: $tag ...\" -ForegroundColor Cyan;" ^
    "  Write-Host '';" ^
    "  $dl = '%REPO_URL%/releases/download/' + $tag + '/%BINARY_NAME%';" ^
    "  & { param($url, $outFile)" ^
    "    $client = New-Object System.Net.WebClient;" ^
    "    $Global:lastTotal = '...';" ^
    "    $eventJob = Register-ObjectEvent -InputObject $client -EventName DownloadProgressChanged -Action {" ^
    "      $percent = $Event.SourceEventArgs.ProgressPercentage;" ^
    "      $received = [math]::Round($Event.SourceEventArgs.BytesReceived / 1MB, 2);" ^
    "      $total = [math]::Round($Event.SourceEventArgs.TotalBytesToReceive / 1MB, 2);" ^
    "      $barWidth = 40;" ^
    "      $filled = [math]::Floor($barWidth * $percent / 100);" ^
    "      $empty = $barWidth - $filled;" ^
    "      $bar = '█' * $filled + ' ' * $empty;" ^
    "      Write-Host \"`r  $bar $percent%% ($received MB / $total MB)                \" -NoNewline;" ^
    "      $Global:lastTotal = \"$total MB\";" ^
    "    };" ^
    "    $client.DownloadFileAsync($url, $outFile);" ^
    "    while ($client.IsBusy) { Start-Sleep -Milliseconds 100 }" ^
    "    Unregister-Event -SourceIdentifier $eventJob.Name;" ^
    "    Write-Host \"`r  ████████████████████████████████████████ 100%% ($Global:lastTotal)                \" -ForegroundColor Green;" ^
    "    $client.Dispose();" ^
    "    Write-Host '';" ^
    "  } $dl '%BINARY_PATH%';" ^
    "  if (Test-Path '%BINARY_PATH%') { Write-Host \" [成功] 程序已成功更新至 $tag\" -ForegroundColor Green } else { Write-Host \" [错误] 下载失败。\" -ForegroundColor Red }" ^
    "} else {" ^
    "  Write-Host ' [错误] 无法获取版本信息，请检查网络。' -ForegroundColor Red;" ^
    "}"
echo.
echo 按任意键继续...
pause >nul
goto main_loop

:op_edit_env
if exist "%WORK_DIR%\.env" (
    notepad "%WORK_DIR%\.env"
) else (
    powershell -NoProfile -Command "Write-Host ' [错误] 找不到 .env 文件，请先选择 [6] 初始化。' -ForegroundColor Red"
    echo 按任意键继续...
    pause >nul
)
goto main_loop

:op_logs
cls
echo.
set "LOG_FILE=%WORK_DIR%\data\logs\app.log"
powershell -NoProfile -Command ^
    "Write-Host ' [运行日志 - 最近20行]' -ForegroundColor Cyan;" ^
    "if (Test-Path '%LOG_FILE%') {" ^
    "  Write-Host ' --------------------------------------------------' -ForegroundColor DarkGray;" ^
    "  Get-Content '%LOG_FILE%' -Tail 20;" ^
    "  Write-Host ' --------------------------------------------------' -ForegroundColor DarkGray;" ^
    "} else {" ^
    "  Write-Host ' [提示] 尚未生成任何日志文件。' -ForegroundColor Yellow;" ^
    "}"
echo.
if exist "%LOG_FILE%" (
    set /p "open_full= 是否使用记事本打开完整日志? (y/N) : "
    if /i "!open_full!"=="y" notepad "%LOG_FILE%"
) else (
    echo 按任意键继续...
    pause >nul
)
goto main_loop

:op_reset_env
cls
echo.
powershell -NoProfile -Command "Write-Host ' [重置配置] 即将获取最新的默认配置。' -ForegroundColor Yellow"
if exist "%WORK_DIR%\.env" (
    set /p "confirm= 当前配置文件已存在，是否覆盖? (y/N) : "
    if /i not "!confirm!"=="y" goto main_loop
)
call :check_env_file_quiet
echo.
echo 按任意键继续...
pause >nul
goto main_loop

:: --- 内部工具函数 ---

:check_running_service
set "running_count=0"
for /f "usebackq" %%i in (`powershell -NoProfile -Command "(Get-Process -Name '%BINARY_NAME:.exe=%' -ErrorAction SilentlyContinue).Count"` ) do set "running_count=%%i"
if "%running_count%"=="" set "running_count=0"
if !running_count! gtr 0 (
    set "STATUS_TEXT=运行中 (实例: !running_count!)"
    set "STATUS_COLOR=Green"
) else (
    set "STATUS_TEXT=已停止"
    set "STATUS_COLOR=Red"
)
exit /b 0

:check_config_status
if exist "%WORK_DIR%\.env" (
    set "CONFIG_EXISTS=YES"
    set "CONFIG_TEXT=已就绪"
    set "CONFIG_COLOR=Green"
) else (
    set "CONFIG_EXISTS=NO"
    set "CONFIG_TEXT=缺失"
    set "CONFIG_COLOR=Yellow"
)
exit /b 0

:check_binary_status
if exist "%BINARY_PATH%" (
    set "BINARY_EXISTS=YES"
) else (
    set "BINARY_EXISTS=NO"
)
exit /b 0

:stop_service_quiet
taskkill /F /IM "%BINARY_NAME%" >nul 2>&1
exit /b 0

:do_update_version_quiet
if not exist "%WORK_DIR%" mkdir "%WORK_DIR%"
powershell -NoProfile -Command ^
    "$ProgressPreference = 'SilentlyContinue';" ^
    "$url = '%REPO_URL%/releases/latest';" ^
    "$resp = Invoke-WebRequest -Uri $url -Method Head -MaximumRedirection 0 -ErrorAction SilentlyContinue;" ^
    "if ($resp.Headers.Location) {" ^
    "  $tag = ($resp.Headers.Location -split '/')[-1];" ^
    "  Write-Host ' [下载] 正在获取程序文件...' -ForegroundColor Cyan;" ^
    "  Write-Host '';" ^
    "  $dl = '%REPO_URL%/releases/download/' + $tag + '/%BINARY_NAME%';" ^
    "  & { param($url, $outFile)" ^
    "    $client = New-Object System.Net.WebClient;" ^
    "    $Global:lastTotal = '...';" ^
    "    $eventJob = Register-ObjectEvent -InputObject $client -EventName DownloadProgressChanged -Action {" ^
    "      $percent = $Event.SourceEventArgs.ProgressPercentage;" ^
    "      $received = [math]::Round($Event.SourceEventArgs.BytesReceived / 1MB, 2);" ^
    "      $total = [math]::Round($Event.SourceEventArgs.TotalBytesToReceive / 1MB, 2);" ^
    "      $barWidth = 40;" ^
    "      $filled = [math]::Floor($barWidth * $percent / 100);" ^
    "      $empty = $barWidth - $filled;" ^
    "      $bar = '█' * $filled + ' ' * $empty;" ^
    "      Write-Host \"`r  $bar $percent%% ($received MB / $total MB)                \" -NoNewline;" ^
    "      $Global:lastTotal = \"$total MB\";" ^
    "    };" ^
    "    $client.DownloadFileAsync($url, $outFile);" ^
    "    while ($client.IsBusy) { Start-Sleep -Milliseconds 100 }" ^
    "    Unregister-Event -SourceIdentifier $eventJob.Name;" ^
    "    Write-Host \"`r  ████████████████████████████████████████ 100%% ($Global:lastTotal)                \" -ForegroundColor Green;" ^
    "    $client.Dispose();" ^
    "    Write-Host '';" ^
    "  } $dl '%BINARY_PATH%';" ^
    "}"
exit /b 0

:check_env_file_quiet
if not exist "%WORK_DIR%" mkdir "%WORK_DIR%"
powershell -NoProfile -Command ^
    "$ProgressPreference = 'SilentlyContinue';" ^
    "Write-Host ' [下载] 正在获取配置文件...' -ForegroundColor Cyan;" ^
    "Write-Host '';" ^
    "  & { param($url, $outFile)" ^
    "    $client = New-Object System.Net.WebClient;" ^
    "    $Global:lastTotalEnv = '...';" ^
    "    $eventJob = Register-ObjectEvent -InputObject $client -EventName DownloadProgressChanged -Action {" ^
    "      $percent = $Event.SourceEventArgs.ProgressPercentage;" ^
    "      $received = [math]::Round($Event.SourceEventArgs.BytesReceived / 1KB, 2);" ^
    "      $total = [math]::Round($Event.SourceEventArgs.TotalBytesToReceive / 1KB, 2);" ^
    "      $barWidth = 40;" ^
    "      $filled = [math]::Floor($barWidth * $percent / 100);" ^
    "      $empty = $barWidth - $filled;" ^
    "      $bar = '█' * $filled + ' ' * $empty;" ^
    "      Write-Host \"`r  $bar $percent%% ($received KB / $total KB)                \" -NoNewline;" ^
    "      $Global:lastTotalEnv = \"$total KB\";" ^
    "    };" ^
    "    $client.DownloadFileAsync($url, $outFile);" ^
    "    while ($client.IsBusy) { Start-Sleep -Milliseconds 100 }" ^
    "    Unregister-Event -SourceIdentifier $eventJob.Name;" ^
    "    Write-Host \"`r  ████████████████████████████████████████ 100%% ($Global:lastTotalEnv)                \" -ForegroundColor Green;" ^
    "    $client.Dispose();" ^
    "    Write-Host '';" ^
    "  } '%ENV_RAW_URL%' '%WORK_DIR%\.env';"
exit /b 0
