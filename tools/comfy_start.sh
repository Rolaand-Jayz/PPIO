#!/usr/bin/env bash
# comfy_start.sh — preflight-gated ComfyUI launcher for the Playtime Protocol project.
# Launch arguments are EXACTLY the memory-safe policy documented in README.md
# (dynamic VRAM on by default + --reserve-vram 3). Nothing here changes those args.
# Do NOT add --gpu-only / --highvram / --disable-dynamic-vram / --disable-pinned-memory:
# each is a documented freeze/thrash failure mode on this machine (see README.md).
# Rollback path: launch the README command by hand and stop using this wrapper.
set -eu

PROJECT=/mnt/workdrive/playtime-protocol-godot-comfy-blender
INSTALL="/home/rolaandjayz/ComfyUI-Installs/ComfyUI (1) (1)"
LOG="$PROJECT/ops/comfy-server.log"

# 1) Never start a second server.
if ss -ltn 2>/dev/null | grep -q ':8188 '; then
  echo "REFUSED: something is already listening on 8188." >&2
  exit 2
fi

# 2) Resource gate — refuse to launch under pressure or while the user is active
#    unless GOOSE_FORCE_COMFY_START=1 is set explicitly (user authorization).
RES="$("$PROJECT/tools/resmon.sh")" || true
echo "$RES"
if echo "$RES" | grep -q '^VERDICT: PRESSURE'; then
  echo "REFUSED: resource pressure detected (see above)." >&2
  exit 1
fi
if echo "$RES" | grep -q '^user_state=ACTIVE' && [ "${GOOSE_FORCE_COMFY_START:-0}" != "1" ]; then
  echo "REFUSED: user appears active; starting ComfyUI requires explicit authorization" >&2
  echo "        (set GOOSE_FORCE_COMFY_START=1 to override, or retry when idle >= 5 min)." >&2
  exit 3
fi

# 3) Launch — identical arguments to README.md "Correct launch".
mkdir -p "$PROJECT/ops" "$PROJECT/assets/source"
echo "[comfy_start] launching server, log: $LOG  $(date -Is)"
cd "$INSTALL"
exec "$INSTALL/standalone-env/bin/python" \
  "$INSTALL/ComfyUI/main.py" \
  --extra-model-paths-config "$PROJECT/comfy_extra_paths.yaml" \
  --output-directory "$PROJECT/assets/source" \
  --reserve-vram 3 \
  >>"$LOG" 2>&1
