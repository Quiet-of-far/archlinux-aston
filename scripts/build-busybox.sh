#!/usr/bin/env bash
set -euo pipefail
project=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$project/build"
archive="$project/build/busybox-1.37.0.tar.bz2"
[[ -f "$archive" ]] || curl -fL https://busybox.net/downloads/busybox-1.37.0.tar.bz2 -o "$archive"
tar -xf "$archive" -C "$project/build"
podman run --rm --userns=keep-id -v "$project/build:/build:rw" ace3-arch-builder bash -lc '
cd /build/busybox-1.37.0
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- allnoconfig
for symbol in STATIC LONG_OPTS LN IP FEATURE_IP_ADDRESS FEATURE_IP_LINK KILL ASH SH_IS_ASH ASH_ECHO ASH_PRINTF ASH_TEST ASH_ALIAS ASH_GETOPTS ASH_CMDCMD FEATURE_SH_MATH FEATURE_SH_MATH_64 TEST TEST1 TEST2 MOUNT FEATURE_MOUNT_FLAGS FEATURE_MOUNT_LOOP UMOUNT LOSETUP SWITCH_ROOT MKDIR SLEEP ECHO CAT LS; do
 sed -i "s/^# CONFIG_${symbol} is not set/CONFIG_${symbol}=y/" .config
done
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- oldconfig < /dev/null
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j6
cp busybox /build/busybox-aarch64
'
