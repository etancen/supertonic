@echo off
setlocal enabledelayedexpansion
title Obsidian Plugin Deployer

set SCRIPT_DIR=%~dp0
set PLUGIN_SRC=%SCRIPT_DIR%obsidian-plugin
set OBS_PLUGINS=%OBSIDIANPLUGINS%

if "%OBS_PLUGINS%"=="" (
    echo OBSIDIANPLUGINS environment variable not set.
    set /p OBS_VAULT="Enter Obsidian vault path: "
    for %%p in ("!OBS_VAULT!") do set "OBS_PLUGINS=%%~dpfxp\.obsidian\plugins"
)

if not exist "%OBS_PLUGINS%" (
    echo ERROR: Plugins directory not found: %OBS_PLUGINS%
    pause
    exit /b 1
)

set "TARGET_DIR=%OBS_PLUGINS%\supertonic-tts"
if not exist "!TARGET_DIR!" mkdir "!TARGET_DIR!"
copy /Y "%PLUGIN_SRC%\main.js" "!TARGET_DIR!\" >nul
copy /Y "%PLUGIN_SRC%\manifest.json" "!TARGET_DIR!\" >nul
copy /Y "%PLUGIN_SRC%\styles.css" "!TARGET_DIR!\" >nul

echo Plugin deployed to: !TARGET_DIR!
echo Restart Obsidian or go to Settings ^> Community Plugins ^> Refresh
pause
