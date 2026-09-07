#!/bin/bash
# Keep the USB4/TB path out of runtime suspend while the chestnut dock is tunneled: the TB host (00:0d.2), the TB PCIe root ports
# (00:07.x), the TB domain, and the GPU (57:00.0) as soon as it appears. Yesterday's 9-minute tunnel session died with
# "0:3: lost during suspend, disconnecting" right after amdgpu's second "SMU is resuming" (runtime PM cycle); today's dropped 3 s
# after enumeration. Run BEFORE plugging the dock into the USB4 port, leave it running; Ctrl-C to stop.
#   sudo bash tb_hold.sh
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
on(){ [ -f "$1" ] && echo on > "$1" 2>/dev/null && echo "  $1 <- on"; }
for d in 0000:00:0d.2 0000:00:0d.3 0000:00:07.0 0000:00:07.1 0000:00:07.2 0000:00:07.3; do on /sys/bus/pci/devices/$d/power/control; done
for t in /sys/bus/thunderbolt/devices/*/power/control; do on "$t"; done
echo "waiting for the GPU (0000:57:00.0) ..."
seen=0
while true; do
  if [ -d /sys/bus/pci/devices/0000:57:00.0 ]; then
    if [ $seen = 0 ]; then seen=1; echo "$(date +%T) GPU present"; on /sys/bus/pci/devices/0000:57:00.0/power/control
      for b in 0000:53:00.0 0000:54:00.0 0000:55:00.0 0000:56:00.0; do on /sys/bus/pci/devices/$b/power/control; done
      for t in /sys/bus/thunderbolt/devices/*/power/control; do on "$t"; done; fi
    st=$(cat /sys/bus/pci/devices/0000:57:00.0/power/runtime_status 2>/dev/null); drv=$(basename "$(readlink /sys/bus/pci/devices/0000:57:00.0/driver 2>/dev/null)")
    echo "$(date +%T) gpu runtime=$st driver=${drv:-none} kfd=$([ -e /dev/kfd ] && echo yes || echo no) tb=$(cat /sys/bus/thunderbolt/devices/0-3/device_name 2>/dev/null || echo gone)"
  else
    [ $seen = 1 ] && { echo "$(date +%T) GPU GONE"; seen=0; }
    echo "$(date +%T) no gpu; tb devices: $(ls /sys/bus/thunderbolt/devices/ | tr '\n' ' ')"
  fi
  sleep 5
done
