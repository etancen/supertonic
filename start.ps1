# SuperTonic TTS API Server (PowerShell)
$ErrorActionPreference = "Stop"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ENV_NAME = "supertonic"

# --- Check conda environment ---
$envList = conda env list 2>$null
if ($LASTEXITCODE -ne 0 -or $envList -notmatch $ENV_NAME) {
    Write-Host "Conda environment '$ENV_NAME' not found. Run install.bat first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "Conda environment '$ENV_NAME' found. Starting API server..."

# --- Parse arguments ---
$UseGPU = $false
$NoGPU = $false
foreach ($arg in $args) {
    if ($arg -eq "--gpu" -or $arg -eq "-g") { $UseGPU = $true }
    if ($arg -eq "--no-gpu") { $NoGPU = $true }
}

# --- Auto-detect GPU ---
if (-not $UseGPU -and -not $NoGPU) {
    $result = conda run -n $ENV_NAME python -c "import onnxruntime; p=onnxruntime.get_available_providers(); exit(0 if 'CUDAExecutionProvider' in p else 1)" 2>$null
    if ($LASTEXITCODE -eq 0) { $UseGPU = $true }
}

# --- Banner ---
Write-Host "============================================"
Write-Host "  SuperTonic TTS API Server"
Write-Host "============================================"
Write-Host "  Assets: $SCRIPT_DIR\assets"
if ($UseGPU) { Write-Host "  GPU:    auto-detected (CUDA)" } else { Write-Host "  GPU:    no (CPU mode)" }
Write-Host "  URL:    http://localhost:8765"
Write-Host "  Docs:   http://localhost:8765/docs"
Write-Host "  Log:    $SCRIPT_DIR\logs\server.log"
Write-Host "============================================"
Write-Host ""
Write-Host "Press Ctrl+C to stop"
Write-Host ""

# --- Ensure log directory ---
$logDir = Join-Path $SCRIPT_DIR "logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

# --- Build arguments ---
$pyArgs = @(
    "$SCRIPT_DIR\py\api_server.py",
    "--onnx-dir", "$SCRIPT_DIR\assets\onnx",
    "--voice-dir", "$SCRIPT_DIR\assets\voice_styles",
    "--log-file", "$SCRIPT_DIR\logs\server.log"
)
if ($UseGPU) { $pyArgs += "--use-gpu" }

# --- Start API server ---
conda run -n $ENV_NAME python $pyArgs
