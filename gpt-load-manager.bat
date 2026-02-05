@echo off
setlocal enabledelayedexpansion

:: ==============================================================================
:: gpt-load - Windows Management Script
:: ==============================================================================

:: --- 变量设置 ---
set "WORK_DIR=gpt-load"
set "BINARY_NAME=gpt-load-windows-amd64.exe"
set "BINARY_PATH=%WORK_DIR%\%BINARY_NAME%"
set "REPO_URL=https://github.com/tbphp/gpt-load"
set "ENV_RAW_URL=https://raw.githubusercontent.com/LiquorXR/gpt-load-manager/main/.env.example"
set "VERSION=v0.16"

:: 检测并设置编码
chcp 65001 >nul

:show_main_menu
cls
echo.
echo ===================================================
echo      gpt-load Manager for Windows %VERSION%
echo ===================================================
echo.
echo  [1] 启动服务 (Start Service)
echo  [2] 配置环境 (Environment Config)
echo  [3] 版本更新 (Update Version)
echo  [4] 查看日志 (View Logs)
echo  [5] 停止服务 (Stop Service)
echo  [0] 退出脚本 (Exit)
echo.
echo ===================================================
echo.

set /p "menu_choice=请输入选项 [0-5]: "

if "%menu_choice%"=="1" goto start_service
if "%menu_choice%"=="2" goto config_env_menu
if "%menu_choice%"=="3" goto update_version
if "%menu_choice%"=="4" goto view_logs
if "%menu_choice%"=="5" goto stop_service
if "%menu_choice%"=="0" goto exit_script

echo [错误] 无效选项
timeout /t 2 >nul
goto show_main_menu

:start_service
cls
echo.
echo [启动服务]
echo.
if not exist "%BINARY_PATH%" (
    echo [错误] 未找到可执行文件。
    set /p "confirm=是否现在下载? (y/n): "
    if /i "!confirm!"=="y" (
        call :do_update_version
    ) else (
        goto show_main_menu
    )
)
call :check_env_file
call :check_running_service
if !running_count! gtr 0 (
    echo [警告] 检测到服务已在运行。
    set /p "confirm=是否重启服务? (y/n): "
    if /i "!confirm!"=="y" (
        call :stop_service_quiet
    ) else (
        goto show_main_menu
    )
)
echo [信息] 正在启动服务...
if not exist "%WORK_DIR%" mkdir "%WORK_DIR%"
pushd "%WORK_DIR%"
start "gpt-load-service" "%BINARY_NAME%"
popd
echo [成功] 服务已在独立窗口启动。
pause
goto show_main_menu

:config_env_menu
cls
echo.
echo [配置环境]
echo  [1] 检查并创建 .env
echo  [2] 编辑 .env (记事本)
echo  [0] 返回
echo.
set /p "env_choice=请选择: "
if "%env_choice%"=="1" (
    call :check_env_file
    pause
    goto config_env_menu
)
if "%env_choice%"=="2" (
    if exist "%WORK_DIR%\.env" (
        notepad "%WORK_DIR%\.env"
    ) else (
        echo [错误] .env 不存在
        pause
    )
    goto config_env_menu
)
if "%env_choice%"=="0" goto show_main_menu
goto config_env_menu

:update_version
cls
echo.
echo [版本更新]
set /p "confirm=确定检查并更新? (y/n): "
if /i "!confirm!"=="y" (
    call :do_update_version
)
pause
goto show_main_menu

:view_logs
cls
echo.
echo [查看日志]
set "LOG_FILE=%WORK_DIR%\data\logs\app.log"
if not exist "%LOG_FILE%" (
    echo [错误] 日志文件不存在: %LOG_FILE%
) else (
    powershell -NoProfile -Command "if (Test-Path '%LOG_FILE%') { Get-Content '%LOG_FILE%' -Tail 20 } else { Write-Host '日志文件尚为空' }"
    echo.
    set /p "open=是否打开完整日志? (y/n): "
    if /i "!open!"=="y" notepad "%LOG_FILE%"
)
pause
goto show_main_menu

:stop_service
cls
echo.
echo [停止服务]
call :stop_service_quiet
pause
goto show_main_menu

:stop_service_quiet
taskkill /F /IM "%BINARY_NAME%" >nul 2>&1
echo [信息] 已停止相关进程。
exit /b 0

:do_update_version
echo [信息] 正在通过重定向获取最新版本号...
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "$url = '%REPO_URL%/releases/latest'; $resp = Invoke-WebRequest -Uri $url -Method Head -MaximumRedirection 0 -ErrorAction SilentlyContinue; if ($resp.Headers.Location) { $tag = ($resp.Headers.Location -split '/')[-1]; $tag } else { '' }"` ) do set "LATEST_TAG=%%i"

if "%LATEST_TAG%"=="" (
    echo [错误] 无法获取最新版本号。
    exit /b 1
)

echo [信息] 检测到最新版本: %LATEST_TAG%
set "LATEST_URL=%REPO_URL%/releases/download/%LATEST_TAG%/%BINARY_NAME%"

if not exist "%WORK_DIR%" mkdir "%WORK_DIR%"
echo [信息] 正在下载程序文件...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%LATEST_URL%' -OutFile '%BINARY_PATH%'"

if exist "%BINARY_PATH%" (
    echo [成功] 更新完成 (版本: %LATEST_TAG%)。
) else (
    echo [错误] 下载失败。
)
exit /b 0

:check_env_file
if exist "%WORK_DIR%\.env" (
    echo [信息] .env 已存在。
    exit /b 0
)
if not exist "%WORK_DIR%" mkdir "%WORK_DIR%"
echo [信息] 正在从 raw 链接获取默认配置...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%ENV_RAW_URL%' -OutFile '%WORK_DIR%\.env'"
if exist "%WORK_DIR%\.env" (
    echo [成功] .env 已基于 %ENV_RAW_URL% 生成。
) else (
    echo [错误] .env 下载失败。
)
exit /b 0

:check_running_service
set "running_count=0"
for /f "usebackq" %%i in (`powershell -NoProfile -Command "(Get-Process -Name '%BINARY_NAME:.exe=%' -ErrorAction SilentlyContinue).Count"` ) do set "running_count=%%i"
if "%running_count%"=="" set "running_count=0"
exit /b 0

:exit_script
exit
