#!/usr/bin/env bash
#
# usb-replug.sh -- software "re-plug" of the dock, no cable pulling.
#
# WHAT ACTUALLY WORKS (verified 2026-08-30 on the XPS 9315): a 15-second s2idle suspend.
#
#     sudo rtcwake -m mem -s 15
#
# s2idle powers the Type-C subsystem (TCSS/IOM) down far enough that resume renegotiates the
# connector from scratch -- electrically equivalent to re-seating the plug. After a firmware
# swap this is the ONLY software method that restored SuperSpeed (10 Gbit/s). Everything this
# script does below was tried first and is NOT sufficient on its own:
#   * root-port `disable` cycling (both halves of the connector)  -> re-attaches at 480 Mb/s
#   * FTDI chip reset while the port is held down                 -> 480 Mb/s
#   * UCSI PPM reset (ucsi_acpi driver rebind)                    -> real detach, still 480 Mb/s
#   * thunderbolt module unload / boltctl deauthorize             -> no enumeration at all
# Root cause: the TB4 port's SS-lane mux state survives all of those; only a fresh Type-C
# attach (physical or via suspend) re-programs it. The port cycling below is still useful for
# the mild case where the dock sits at 480 after a cold, bus-powered boot.
#
# Why you need this: after a firmware flash the ASM2464PD is reset over the FTDI debug lines
# rather than by a real disconnect, so the host never sees an unplug. The device re-attaches on
# the USB-2 lines only and its SuperSpeed companion port stays "not attached" -- you end up at
# 480 Mb/s instead of 10 Gbit/s. Toggling the root port's `disable` attribute drops VBUS, which
# the device sees as a genuine disconnect, and SuperSpeed retrains on re-enable.
#
# A USB-C connector shows up as two root ports sharing one `location` value: the USB-2 one
# (usb3-portN here) and the SuperSpeed one (usb2-portN / usb4-portN). Both must be cycled, and
# they are matched by `location` so this keeps working if port numbering changes -- and so it
# never touches a different physical port (e.g. a hub you have plugged in elsewhere).
#
# Needs root (the `disable` attribute is root-only).
#
# Usage:  sudo ./usb-replug.sh            # find the dock automatically
#         sudo ./usb-replug.sh 3-6        # or name its device path
set -euo pipefail

IDS="3801:0001 add1:0001 174c:2463 174c:2464 2065:2463"

find_dock() {
  for d in /sys/bus/usb/devices/[0-9]*-[0-9]*; do
    case "$(basename "$d")" in *:*) continue;; esac
    local v p
    v=$(cat "$d/idVendor" 2>/dev/null) || continue
    p=$(cat "$d/idProduct" 2>/dev/null) || continue
    for id in $IDS; do [ "$v:$p" = "$id" ] && { basename "$d"; return 0; }; done
  done
  return 1
}

DEV="${1:-$(find_dock || true)}"
[ -n "$DEV" ] || { echo "no dock found on USB (ids: $IDS)" >&2; exit 1; }
[ -d "/sys/bus/usb/devices/$DEV" ] || { echo "no such device: $DEV" >&2; exit 1; }

BUS="${DEV%%-*}"; PORT="${DEV#*-}"; PORT="${PORT%%.*}"
PORTDIR="/sys/bus/usb/devices/usb$BUS/$BUS-0:1.0/usb$BUS-port$PORT"
[ -d "$PORTDIR" ] || { echo "no port dir: $PORTDIR" >&2; exit 1; }
LOC=$(cat "$PORTDIR/location" 2>/dev/null || echo "")
echo "dock $DEV ($(cat /sys/bus/usb/devices/$DEV/product 2>/dev/null)) at $(cat /sys/bus/usb/devices/$DEV/speed)M, location $LOC"

# every root port sharing that location == the two halves of the same USB-C connector
PORTS=()
for p in /sys/bus/usb/devices/usb*/*-0:1.0/usb*-port*; do
  [ -f "$p/location" ] || continue
  [ "$(cat "$p/location")" = "$LOC" ] && PORTS+=("$p")
done
echo "cycling: ${PORTS[*]##*/}"

for p in "${PORTS[@]}"; do echo 1 > "$p/disable" 2>/dev/null || echo "  (cannot disable ${p##*/})"; done
sleep 2

# Dropping VBUS is not enough on its own: the dock is also powered from its DC input, so its
# SuperSpeed PHY never deasserts and it re-attaches on the USB-2 pairs only (480 Mb/s, and the
# SS companion port stays "not attached"). Resetting the chip WHILE the port is held down makes
# it boot into a down port and then see a real connect, which is what triggers SS training.
# Skip with NO_CHIP_RESET=1 if the FTDI debug cable is not attached.
if [ "${NO_CHIP_RESET:-0}" != "1" ] && lsusb -d 0403:6015 >/dev/null 2>&1; then
  echo "resetting the controller while the port is down (FTDI)"
  PYTHONPATH=/home/jacob/z/tinygrad timeout 60 /home/jacob/z/tinygrad/.venv/bin/python3 \
    /home/jacob/z/tinygrad/extra/usbgpu/debug.py -r -n >/dev/null 2>&1 || echo "  (chip reset failed, continuing)"
  sleep 2
fi

for p in "${PORTS[@]}"; do echo 0 > "$p/disable" 2>/dev/null || true; done

for _ in $(seq 1 20); do
  sleep 1
  d=$(find_dock || true)
  [ -n "$d" ] && { echo "back as $d at $(cat /sys/bus/usb/devices/$d/speed)M -- $(cat /sys/bus/usb/devices/$d/product 2>/dev/null)"; exit 0; }
done
echo "dock did not come back within 20s -- check the PSU switch, then try again" >&2
exit 1
