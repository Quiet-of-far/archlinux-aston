#!/usr/bin/env bash
set -euo pipefail
project=$(cd "$(dirname "$0")/.." && pwd)
kernel_build=${1:-"$project/build/kernel-7.2-arch"}
initroot="$project/build/initramfs-root"
mkdir -p "$initroot"/{bin,sbin,dev,proc,sys,newroot,host}
install -m755 "$project/build/busybox-aarch64" "$initroot/bin/busybox"
install -m755 "$project/initramfs/init" "$initroot/init"
install -m755 "$project/initramfs/usb-debug" "$initroot/usb-debug"
install -m755 "$project/build/save-kmsg-aarch64" "$initroot/save-kmsg"
install -m755 "$project/scripts/ace3-boot-log" "$initroot/ace3-boot-log"
# Minimal BusyBox has no --install feature: provide applet links explicitly.
for applet in sh mount umount losetup switch_root mkdir sleep cat ls ln ip kill; do
 ln -sf busybox "$initroot/bin/$applet"
done
(cd "$initroot"; find . -print0 | cpio --null -o --format=newc --owner=0:0) | gzip -n > "$project/build/initramfs-arch-aston.gz"
[[ ${1:-} == --initramfs-only ]] && exit 0
python3 "$project/mkbootimg" --header_version 4 --base 0x0 \
 --kernel "$kernel_build/Image_w_dtb.gz" --ramdisk "$project/build/initramfs-arch-aston.gz" \
 --os_version 15.0.0 --os_patch_level 2025-02 -o "$project/build/boot-arch-aston.img"
