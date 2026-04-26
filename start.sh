#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"

if [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo "Virtual environment not found. Run ./install.sh first."
    exit 1
fi

source "$VENV_DIR/bin/activate"

USE_GPU=""
for arg in "$@"; do
    case "$arg" in
        --gpu|-g) USE_GPU="--use-gpu" ;;
    esac
done

echo "============================================"
echo "  SuperTonic TTS API Server"
echo "============================================"
echo "  Assets: $SCRIPT_DIR/assets"
echo "  GPU:    ${USE_GPU:-no}"
echo "  URL:    http://localhost:8765"
echo "============================================"
echo ""
echo "Press Ctrl+C to stop"
echo ""

python "$SCRIPT_DIR/py/api_server.py" \
    --onnx-dir "$SCRIPT_DIR/assets/onnx" \
    --voice-dir "$SCRIPT_DIR/assets/voice_styles" \
    $USE_GPU
