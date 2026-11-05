#!/usr/bin/env bash
# resmon.sh — on-demand resource snapshot for gating ComfyUI work.
# Run explicitly when needed; NOT a daemon, no sampling loop, negligible cost.
# Exit 0 = within targets. Exit 1 = pressure — do not queue/start GPU work.
set -u

# --- memory (MB) ---
AVAIL=$(awk '/^MemAvailable/{print int($2/1024)}' /proc/meminfo)
SWAP_USED=$(awk '/^SwapTotal/{t=$2} /^SwapFree/{f=$2} END{print int((t-f)/1024)}' /proc/meminfo)
MEM_SOME=$(awk '/^some/{gsub("avg60=","",$3); print int($3)}' /proc/pressure/memory 2>/dev/null || echo 0)
MEM_FULL=$(awk '/^full/{gsub("avg60=","",$3); print int($3)}' /proc/pressure/memory 2>/dev/null || echo 0)

# --- GPU: first amdgpu card with >4GB vram (the dGPU) ---
CARD=""
for c in /sys/class/drm/card[0-9]/device; do
  grep -q DRIVER=amdgpu "$c/uevent" 2>/dev/null || continue
  vt=$(cat "$c/mem_info_vram_total" 2>/dev/null) || continue
  if [ "${vt:-0}" -gt 4000000000 ]; then CARD="$c"; break; fi
done
if [ -n "$CARD" ]; then
  VRAM_USED_MB=$(( $(cat "$CARD/mem_info_vram_used") / 1048576 ))
  VRAM_TOTAL_MB=$(( $(cat "$CARD/mem_info_vram_total") / 1048576 ))
  GTT_USED_MB=$(( $(cat "$CARD/mem_info_gtt_used") / 1048576 ))
  BUSY=$(cat "$CARD/gpu_busy_percent" 2>/dev/null || echo '?')
  VRAM_FREE_MB=$(( VRAM_TOTAL_MB - VRAM_USED_MB ))
else
  VRAM_USED_MB=0; VRAM_TOTAL_MB=0; GTT_USED_MB=0; VRAM_FREE_MB=0; BUSY='?'
fi

# --- idle detection (KDE Wayland): session IdleHint, no input hooks ---
IDLE=no
for s in $(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}'); do
  if [ "$(loginctl show-session "$s" -p IdleHint 2>/dev/null | cut -d= -f2)" = "yes" ]; then IDLE=yes; fi
done
if [ "$IDLE" = no ]; then
  # IdleHint can be unreliable on some setups; treat as ACTIVE per policy.
  USER_STATE="ACTIVE (assume active unless IdleHint=yes)"
else
  USER_STATE="IDLE (IdleHint=yes)"
fi

# --- comfy server ---
COMFY_RUNNING=$(ss -ltn 2>/dev/null | grep -c ':8188 ' || true)

echo "user_state=$USER_STATE"
echo "ram_available_mb=$AVAIL swap_used_mb=$SWAP_USED psi_mem_some60=$MEM_SOME psi_mem_full60=$MEM_FULL"
echo "vram_free_mb=$VRAM_FREE_MB vram_used_mb=$VRAM_USED_MB vram_total_mb=$VRAM_TOTAL_MB gtt_used_mb=$GTT_USED_MB gpu_busy=$BUSY"
echo "comfy_on_8188=$COMFY_RUNNING"

STATUS=0
# Abort thresholds (hard floor): RAM < 6 GB, free VRAM < 2 GB, sustained swap, mem PSI.
if [ "$AVAIL" -lt 6000 ];  then echo "ABORT: RAM available < 6000 MB"; STATUS=1; fi
if [ "$VRAM_FREE_MB" -gt 0 ] && [ "$VRAM_FREE_MB" -lt 2000 ]; then echo "ABORT: free VRAM < 2000 MB"; STATUS=1; fi
if [ "${MEM_SOME:-0}" -ge 50 ]; then echo "ABORT: memory PSI some avg60 >= 50"; STATUS=1; fi
# Target check (soft, informational): active targets RAM>=10GB, VRAM>=4GB free.
if [ "$IDLE" = no ]; then
  [ "$AVAIL" -lt 10000 ] && echo "SOFT: below active-use RAM target (10000 MB)"
  [ "$VRAM_FREE_MB" -gt 0 ] && [ "$VRAM_FREE_MB" -lt 4000 ] && echo "SOFT: below active-use free-VRAM target (4000 MB)"
fi
[ "$COMFY_RUNNING" -ne 0 ] && echo "INFO: a ComfyUI server is already listening on 8188 — never start a second one"

[ "$STATUS" -eq 0 ] && echo "VERDICT: OK — resources within abort thresholds" || echo "VERDICT: PRESSURE — stop queuing new GPU work"
exit $STATUS
