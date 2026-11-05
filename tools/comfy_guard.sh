#!/usr/bin/env bash
# comfy_guard.sh — lightweight in-job resource guard for ComfyUI (Playtime Protocol).
# Runs alongside ONE active generation job. NOT a daemon: start it per job, it exits
# when the job finishes. Poll default 15 s; each sample is ~2 file reads + one tiny
# HTTP call; kernel-journal GPU-error check runs once per minute, bounded to ~2 min.
#
# On pressure breach: POST /interrupt (ComfyUI's graceful current-job cancel), log to
# ops/guard-events.log, exit 2. It never restarts anything and never queues work.
#
# Usage: tools/comfy_guard.sh [--interval SEC] [--max-minutes N] [--wait-for-job SEC] [--once]
# Exit: 0 job finished/none within wait window · 2 pressure breach (job interrupted)
#       3 timeout · 4 server unreachable
set -u
BASE="http://127.0.0.1:8188"
PROJECT="$(cd "$(dirname "$0")/.." && pwd)"
EVENTLOG="$PROJECT/ops/guard-events.log"
INTERVAL=15; MAX_MIN=45; WAIT_JOB=120; ONCE=0
while [ $# -gt 0 ]; do case "$1" in
  --interval) INTERVAL="$2"; shift 2;;
  --max-minutes) MAX_MIN="$2"; shift 2;;
  --wait-for-job) WAIT_JOB="$2"; shift 2;;
  --once) ONCE=1; shift;;
  *) echo "unknown arg $1" >&2; exit 4;;
esac; done

CPU_CARD=""
for c in /sys/class/drm/card[0-9]/device; do
  grep -q DRIVER=amdgpu "$c/uevent" 2>/dev/null || continue
  vt=$(cat "$c/mem_info_vram_total" 2>/dev/null) || continue
  [ "${vt:-0}" -gt 4000000000 ] && CPU_CARD="$c" && break
done
sample() {  # one lightweight sample; echoes "key=value key=value ..."
  local avail swap vused vtotal gtt busy psisome
  avail=$(awk '/^MemAvailable/{print int($2/1024)}' /proc/meminfo)
  swap=$(awk '/^SwapTotal/{t=$2} /^SwapFree/{f=$2} END{print int((t-f)/1024)}' /proc/meminfo)
  psisome=$(awk '/^some/{gsub("avg60=","",$3); print int($3)}' /proc/pressure/memory 2>/dev/null || echo 0)
  if [ -n "$CPU_CARD" ]; then
    vused=$(( $(cat "$CPU_CARD/mem_info_vram_used") / 1048576 ))
    vtotal=$(( $(cat "$CPU_CARD/mem_info_vram_total") / 1048576 ))
    gtt=$(( $(cat "$CPU_CARD/mem_info_gtt_used") / 1048576 ))
    busy=$(cat "$CPU_CARD/gpu_busy_percent" 2>/dev/null || echo '?')
  else vused=0; vtotal=0; gtt=0; busy='?'; fi
  echo "avail_mb=$avail swap_mb=$swap psi_some60=$psisome vram_used_mb=$vused vram_free_mb=$((vtotal-vused)) gtt_mb=$gtt gpu_busy=$busy"
}
queue_counts() {  # prints "running N pending M" (single tiny GET)
  curl -s --max-time 4 "$BASE/queue" | python3 -c '
import json,sys
try:
    q=json.load(sys.stdin); print("running",len(q.get("queue_running",[])),"pending",len(q.get("queue_pending",[])))
except Exception: print("running 0 pending 0")' 2>/dev/null
}
gpu_errors_recent() {  # fatal-signature check, bounded window; REG_WAIT display warnings excluded
  journalctl -k --since '-90 sec' --no-pager 2>/dev/null | \
    grep -cE 'VM fault|page table fault|ring .*(timeout|hang)|GPU hang|gpu_recovery|amdgpu.*(reset|fatal)' || true
}
cancel_job() {
  local reason="$1"
  mkdir -p "$PROJECT/ops"
  printf '%s BREACH %s -> POST /interrupt\n' "$(date -Is)" "$reason" >> "$EVENTLOG"
  curl -s --max-time 4 -X POST "$BASE/interrupt" >/dev/null 2>&1 || true
  echo "GUARD: breach ($reason) — graceful /interrupt sent; DO NOT queue new work until resmon passes."
}
trap 'echo "GUARD: stopped by signal"; exit 0' INT TERM

# wait for a job to appear (server up within window)
seen_job=0; waited=0
while [ $seen_job -eq 0 ] && [ $waited -lt "$WAIT_JOB" ]; do
  read -r _ running _ pending <<< "$(queue_counts)"
  if [ "${running:-0}" -gt 0 ] || [ "${pending:-0}" -gt 0 ]; then seen_job=1; break; fi
  if ! curl -s --max-time 3 "$BASE/system_stats" >/dev/null 2>&1; then
    [ $waited -ge 5 ] && { echo "GUARD: server unreachable on $BASE"; exit 4; }
  fi
  sleep 3; waited=$((waited+3))
done
[ $seen_job -eq 0 ] && { echo "GUARD: no active job within ${WAIT_JOB}s; nothing to guard"; exit 0; }
echo "GUARD: job active — monitoring every ${INTERVAL}s (max ${MAX_MIN}min)"

start=$(date +%s); last_swap=""; swap_grow_streak=0; n=0; down=0
while :; do
  s=$(sample); echo "GUARD-SAMPLE $s"
  avail=$(echo "$s" | grep -o 'avail_mb=[0-9]*' | cut -d= -f2)
  swap=$(echo "$s"  | grep -o 'swap_mb=[0-9]*'  | cut -d= -f2)
  psi=$(echo "$s"   | grep -o 'psi_some60=[0-9]*' | cut -d= -f2)
  vfree=$(echo "$s" | grep -o 'vram_free_mb=[0-9]*' | cut -d= -f2)
  # swap trend: sustained growth = memory pressure (GPU util is deliberately ignored)
  if [ -n "$last_swap" ] && [ "$swap" -ge $((last_swap + 256)) ]; then
    swap_grow_streak=$((swap_grow_streak+1))
  else swap_grow_streak=0; fi
  last_swap=$swap
  if [ "$avail" -lt 6000 ]; then cancel_job "ram_available ${avail}MB < 6000MB"; exit 2; fi
  if [ "$vfree" -lt 2000 ]; then cancel_job "free_vram ${vfree}MB < 2000MB"; exit 2; fi
  if [ "${psi:-0}" -ge 50 ]; then cancel_job "memory PSI some avg60=${psi}"; exit 2; fi
  if [ "$swap_grow_streak" -ge 2 ]; then cancel_job "swap grew >=256MB for ${swap_grow_streak} consecutive samples"; exit 2; fi
  n=$((n+1))
  if [ $((n % 4)) -eq 0 ]; then  # ~1x/minute: kernel GPU fault check
    errs=$(gpu_errors_recent)
    if [ "${errs:-0}" -ge 1 ]; then cancel_job "$errs kernel GPU fault signature(s) in last 90s"; exit 2; fi
  fi
  [ $ONCE -eq 1 ] && { echo "GUARD: --once complete (sample OK, no breach)"; exit 0; }
  if ! curl -s --max-time 3 "$BASE/system_stats" >/dev/null 2>&1; then down=$((down+1)); else down=0; fi
  if [ "$down" -ge 2 ]; then
    printf '%s EVENT server-unreachable-during-job (nothing to cancel)\n' "$(date -Is)" >> "$EVENTLOG"
    echo "GUARD: server vanished mid-job; incident logged"; exit 4
  fi
  read -r _ running _ pending <<< "$(queue_counts)"
  if [ "${running:-0}" -eq 0 ] && [ "${pending:-0}" -eq 0 ]; then
    echo "GUARD: job finished cleanly"; exit 0
  fi
  if [ $(( $(date +%s) - start )) -ge $((MAX_MIN * 60)) ]; then
    echo "GUARD: max runtime ${MAX_MIN}min reached (job still active)"; exit 3
  fi
  sleep "$INTERVAL"
done
