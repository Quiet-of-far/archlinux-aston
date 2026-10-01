#!/usr/bin/env bash
# Read-only USB role, OnePlus firmware state and power diagnostics.
set -u
printf 'USB role: '
cat /sys/class/usb_role/a600000.usb-role-switch/role
for f in /sys/class/power_supply/qcom-battmgr-usb/oplus/*; do
 [[ -f "$f" ]] || continue
 printf '%s=' "${f##*/}"
 cat "$f"
done
for psy in /sys/class/power_supply/*; do
 for name in type online status capacity voltage_now current_now temp; do
  [[ -f "$psy/$name" ]] || continue
  printf '%s/%s=' "${psy##*/}" "$name"
  cat "$psy/$name"
 done
done
lsusb
journalctl -b -k --no-pager --since '-2 min' | rg -i 'ucsi|battmgr|notification|xhci|usb|typec' || true
