import argparse
import io
import os
from contextlib import asynccontextmanager

import soundfile as sf
from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import Response
from pydantic import BaseModel, Field

from helper import (
    AVAILABLE_LANGS,
    load_text_to_speech,
    load_voice_style,
)

VOICE_NAMES = ["M1", "M2", "M3", "M4", "M5", "F1", "F2", "F3", "F4", "F5"]

tts_engine = None
voice_cache = {}
DEFAULT_ONNX_DIR = "assets/onnx"
DEFAULT_VOICE_DIR = "assets/voice_styles"

use_gpu = False


@asynccontextmanager
async def lifespan(app: FastAPI):
    global tts_engine, use_gpu
    onnx_dir = os.environ.get("SUPERTONIC_ONNX_DIR", DEFAULT_ONNX_DIR)
    gpu_env = os.environ.get("SUPERTONIC_USE_GPU", "").lower()
    use_gpu = gpu_env in ("1", "true", "yes")
    tts_engine = load_text_to_speech(onnx_dir, use_gpu)
    yield
    tts_engine = None


app = FastAPI(
    title="SuperTonic TTS API",
    description="On-device Text-to-Speech API powered by SuperTonic",
    version="1.0.0",
    lifespan=lifespan,
)


def get_voice_style(voice: str):
    global voice_cache
    if voice not in voice_cache:
        voice_dir = os.environ.get("SUPERTONIC_VOICE_DIR", DEFAULT_VOICE_DIR)
        voice_path = os.path.join(voice_dir, f"{voice}.json")
        if not os.path.exists(voice_path):
            raise HTTPException(
                status_code=400,
                detail=f"Voice style not found: {voice}. Available: {VOICE_NAMES}",
            )
        voice_cache[voice] = load_voice_style([voice_path])
    return voice_cache[voice]


class TTSRequest(BaseModel):
    text: str = Field(..., description="Text to synthesize", min_length=1, max_length=5000)
    voice: str = Field("M1", description="Voice style name", pattern="^[MF][1-5]$")
    lang: str = Field("en", description="Language code")
    speed: float = Field(1.05, description="Speech speed (0.5-2.0)", ge=0.5, le=2.0)
    total_step: int = Field(5, description="Denoising steps (3-10)", ge=3, le=10)
    response_format: str = Field("wav", description="Audio format")


@app.post("/tts", summary="Text-to-Speech synthesis")
async def synthesize(request: TTSRequest):
    if request.lang not in AVAILABLE_LANGS:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported language: {request.lang}. Available: {AVAILABLE_LANGS}",
        )

    style = get_voice_style(request.voice)
    wav, duration = tts_engine(
        request.text,
        request.lang,
        style,
        request.total_step,
        request.speed,
    )

    wav_trimmed = wav[0, : int(tts_engine.sample_rate * duration.item())]
    buf = io.BytesIO()
    sf.write(buf, wav_trimmed, tts_engine.sample_rate, format="WAV")
    buf.seek(0)

    return Response(content=buf.read(), media_type="audio/wav")


@app.get("/voices", summary="List available voice styles")
async def list_voices():
    return {"voices": VOICE_NAMES}


@app.get("/languages", summary="List available languages")
async def list_languages():
    return {"languages": AVAILABLE_LANGS}


@app.get("/health", summary="Health check")
async def health():
    return {"status": "ok", "engine_loaded": tts_engine is not None}


if __name__ == "__main__":
    import uvicorn

    parser = argparse.ArgumentParser(description="SuperTonic TTS API Server")
    parser.add_argument("--host", type=str, default="0.0.0.0", help="Bind address")
    parser.add_argument("--port", type=int, default=8765, help="Listen port")
    parser.add_argument("--onnx-dir", type=str, default=DEFAULT_ONNX_DIR, help="ONNX models directory")
    parser.add_argument("--voice-dir", type=str, default=DEFAULT_VOICE_DIR, help="Voice styles directory")
    parser.add_argument("--use-gpu", action="store_true", help="Use CUDA GPU for inference")
    args = parser.parse_args()

    os.environ["SUPERTONIC_ONNX_DIR"] = args.onnx_dir
    os.environ["SUPERTONIC_VOICE_DIR"] = args.voice_dir
    if args.use_gpu:
        os.environ["SUPERTONIC_USE_GPU"] = "1"

    uvicorn.run(app, host=args.host, port=args.port)
