@echo off
setlocal enabledelayedexpansion
title SuperTonic TTS Installer

echo ============================================
echo   SuperTonic TTS — One-Click Installer
echo ============================================
echo.

:: --- Check ONNX models ---
echo [1/5] Checking ONNX models...
set ONNX_DIR=%~dp0assets\onnx
if not exist "%ONNX_DIR%\duration_predictor.onnx" (
    echo.
    echo   WARNING: ONNX models not found!
    echo   Download from: https://huggingface.co/SuperTone/supertonic
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

:: --- Check Python ---
echo [2/5] Checking Python...
where python >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ERROR: Python not found. Install Python 3.10+ from https://python.org
    pause
    exit /b 1
)
for /f "tokens=2 delims= " %%v in ('python --version 2^>^&1') do set PYVER=%%v
echo   Found Python %PYVER%

:: --- Create venv ---
echo [3/5] Creating virtual environment...
set VENV_DIR=%~dp0venv
if not exist "%VENV_DIR%" (
    python -m venv "%VENV_DIR%"
    if %ERRORLEVEL% neq 0 (
        echo ERROR: Failed to create virtual environment
        pause
        exit /b 1
    )
    echo   Virtual environment created
) else (
    echo   Virtual environment already exists
)

:: --- Install dependencies ---
echo [4/5] Installing Python dependencies...
call "%VENV_DIR%\Scripts\activate.bat
pip install -r "%~dp0py\requirements.txt" --quiet
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)
echo   Dependencies installed

:: --- Install Obsidian plugin ---
echo [5/5] Setting up Obsidian plugin...
set PLUGIN_SRC=%~dp0obsidian-plugin
set OBS_PLUGINS=%OBSIDIAN_PLUGIN_DIR%

:: Try to auto-detect Obsidian plugins directory
if "%OBS_PLUGINS%"=="" (
    if exist "%USERPROFILE%\.obsidian\plugins" (
        echo   Found Obsidian vault at: %USERPROFILE%
        set /p OBS_VAULT="Enter Obsidian vault path (e.g. D:\my-vault): "
        set "OBS_PLUGINS=!OBS_VAULT!\.obsidian\plugins"
    )
)

if not "%OBS_PLUGINS%"=="" (
    set "TARGET_DIR=%OBS_PLUGINS%\supertonic-tts"
    if not exist "!TARGET_DIR!" mkdir "!TARGET_DIR!"
    copy /Y "%PLUGIN_SRC%\main.js" "!TARGET_DIR!\" >nul
    copy /Y "%PLUGIN_SRC%\manifest.json" "!TARGET_DIR!\" >nul
    copy /Y "%PLUGIN_SRC%\styles.css" "!TARGET_DIR!\" >nul
    echo   Obsidian plugin installed to: !TARGET_DIR!
) else (
    echo   OBSIDIAN_PLUGIN_DIR not set, skipping plugin install
    echo   Manually copy obsidian-plugin\*.js obsidian-plugin\*.json obsidian-plugin\*.css to .obsidian\plugins\supertonic-tts\
)

:: --- Done ---
echo.
echo ============================================
echo   Installation Complete!
echo ============================================
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
