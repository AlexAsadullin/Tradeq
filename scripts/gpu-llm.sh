#!/usr/bin/env bash
# GPU for Tradeq on the AMD RX 580 (gfx803), without ROCm and without Docker: llama.cpp's ggml engine on Vulkan
# (Mesa RADV), the same route as whisper.cpp in the user's speech-to-text project, adapted to Tradeq's LLM side.
#
# What it gives: a local OpenAI-compatible LLM server (llama-server) on the GPU, which S7 llm-leakage-probe
# (backend "openai") and S8 agent-arena (provider "openai") already speak. It does NOT train PyTorch models:
# ggml runs inference; RL training stays on the CPU (robust-mm-rl docs/gpu.md).
#
# Usage: scripts/gpu-llm.sh check     driver, Vulkan, device access, build tools (changes nothing)
#        scripts/gpu-llm.sh build     clone llama.cpp at a pinned release and build it with Vulkan (~10 min)
#        scripts/gpu-llm.sh model     download the test model (Qwen2.5-0.5B-Instruct, Q4_K_M GGUF, ~0.4 GB)
#        scripts/gpu-llm.sh verify    prove the GPU is used, and compare GPU vs CPU tokens/s
# Then:  scripts/stack.sh start llm   serve it on http://127.0.0.1:8620/v1
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE="$ROOT/data/cache"
SRC="$CACHE/llama.cpp"
BIN="$SRC/build/bin"
TAG="b11869"            # llama.cpp release of 2026-10-24 (pinned; at least two weeks old when chosen)
MODEL_DIR="$CACHE/models"
MODEL_URL="https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf"
MODEL="$MODEL_DIR/qwen2.5-0.5b-instruct-q4_k_m.gguf"

ok() { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

check() {
  fail=0
  echo "== GPU driver (guide step 1)"
  local drv; drv="$(basename "$(readlink -f /sys/class/drm/card1/device/driver)")"
  [[ "$drv" == amdgpu ]] && ok "card1 driver: amdgpu" || bad "card1 driver: $drv (needs amdgpu)"
  echo "== Vulkan sees the GPU (step 3)"
  if vulkaninfo --summary 2>/dev/null | grep -q "RX 580"; then ok "$(vulkaninfo --summary 2>/dev/null | grep -m1 deviceName | sed 's/^ *//')"
  else bad "vulkaninfo does not list the RX 580 (only llvmpipe?)"; fi
  echo "== device access (step 4)"
  [[ -r /dev/dri/renderD128 && -w /dev/dri/renderD128 ]] && ok "/dev/dri/renderD128 readable and writable" \
    || bad "no access to /dev/dri/renderD128: sudo usermod -aG render,video \$USER, then log in again"
  echo "== build tools (step 2)"
  for t in g++ cmake glslc git curl; do command -v "$t" >/dev/null && ok "$t" || bad "$t missing"; done
  for p in libvulkan-dev spirv-headers; do dpkg -s "$p" >/dev/null 2>&1 && ok "$p" || bad "$p missing"; done
  [[ $fail -eq 0 ]] || { echo "fix: sudo apt install -y g++ cmake glslc libvulkan-dev spirv-headers mesa-vulkan-drivers vulkan-tools"; return 1; }
}

build() {
  check
  mkdir -p "$CACHE"
  if [[ ! -d "$SRC/.git" ]]; then
    git clone --depth 1 --branch "$TAG" https://github.com/ggml-org/llama.cpp "$SRC"
  fi
  echo "source: $(git -C "$SRC" describe --tags) $(git -C "$SRC" log -1 --format='%h %ci')"
  # BUILD_SHARED_LIBS=OFF: one self-contained binary (the guide's lesson about missing .so links).
  # GGML_NATIVE=ON: tuned for this Xeon; rebuild on another machine. nice 19: never slows the recorder or training.
  nice -n 19 cmake -S "$SRC" -B "$SRC/build" -DGGML_VULKAN=ON -DGGML_NATIVE=ON -DBUILD_SHARED_LIBS=OFF \
    -DLLAMA_CURL=OFF -DCMAKE_BUILD_TYPE=Release
  nice -n 19 cmake --build "$SRC/build" -j "$(( $(nproc) / 2 ))" --target llama-server llama-bench
  ldd "$BIN/llama-server" | grep -q libvulkan && echo "llama-server links libvulkan: ok" \
    || { echo "llama-server is not linked to Vulkan; the build fell back to CPU only" >&2; exit 1; }
}

model() {
  mkdir -p "$MODEL_DIR"
  if [[ ! -s "$MODEL" ]]; then
    curl -L --fail -o "$MODEL.part" "$MODEL_URL"
    mv -f "$MODEL.part" "$MODEL"
  fi
  ls -lh "$MODEL"
}

verify() {
  [[ -x "$BIN/llama-bench" ]] || { echo "run: scripts/gpu-llm.sh build" >&2; exit 1; }
  [[ -s "$MODEL" ]] || { echo "run: scripts/gpu-llm.sh model" >&2; exit 1; }
  echo "== devices llama.cpp sees (expect Vulkan0: AMD Radeon RX 580 2048SP)"
  "$BIN/llama-server" --list-devices 2>&1 | grep -iE "vulkan|available" || true
  echo "== GPU (all layers offloaded) vs CPU (-ngl 0): prompt 512 tokens, generate 128 tokens"
  "$BIN/llama-bench" -m "$MODEL" -ngl 99 -p 512 -n 128 -r 3 2>&1 | grep -E "\| (model|qwen)|pp512|tg128" | sed 's/^/GPU /'
  GGML_VK_VISIBLE_DEVICES="" "$BIN/llama-bench" -m "$MODEL" -ngl 0 -p 512 -n 128 -r 3 2>&1 \
    | grep -E "pp512|tg128" | sed 's/^/CPU /'
  echo "GPU busy now: $(cat /sys/class/drm/card1/device/gpu_busy_percent)% (run again during a bench to see it rise)"
}

case "${1:-check}" in
  check) check ;;
  build) build ;;
  model) model ;;
  verify) verify ;;
  *) sed -n '2,13p' "$0"; exit 64 ;;
esac
