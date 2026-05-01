@echo off
setlocal enabledelayedexpansion
title SuperTonic TTS API

set SCRIPT_DIR=%~dp0
set VENV_DIR=%SCRIPT_DIR%venv

:: --- Check virtual environment ---
if not exist "%VENV_DIR%\Scripts\python.exe" (
    echo Virtual environment not found in:
    echo   %VENV_DIR%
    echo.
    echo Run install.bat first to create it.
    pause
    exit /b 1
)

:: --- Parse arguments ---
set USE_GPU=
set NO_GPU=0
for %%a in (%*) do (
    if /i "%%a"=="--gpu" set USE_GPU=--use-gpu
    if /i "%%a"=="-g" set USE_GPU=--use-gpu
    if /i "%%a"=="--no-gpu" set NO_GPU=1
)

:: --- Auto-detect GPU ---
if "%USE_GPU%"=="" if "%NO_GPU%"=="0" (
    "%VENV_DIR%\Scripts\python.exe" -c "import onnxruntime; p=onnxruntime.get_available_providers(^); exit(0 if 'CUDAExecutionProvider' in p else 1^)" 2>nul
    if !ERRORLEVEL! equ 0 set USE_GPU=--use-gpu
)

echo ============================================
echo   SuperTonic TTS API Server
echo ============================================
echo   Assets: %SCRIPT_DIR%assets
if "%USE_GPU%"=="--use-gpu" (echo   GPU:    auto-detected ^(CUDA^)^) else (echo   GPU:    no ^(CPU mode^)^)
echo   URL:    http://localhost:8765
echo   Docs:   http://localhost:8765/docs
echo   Log:    %SCRIPT_DIR%logs\server.log
echo ============================================
echo.
echo Press Ctrl+C to stop
echo.

if not exist "%SCRIPT_DIR%logs" mkdir "%SCRIPT_DIR%logs"

"%VENV_DIR%\Scripts\python.exe" "%SCRIPT_DIR%py\api_server.py" --onnx-dir "%SCRIPT_DIR%assets\onnx" --voice-dir "%SCRIPT_DIR%assets\voice_styles" --log-file "%SCRIPT_DIR%logs\server.log" %USE_GPU%

pause
