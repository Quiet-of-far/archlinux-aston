#!/usr/bin/env bash
set -euo pipefail
project=$(cd "$(dirname "$0")/.." && pwd)
source_dir=${1:-"$project/../aston-mainline"}
cached=${2:-"$project/../ubuntu-oneplus-aston/build/kernel-7.2"}
output="$project/build/kernel-7.2-arch"
if [[ ! -d "$output" && -d "$cached" ]]; then
 cp -a --reflink=auto "$cached" "$output"
fi
mkdir -p "$output"
podman run --rm --userns=keep-id -v "$project:/arch:rw" ace3-arch-builder \
 aarch64-linux-gnu-gcc -static -Os -s /arch/initramfs/save-kmsg.c -o /arch/build/save-kmsg-aarch64
"$project/scripts/package-boot.sh" --initramfs-only
gzip -dc "$project/build/initramfs-arch-aston.gz" > "$project/build/initramfs-arch-aston.cpio"
podman run --rm --userns=keep-id \
 -v "$source_dir:/kernel:ro" -v "$project:/arch:rw" \
 ace3-arch-builder bash -lc '
export ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
output=/arch/build/kernel-7.2-arch
if [[ ! -f "$output/.config" ]]; then
 make -C /kernel O="$output" defconfig sm8550.config
fi
/kernel/scripts/config --file "$output/.config" --set-str INITRAMFS_SOURCE /arch/build/initramfs-arch-aston.cpio
/kernel/scripts/config --file "$output/.config" --module SPI_GPIO --module BMI270_SPI
/kernel/scripts/config --file "$output/.config" --module BATTERY_QCOM_BATTMGR
make -C /kernel O="$output" olddefconfig
make -C /kernel O="$output" -j6 Image dtbs modules
rm -rf /arch/build/modules-stage
make -C /kernel O="$output" modules_install INSTALL_MOD_PATH=/arch/build/modules-stage
find /arch/build/modules-stage/lib/modules -maxdepth 2 -type l \( -name build -o -name source \) -delete
tar -C /arch/build/modules-stage -czf "$output/modules-7.2.tar.gz" lib/modules
cat "$output/arch/arm64/boot/Image" "$output/arch/arm64/boot/dts/qcom/sm8550-oneplus-aston.dtb" | gzip -n > "$output/Image_w_dtb.gz"
'
"$project/scripts/package-boot.sh" "$output"
