# SuperTonic TTS Obsidian Plugin Deployer (PowerShell)
$ErrorActionPreference = "Stop"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PLUGIN_SRC = Join-Path $SCRIPT_DIR "obsidian-plugin"
$OBS_PLUGINS = $env:OBSIDIANPLUGINS

if (-not $OBS_PLUGINS) {
    Write-Host "OBSIDIANPLUGINS environment variable not set." -ForegroundColor Yellow
    $OBS_VAULT = Read-Host "Enter Obsidian vault path"
    $OBS_PLUGINS = Join-Path $OBS_VAULT ".obsidian\plugins"
}

if (-not (Test-Path $OBS_PLUGINS)) {
    Write-Host "ERROR: Plugins directory not found: $OBS_PLUGINS" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$TARGET_DIR = Join-Path $OBS_PLUGINS "supertonic-tts"
if (-not (Test-Path $TARGET_DIR)) { New-Item -ItemType Directory -Path $TARGET_DIR -Force | Out-Null }

Copy-Item -Path "$PLUGIN_SRC\main.js" -Destination "$TARGET_DIR\" -Force
Copy-Item -Path "$PLUGIN_SRC\manifest.json" -Destination "$TARGET_DIR\" -Force
Copy-Item -Path "$PLUGIN_SRC\styles.css" -Destination "$TARGET_DIR\" -Force

Write-Host "Plugin deployed to: $TARGET_DIR" -ForegroundColor Green
Write-Host "Restart Obsidian or go to Settings > Community Plugins > Refresh"
