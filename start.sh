#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"

if [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo "Virtual environment not found. Run ./install.sh first."
    exit 1
fi

source "$VENV_DIR/bin/activate"

USE_GPU=""
AUTO_GPU=0
for arg in "$@"; do
    case "$arg" in
        --gpu|-g) USE_GPU="--use-gpu" ;;
        --no-gpu) AUTO_GPU=0 ;;
    esac
done

# Auto-detect GPU if not explicitly set
if [ -z "$USE_GPU" ] && [ "$AUTO_GPU" != "0" ]; then
    OS="$(uname -s)"
    if [ "$OS" = "Windows" ] || [ "$OS" = "MINGW"* ]; then
        python -c "import onnxruntime; p=onnxruntime.get_available_providers(); exit(0 if 'DmlExecutionProvider' in p else 1)" 2>/dev/null && USE_GPU="--use-gpu"
    elif command -v nvidia-smi &>/dev/null; then
        python -c "import onnxruntime; p=onnxruntime.get_available_providers(); exit(0 if 'CUDAExecutionProvider' in p else 1)" 2>/dev/null && USE_GPU="--use-gpu"
    fi
fi

echo "============================================"
echo "  SuperTonic TTS API Server"
echo "============================================"
echo "  Assets: $SCRIPT_DIR/assets"
if [ -n "$USE_GPU" ]; then
    echo "  GPU:    auto-detected"
else
    echo "  GPU:    no"
fi
echo "  URL:    http://localhost:8765"
echo "  Log:    $SCRIPT_DIR/logs/server.log"
echo "============================================"
echo ""
echo "Press Ctrl+C to stop"
echo ""

mkdir -p "$SCRIPT_DIR/logs"

python "$SCRIPT_DIR/py/api_server.py" \
    --onnx-dir "$SCRIPT_DIR/assets/onnx" \
    --voice-dir "$SCRIPT_DIR/assets/voice_styles" \
    --log-file "$SCRIPT_DIR/logs/server.log" \
    $USE_GPU
