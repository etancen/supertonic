@echo off
setlocal enabledelayedexpansion
title SuperTonic TTS Installer

set SCRIPT_DIR=%~dp0

echo ============================================
echo   SuperTonic TTS — One-Click Installer
echo ============================================
echo.

:: --- Check ONNX models ---
echo [1/5] Checking ONNX models...
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
echo [3/5] Setting up virtual environment...
set VENV_DIR=%SCRIPT_DIR%venv
if not exist "%VENV_DIR%\Scripts\python.exe" (
    echo   Creating virtual environment...
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
"%VENV_DIR%\Scripts\python.exe" -m pip install -r "%SCRIPT_DIR%py\requirements.txt"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)
echo   Dependencies installed

:: --- Install Obsidian plugin ---
echo [5/5] Setting up Obsidian plugin...
call "%SCRIPT_DIR%deploy-plugin.bat"

:: --- Done ---
echo.
echo ============================================
echo   Installation Complete!
echo ============================================
echo.
echo   Usage:
echo     start.bat          - Launch API server
echo     start.ps1          - Launch API server (PowerShell)
echo     start.bat --gpu    - Launch with GPU acceleration
echo     start.bat --no-gpu - Launch with CPU only
echo.
echo   In Obsidian:
echo     Settings ^> Community Plugins ^> Enable "SuperTonic TTS"
echo     Settings ^> Hotkeys ^> Bind Ctrl+Shift+P to "SuperTonic: Speak selected text"
echo.
pause
