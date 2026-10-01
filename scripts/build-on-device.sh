#!/usr/bin/env bash
set -euo pipefail
if [[ ${ACE3_PRIVATE_MOUNT_NS:-0} != 1 ]]; then
 exec unshare --mount --propagation private env ACE3_PRIVATE_MOUNT_NS=1 bash "$0" "$@"
fi
[[ $(uname -m) == aarch64 ]] || { echo 'Run on the ARM64 Ubuntu phone'; exit 1; }
staging=${1:-/var/lib/archlinux-aston/build-input}
image=/var/lib/archlinux-aston/rootfs.img
root=/mnt/archlinux-aston-build
mkdir -p "$(dirname "$image")" "$root"
exec 9>"$image.lock"
flock -n 9 || { echo "Another Arch image build is running"; exit 1; }
mountpoint -q "$root" && { echo "Build root still mounted; clean it first"; exit 1; }
[[ -z $(losetup -j "$image") ]] || { echo "Image already attached"; exit 1; }
if [[ ! -e "$image" ]]; then
 truncate -s 32G "$image"
 mkfs.ext4 -q -L arch-aston "$image"
fi
loop=$(losetup -f --show "$image")
cleanup() {
 for path in /proc/[0-9]*; do
  [[ $(readlink "$path/root" 2>/dev/null) == "$root" ]] || continue
  name=$(cat "$path/comm" 2>/dev/null || true)
  case "$name" in gpg-agent|dirmngr|scdaemon) kill -TERM "${path##*/}" 2>/dev/null || true;; esac
 done
 sleep 1
 umount -R "$root" || { echo "Build mount cleanup failed; do not retry over this mount"; return 1; }
 losetup -d "$loop"
}
trap cleanup EXIT
mount "$loop" "$root"
if [[ ! -x "$root/usr/bin/pacman" ]]; then
 tar --numeric-owner -xpf "$staging/ArchLinuxARM-aarch64-latest.tar.gz" -C "$root"
fi
mkdir -p "$root/root/ace3-build"
tar --numeric-owner -xpf "$staging/project-input.tar.gz" -C "$root/root/ace3-build"
rm -f "$root/etc/resolv.conf"
dns=${BUILD_DNS:-$(ip -4 route show default | awk 'NR==1 {print $3}')}
[[ -n "$dns" ]] || dns=1.1.1.1
printf 'nameserver %s\n' "$dns" > "$root/etc/resolv.conf"
ln -sf /proc/self/mounts "$root/etc/mtab"
mount --rbind /dev "$root/dev"
mount --make-rslave "$root/dev"
mount -t proc proc "$root/proc"
mount --bind /sys "$root/sys"
chroot "$root" /bin/bash /root/ace3-build/scripts/configure-arch.sh
mkdir -p "$staging/output-packages"
cp "$root"/opt/ace3-packages/*/*.pkg.tar.* "$staging/output-packages/"
cp "$root/etc/ace3-package-manifest" "$staging/"
cp "$root/etc/ssh/ssh_host_ed25519_key.pub" "$staging/arch-host-key.pub"
rm -rf "$root/root/ace3-build/secrets"

sync
