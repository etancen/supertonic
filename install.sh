#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"

echo "============================================"
echo "  SuperTonic TTS — One-Click Installer"
echo "============================================"
echo ""

# --- Check ONNX models ---
echo "[1/5] Checking ONNX models..."
ONNX_DIR="$SCRIPT_DIR/assets/onnx"
if [ ! -f "$ONNX_DIR/duration_predictor.onnx" ]; then
    echo ""
    echo "  WARNING: ONNX models not found!"
    echo "  Download from: https://huggingface.co/SuperTone/supertonic"
    echo "  Place .onnx files in: $ONNX_DIR/"
    echo ""
    echo "  Required files:"
    echo "    duration_predictor.onnx"
    echo "    text_encoder.onnx"
    echo "    vector_estimator.onnx"
    echo "    vocoder.onnx"
    echo ""
    read -rp "  Continue without models? (y/N): " CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        exit 1
    fi
else
    echo "  Models found"
fi

# --- Check Python ---
echo "[2/5] Checking Python..."
if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
    echo "ERROR: Python not found. Install Python 3.10+"
    exit 1
fi
PYTHON=$(command -v python3 || command -v python)
echo "  Found $($PYTHON --version 2>&1)"

# --- Create venv ---
echo "[3/5] Creating virtual environment..."
if [ ! -d "$VENV_DIR" ]; then
    $PYTHON -m venv "$VENV_DIR"
    echo "  Virtual environment created"
else
    echo "  Virtual environment already exists"
fi

# --- Install dependencies ---
echo "[4/5] Installing Python dependencies..."
source "$VENV_DIR/bin/activate"
pip install -r "$SCRIPT_DIR/py/requirements.txt" --quiet
echo "  Dependencies installed"

# --- Install Obsidian plugin ---
echo "[5/5] Setting up Obsidian plugin..."
PLUGIN_SRC="$SCRIPT_DIR/obsidian-plugin"
OBS_PLUGINS="${OBSIDIAN_PLUGIN_DIR:-}"

if [ -z "$OBS_PLUGINS" ]; then
    # Try common paths
    for vault in "$HOME/Documents"/*; do
        if [ -d "$vault/.obsidian/plugins" ]; then
            echo "  Found vault: $vault"
        fi
    done
    echo ""
    read -rp "  Enter Obsidian vault path: " OBS_VAULT
    OBS_PLUGINS="$OBS_VAULT/.obsidian/plugins"
fi

if [ -n "$OBS_PLUGINS" ]; then
    TARGET_DIR="$OBS_PLUGINS/supertonic-tts"
    mkdir -p "$TARGET_DIR"
    cp "$PLUGIN_SRC/main.js" "$TARGET_DIR/"
    cp "$PLUGIN_SRC/manifest.json" "$TARGET_DIR/"
    cp "$PLUGIN_SRC/styles.css" "$TARGET_DIR/"
    echo "  Obsidian plugin installed to: $TARGET_DIR"
else
    echo "  Skipping plugin install (no OBSIDIAN_PLUGIN_DIR)"
    echo "  Manually copy obsidian-plugin/*.js, *.json, *.css to .obsidian/plugins/supertonic-tts/"
fi

# --- Done ---
echo ""
echo "============================================"
echo "  Installation Complete!"
echo "============================================"
echo ""
echo "  Usage:"
echo "    ./start.sh         - Launch API server"
echo "    ./start.sh --gpu   - Launch with GPU acceleration"
echo ""
echo "  In Obsidian:"
echo "    Settings > Community Plugins > Enable 'SuperTonic TTS'"
echo "    Settings > Hotkeys > Bind Ctrl+Shift+P to 'SuperTonic: Speak selected text'"
echo ""
