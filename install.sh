#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_NAME="supertonic"

echo "============================================"
echo "  SuperTonic TTS — One-Click Installer"
echo "============================================"
echo ""

# --- Check ONNX models ---
echo "[1/4] Checking ONNX models..."
ONNX_DIR="$SCRIPT_DIR/assets/onnx"
if [ ! -f "$ONNX_DIR/duration_predictor.onnx" ]; then
    echo ""
    echo "  WARNING: ONNX models not found!"
    echo "  Download from: https://huggingface.co/Supertone/supertonic-2"
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

# --- Check Conda ---
echo "[2/4] Checking Conda..."
if ! command -v conda &>/dev/null; then
    echo "ERROR: Conda not found. Install Miniconda from https://docs.conda.io"
    exit 1
fi
echo "  Found $(conda --version 2>&1)"

# --- Check / Create conda env ---
echo "[3/4] Setting up conda environment..."
if ! conda env list | grep -q "^${ENV_NAME} "; then
    echo "  Creating conda environment '${ENV_NAME}'..."
    conda create -n "$ENV_NAME" python=3.10 -y
    echo "  Installing Python dependencies..."
    conda run -n "$ENV_NAME" pip install -r "$SCRIPT_DIR/py/requirements.txt"

    # Install platform-appropriate CUDA libraries
    OS="$(uname -s)"
    if [ "$OS" = "Linux" ]; then
        if command -v nvidia-smi &>/dev/null; then
            conda run -n "$ENV_NAME" pip install nvidia-cublas-cu12 nvidia-cudnn-cu12 nvidia-cuda-runtime-cu12 nvidia-cufft-cu12 nvidia-cusolver-cu12 nvidia-cusparse-cu12 nvidia-curand-cu12 nvidia-nvjitlink-cu12 2>/dev/null
            echo "  NVIDIA CUDA 12 libraries installed"
        fi
    fi
    echo "  Dependencies installed"
else
    echo "  Conda environment '${ENV_NAME}' already exists"
fi

# --- Install Obsidian plugin ---
echo "[4/4] Setting up Obsidian plugin..."
PLUGIN_SRC="$SCRIPT_DIR/obsidian-plugin"
OBS_PLUGINS="${OBSIDIANPLUGINS:-}"

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
    echo "  Skipping plugin install (no OBSIDIANPLUGINS)"
    echo "  Manually copy obsidian-plugin/*.js, *.json, *.css to .obsidian/plugins/supertonic-tts/"
fi

# --- Done ---
echo ""
echo "============================================"
echo "  Installation Complete!"
echo "============================================"
echo ""
echo "  Environment:  conda activate $ENV_NAME"
echo ""
echo "  Usage:"
echo "    ./start.sh         - Launch API server"
echo "    ./start.sh --gpu   - Launch with GPU acceleration"
echo ""
echo "  In Obsidian:"
echo "    Settings > Community Plugins > Enable 'SuperTonic TTS'"
echo "    Settings > Hotkeys > Bind Ctrl+Shift+P to 'SuperTonic: Speak selected text'"
echo ""
