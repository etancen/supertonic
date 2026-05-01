@echo off
setlocal enabledelayedexpansion
title SuperTonic TTS Installer

set SCRIPT_DIR=%~dp0

echo ============================================
echo   SuperTonic TTS — One-Click Installer
echo ============================================
echo.

:: --- Check ONNX models ---
echo [1/4] Checking ONNX models...
set ONNX_DIR=%SCRIPT_DIR%assets\onnx
if not exist "%ONNX_DIR%\duration_predictor.onnx" (
    echo.
    echo   WARNING: ONNX models not found!
    echo   Download from: https://huggingface.co/Supertone/supertonic-2
    echo   Place .onnx files in: %ONNX_DIR%\
    echo.
    echo   Required files:
    echo     duration_predictor.onnx
    echo     text_encoder.onnx
    echo     vector_estimator.onnx
    echo     vocoder.onnx
    echo.
    choice /C YN /M "Continue without models"
    if !ERRORLEVEL! neq 1 exit /b 1
) else (
    echo   Models found
)

:: --- Check Conda ---
echo [2/4] Checking Conda...
where conda >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ERROR: Conda not found. Install Miniconda from https://docs.conda.io
    pause
    exit /b 1
)
for /f "tokens=2 delims= " %%v in ('conda --version 2^>^&1') do set CONDAVER=%%v
echo   Found Conda %CONDAVER%

:: --- Check / Create conda env ---
echo [3/4] Setting up conda environment...
set ENV_NAME=supertonic
conda env list | findstr /C:"%ENV_NAME%" >nul
if %ERRORLEVEL% neq 0 (
    echo   Creating conda environment '%ENV_NAME%'...
    conda create -n %ENV_NAME% python=3.10 -y
    if %ERRORLEVEL% neq 0 (
        echo ERROR: Failed to create conda environment
        pause
        exit /b 1
    )
    echo   Installing Python dependencies...
    conda run -n %ENV_NAME% pip install -r "%SCRIPT_DIR%py\requirements.txt"
    if %ERRORLEVEL% neq 0 (
        echo ERROR: Failed to install dependencies
        pause
        exit /b 1
    )
    echo   Dependencies installed
) else (
    echo   Conda environment '%ENV_NAME%' already exists
)

:: --- Install Obsidian plugin ---
echo [4/4] Setting up Obsidian plugin...
call "%SCRIPT_DIR%deploy-plugin.bat"

:: --- Done ---
echo.
echo ============================================
echo   Installation Complete!
echo ============================================
echo.
echo   Environment:  conda activate supertonic
echo.
echo   Usage:
echo     start.bat          - Launch API server
echo     start.bat --gpu    - Launch with GPU acceleration
echo.
echo   In Obsidian:
echo     Settings ^> Community Plugins ^> Enable "SuperTonic TTS"
echo     Settings ^> Hotkeys ^> Bind Ctrl+Shift+P to "SuperTonic: Speak selected text"
echo.
pause
