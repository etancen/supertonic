@echo off
setlocal enabledelayedexpansion
title SuperTonic TTS API

set SCRIPT_DIR=%~dp0
set VENV_DIR=%SCRIPT_DIR%venv

if not exist "%VENV_DIR%\Scripts\activate.bat" (
    echo Virtual environment not found. Run install.bat first.
    pause
    exit /b 1
)

call "%VENV_DIR%\Scripts\activate.bat"

:: Parse arguments
set USE_GPU=
set NO_GPU=0
for %%a in (%*) do (
    if /i "%%a"=="--gpu" set USE_GPU=--use-gpu
    if /i "%%a"=="-g" set USE_GPU=--use-gpu
    if /i "%%a"=="--no-gpu" set NO_GPU=1
)

:: Auto-detect GPU
if "%USE_GPU%"=="" if "%NO_GPU%"=="0" (
    python -c "import onnxruntime; p=onnxruntime.get_available_providers(); exit(0 if 'CUDAExecutionProvider' in p else 1)" 2>nul
    if !ERRORLEVEL! equ 0 set USE_GPU=--use-gpu
)

echo ============================================
echo   SuperTonic TTS API Server
echo ============================================
echo   Assets: %SCRIPT_DIR%assets
if "%USE_GPU%"=="--use-gpu" (echo   GPU:    auto-detected) else (echo   GPU:    no)
echo   URL:    http://localhost:8765
echo   Log:    %SCRIPT_DIR%logs\server.log
echo ============================================
echo.

if not exist "%SCRIPT_DIR%logs" mkdir "%SCRIPT_DIR%logs"

python "%SCRIPT_DIR%py\api_server.py" --onnx-dir "%SCRIPT_DIR%assets\onnx" --voice-dir "%SCRIPT_DIR%assets\voice_styles" --log-file "%SCRIPT_DIR%logs\server.log" %USE_GPU%

pause
