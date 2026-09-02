#!/usr/bin/env bash
# rebuild -> e4 flash over main USB -> FTDI reset -> short repro. Fast iterate loop.
set -e
FW=/home/jacob/z/asm2464pd-firmware
VENV=$FW/.venv/bin/python
REPRO=/home/jacob/z/tinygrad/sweeps/chestnut-usb3-20260830/repro-f2-corruption

make -C "$FW/handmade" clean >/dev/null 2>&1
make -C "$FW/handmade" wrapped 2>&1 | grep -oE 'GIT_VERSION=.[0-9a-f]+-(CLEAN|DIRTY)' | head -1
cd "$FW/handmade" && PYTHONPATH=.:"$FW" "$VENV" e4_flash.py build/firmware_wrapped.bin 2>&1 | grep -E "PASS|FAIL|Done" | head -2
"$VENV" "$FW/ftdi_debug.py" -rn 2>&1 | grep -i "reset complete" || true
sleep 3
d=$(grep -l '3801\|add1' /sys/bus/usb/devices/*/idVendor 2>/dev/null | head -1)
echo "running: $(cat ${d%idVendor}product 2>/dev/null) @ $(cat ${d%idVendor}speed 2>/dev/null)"
DEV=USB+AMD USB_COPYIN_GUARD=0 RUNS=${RUNS:-15} MB=${MB:-64} "$REPRO/.venv/bin/python" "$REPRO/repro.py" 2>&1 | tail -20
echo "(no 'bad bytes' lines = FIXED)"
