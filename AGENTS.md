# Project: Offline AI Chat App (Android + iOS)

## Role
You are Codex, a senior mobile + ML systems engineer.
Design and implement a fully offline AI chat application.

## Core Goals
- ChatGPT-style UI
- Works 100% offline after model download
- Runs local GGUF models (Qwen / LFM2.5)
- Privacy-first: no external network calls during inference

## Platforms
- Android: [MIN_ANDROID_VERSION]
- iOS: [MIN_IOS_VERSION]
- Framework: [FLUTTER / REACT_NATIVE / NATIVE / DECIDE]

## Model & Inference
- Supported models:
  - Qwen 0.6B GGUF
  - LFM2.5 1.2B GGUF
- Inference backend: [LLAMA_CPP / MLC_LLM / DECIDE]
the download links are these 
https://huggingface.co/ggml-org/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q4_0.gguf
https://huggingface.co/LiquidAI/LFM2.5-1.2B-Thinking-GGUF/resolve/main/LFM2.5-1.2B-Thinking-Q4_0.gguf
use these links and they do not even require hf token so use these links to download 


## Offline Model Management
- Models are downloaded once and stored locally
- App must:
  - Verify checksum
  - Show download progress
  - Allow deleting/replacing models
- No cloud fallback

## UI / UX
- ChatGPT-like interface:
  - Message bubbles
  - Streaming token output
  - Markdown + code block rendering
- Controls:
  - Stop generation
  - Regenerate response
  - Clear conversation
- Dark mode by default

## Data Storage
- Conversations stored locally only
- No analytics
- No telemetry
- No accounts or login

## Architecture
- Clean architecture
- Separate layers:
  - UI
  - Inference engine
  - Model manager
  - Storage
- Designed for extensibility (future models/features)

## Constraints
- Must run offline
- Must be memory-safe
- Must handle low-memory gracefully
- Battery-aware inference

## Deliverables
- Android app
- iOS app
- Clear README
- Build & run instructions

if you make a new plan add it to plan.md and what all is already implemented and how is it implemented have it in done.md 
