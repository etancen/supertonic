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
for %%a in (%*) do (
    if /i "%%a"=="--gpu" set USE_GPU=--use-gpu
    if /i "%%a"=="-g" set USE_GPU=--use-gpu
)

echo ============================================
echo   SuperTonic TTS API Server
echo ============================================
echo   Assets: %SCRIPT_DIR%assets
echo   GPU:    %USE_GPU%
echo   URL:    http://localhost:8765
echo ============================================
echo.
echo Press Ctrl+C to stop
echo.

python "%SCRIPT_DIR%py\api_server.py" --onnx-dir "%SCRIPT_DIR%assets\onnx" --voice-dir "%SCRIPT_DIR%assets\voice_styles" %USE_GPU%

pause
