#!/usr/bin/env bash
# Waits until the GPU actually has room (i.e. until the live splizard session frees VRAM on
# its own -- this script never stops it itself, no systemctl/kill of the production service),
# then runs the sampling sweep unattended and pings ntfy when it's done or if it fails.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$DIR/wait_and_run.log"
NTFY="https://ntfy.memoryio.com/claude"
VRAM_TOTAL_FILE=/sys/class/drm/card1/device/mem_info_vram_total
VRAM_USED_FILE=/sys/class/drm/card1/device/mem_info_vram_used
NEED_FREE_GB=10   # sampling-sweep legs load a second full model copy; be generous

log() { echo "$(date '+%F %T') $*" | tee -a "$LOG"; }

free_gb() {
  local total used
  total=$(cat "$VRAM_TOTAL_FILE"); used=$(cat "$VRAM_USED_FILE")
  awk -v t="$total" -v u="$used" 'BEGIN{printf "%.2f", (t-u)/1073741824}'
}

log "waiting for >=${NEED_FREE_GB}GB free VRAM before starting sampling sweep (not touching the live splizard service)"
while true; do
  f=$(free_gb)
  if awk -v f="$f" -v need="$NEED_FREE_GB" 'BEGIN{exit !(f>=need)}'; then
    log "GPU free: ${f}GB available, starting sweep"
    break
  fi
  sleep 120
done

curl -sf -H "X-Tags: information_source" -d "Sampling sweep starting now -- GPU freed up (${f}GB avail)." "$NTFY" >/dev/null 2>&1 || true

if bash "$DIR/run_sweep.sh" >> "$LOG" 2>&1; then
  log "sweep finished OK"
  curl -sf -H "X-Tags: information_source" -d "Sampling sweep (tinygrad temp-only + llama.cpp temp/top_p/top_k) finished. Results: $DIR/results.csv" "$NTFY" >/dev/null 2>&1 || true
else
  log "sweep FAILED, see $LOG"
  curl -sf -H "X-Tags: rotating_light" -H "X-Priority: high" -d "Sampling sweep failed -- check $LOG" "$NTFY" >/dev/null 2>&1 || true
fi
