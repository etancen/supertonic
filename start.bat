@echo off
setlocal enabledelayedexpansion
title SuperTonic TTS API

set SCRIPT_DIR=%~dp0
set ENV_NAME=supertonic

:: --- Locate conda ---
set CONDA_CMD=conda
where conda >nul 2>nul
if %ERRORLEVEL% neq 0 (
    for %%d in ("%USERPROFILE%\miniforge3" "%USERPROFILE%\miniconda3" "%USERPROFILE%\Anaconda3" "%ProgramData%\miniforge3" "%ProgramData%\miniconda3" "%ProgramData%\Anaconda3") do (
        if exist "%%~d\Scripts\conda.exe" (
            set "CONDA_CMD=%%~d\Scripts\conda"
        )
    )
)

:: --- Check conda environment exists ---
!CONDA_CMD! env list | findstr /C:"%ENV_NAME%" >nul
if %ERRORLEVEL% neq 0 (
    echo Conda environment '%ENV_NAME%' not found. Run install.bat first.
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
    !CONDA_CMD! run -n %ENV_NAME% python -c "import onnxruntime; p=onnxruntime.get_available_providers(); exit(0 if 'CUDAExecutionProvider' in p else 1)" 2>nul
    if !ERRORLEVEL! equ 0 set USE_GPU=--use-gpu
)

echo ============================================
echo   SuperTonic TTS API Server
echo ============================================
echo   Assets: %SCRIPT_DIR%assets
if "%USE_GPU%"=="--use-gpu" (echo   GPU:    auto-detected (CUDA)) else (echo   GPU:    no (CPU mode))
echo   URL:    http://localhost:8765
echo   Docs:   http://localhost:8765/docs
echo   Log:    %SCRIPT_DIR%logs\server.log
echo ============================================
echo.
echo Press Ctrl+C to stop
echo.

if not exist "%SCRIPT_DIR%logs" mkdir "%SCRIPT_DIR%logs"

!CONDA_CMD! run -n %ENV_NAME% python "%SCRIPT_DIR%py\api_server.py" --onnx-dir "%SCRIPT_DIR%assets\onnx" --voice-dir "%SCRIPT_DIR%assets\voice_styles" --log-file "%SCRIPT_DIR%logs\server.log" %USE_GPU%

pause
