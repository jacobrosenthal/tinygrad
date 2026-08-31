#!/usr/bin/env bash
#
# chestnut-fw.sh -- switch a tiny chestnut dock between the two firmwares.
#
#   tiny custom firmware  ->  USB 3.2 vendor-class device (3801:0001), DEV=USB+AMD:LLVM.
#                             The GPU never reaches the host PCI bus; tinygrad's userspace
#                             driver tunnels PCIe TLPs over USB. ~10 Gbit/s here, ~780 MB/s
#                             copyin, ~50 tok/s on Qwen3.8-27B. amdgpu/llama.cpp CANNOT use it.
#
#   stock ASMedia         ->  USB4/Thunderbolt PCIe tunnelling. The GPU is a real PCIe device
#                             under amdgpu, so llama.cpp / ROCm / Vulkan all work. On the XPS
#                             9315 the tunnel trains at PCIe 1.0 x1 (2 Gbit/s) but decode is
#                             not link-bound: llama-bench gave pp512 592 / tg128 32.7 tok/s.
#
# Usage:
#   ./chestnut-fw.sh status
#   ./chestnut-fw.sh backup [out.bin]
#   ./chestnut-fw.sh to-stock     # -> USB4/PCIe mode (llama.cpp, ROCm, Vulkan)
#   ./chestnut-fw.sh to-tiny      # -> USB3 mode (tinygrad DEV=USB+AMD)
#
# ---------------------------------------------------------------------------------------
# READ THIS FIRST -- the swap is NOT symmetric.
#
# Flashing works only while the dock presents a USB interface (this tool pokes the SPI flash
# via 0xE4/0xE5 XDATA vendor requests over libusb). That is true in tiny-custom mode and in
# stock USB 3.2 mode -- but NOT in stock USB4 mode, where the dock appears only as PCI bridges
# (lspci: ASMedia 1b21:2463) and `lsusb` shows nothing at all.
#
# So `to-stock` is easy, and `to-tiny` needs the dock forced out of USB4 first. Verified on a
# Dell XPS 9315: deauthorising the Thunderbolt device, unloading the `thunderbolt` module, and
# power-cycling the dock ALL fail to produce a USB3 fallback on a bare USB4 port. What works:
#
#   (a) put any plain USB 3.x hub/dongle between host and dock. USB4 cannot negotiate through
#       one, so the ASM2464PD falls back to USB 3.2 mass-storage mode and reappears on USB.
#   (b) connect the board's DEBUG USB port (onboard FT230X) and force bootloader mode:
#         pip install pyftdi && ./debug.py -b
#       You need BOTH cables for this: the FTDI only drives the RESET/BOOTLOADER GPIOs, the
#       main USB-C still carries the flash data.
#
# Other hard-won details:
#   * The ASM2464PD runs off USB VBUS *and* the dock's DC input. Switching the ATX PSU does NOT
#     reset it. Only unplugging the main USB-C cable reboots it into newly written firmware.
#   * Flash layout is [4B LE length][body][0xA5][checksum][crc32] at offset 0x100, for both
#     firmwares. The 0x000-0x0FF config area (VID/PID/strings) is preserved across a write.
#   * If the GPU is missing from lspci in stock mode, check the PSU switch is on ( | not O ).
#     The "cannot fit 0x100000" bridge-window message is a warning and appears even on
#     successful enumerations -- it is not the cause.
# ---------------------------------------------------------------------------------------
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
FW="$REPO/sweeps/chestnut-usb3-20260830/fw-backup"
PY="${PY:-$REPO/.venv/bin/python3}"
FLASHER="$FW/e4_flash_any.py"
TINY_IMG="$FW/restore-tiny-ed4e39b7-at0x100.bin"
STOCK_IMG="$FW/AS_USB4_231204_85_00_00.bin"

# every VID:PID the dock can present: tiny custom (comma VID), older tinygrad-patched stock,
# and stock ASMedia in USB 3.2 mode (several rebrands share the 2463/2464 PIDs)
KNOWN_IDS="3801:0001 add1:0001 174c:2463 174c:2464 2065:2463"

die() { echo "error: $*" >&2; exit 1; }

find_dev() {  # echoes "VID PID" of the first known id present on USB, or nothing
  for id in $KNOWN_IDS; do
    if lsusb -d "$id" >/dev/null 2>&1; then echo "0x${id%%:*} 0x${id##*:}"; return 0; fi
  done
  return 1
}

cmd_status() {
  echo "== USB =="
  if read -r vid pid < <(find_dev); then
    echo "  dock on USB as $vid:$pid -- flashable"
    lsusb | grep -iE "3801|add1|174c|2065" || true
  else
    echo "  no dock on USB"
  fi
  echo "== PCI =="
  if lspci -nn 2>/dev/null | grep -qi "1b21:2463"; then
    echo "  ASMedia bridges present -> stock firmware, USB4/PCIe mode"
    if lspci -nn 2>/dev/null | grep -qi "1002:744c"; then
      echo "  GPU: $(lspci -nn | grep -i 1002:744c | cut -d' ' -f2-)"
      for f in /sys/class/drm/card*/device/mem_info_vram_total; do
        [ -f "$f" ] && echo "  vram: $(( $(cat "$f")/1024/1024 )) MB"
      done
      echo "  -> llama.cpp / ROCm / Vulkan usable; tinygrad DEV=USB+AMD is NOT"
    else
      echo "  GPU NOT enumerated -- check the dock PSU switch is ON ( | not O ), then re-plug USB-C"
    fi
  else
    echo "  no ASMedia bridges on PCI"
  fi
  echo "== mode =="
  if lsusb 2>/dev/null | grep -qi "AS2462"; then
    echo "  BOOTLOADER (via DEBUG port) -- ready to flash: $0 to-tiny  |  $0 to-stock"
  elif lsusb -d 3801:0001 >/dev/null 2>&1 || lsusb -d add1:0001 >/dev/null 2>&1; then
    echo "  TINY CUSTOM (USB3) -- run tinygrad with DEV=USB+AMD:LLVM"
  elif lspci -nn 2>/dev/null | grep -qi "1b21:2463"; then
    echo "  STOCK (USB4/PCIe) -- to get back to tinygrad you need a USB3 hub or the DEBUG port"
  else
    echo "  dock not detected on USB or PCI (powered? cable in?)"
  fi
}

require_usb() {
  read -r vid pid < <(find_dev) || die "dock is not on the USB bus, so it cannot be flashed.
  If it is in stock USB4 mode (lspci shows ASMedia 1b21:2463), force it out of USB4 first:
    (a) put a plain USB 3.x hub between host and dock, or
    (b) connect the DEBUG USB port and run:  pip install pyftdi && $HERE/debug.py -b
  See the header of this script for why deauthorising/unloading thunderbolt does not work."
  echo "$vid $pid"
}

cmd_backup() {
  read -r vid pid < <(require_usb)
  local out="${1:-$FW/chestnut-backup-$(date +%Y%m%d-%H%M%S).bin}"
  echo "dumping 2 MB flash from $vid:$pid -> $out"
  FLASH_VID="$vid" FLASH_PID="$pid" PYTHONPATH="$REPO" "$PY" - "$out" <<'PYEOF'
import ctypes, sys, os
d = os.environ['FWDIR']; sys.path.insert(0, d)
from tinygrad.runtime.autogen import libusb
e4 = type(sys)('e4'); src = open(os.path.join(d, 'e4_flash_any.py')).read()
exec(compile(src.replace("if __name__ == '__main__':\n  main()", ""), 'e4', 'exec'), e4.__dict__)
ctx = ctypes.POINTER(libusb.libusb_context)(); libusb.libusb_init(ctypes.byref(ctx))
h = libusb.libusb_open_device_with_vid_pid(ctx, e4.VID, e4.PID); assert h, "device not found"
libusb.libusb_claim_interface(h, 0); e4.flash_init(h)
out = bytearray()
for a in range(0, 0x200000, 0x8000):
    out += e4.flash_read(h, a, 0x8000)
    print("\r  %6.1f%%" % (100*len(out)/0x200000), end="", flush=True)
print()
open(sys.argv[1], 'wb').write(bytes(out)); print("wrote", sys.argv[1], len(out), "bytes")
PYEOF
}

flash_img() {  # $1=image $2=human label
  local img="$1" label="$2"
  [ -f "$img" ] || die "missing image: $img"
  read -r vid pid < <(require_usb)
  echo "flashing $label"
  echo "  image:  $img ($(stat -c%s "$img") bytes)"
  echo "  device: $vid:$pid  (writes at 0x100; the 0x000-0x0FF config area is preserved)"
  FLASH_VID="$vid" FLASH_PID="$pid" PYTHONPATH="$REPO" "$PY" "$FLASHER" "$img" --no-reset
  cat <<EOF

done -- but the controller is still running the OLD firmware from RAM.
UNPLUG THE MAIN USB-C CABLE, wait ~5 s, plug it back in. Switching the dock's PSU is NOT
enough: the ASM2464PD stays powered over VBUS.

Then:  $0 status
EOF
}

case "${1:-status}" in
  status)   cmd_status ;;
  backup)   cmd_backup "${2:-}" ;;
  to-stock) flash_img "$STOCK_IMG" "STOCK ASMedia (USB4/PCIe -- llama.cpp, ROCm, Vulkan)" ;;
  to-tiny)  flash_img "$TINY_IMG"  "tiny custom ed4e39b7 (USB3 -- tinygrad DEV=USB+AMD:LLVM)" ;;
  *) sed -n '2,40p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
