#!/usr/bin/bash
set -euo pipefail
export LC_ALL=C
printf 'Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxarm/$arch/$repo\nServer = http://mirror.archlinuxarm.org/$arch/$repo\n' > /etc/pacman.d/mirrorlist
sed -i 's/^#\?Architecture.*/Architecture = aarch64/' /etc/pacman.conf
sed -i '/^#CheckSpace$/!s/^CheckSpace/#CheckSpace/' /etc/pacman.conf
# Chroot downloads run without a separate sandbox user; signature verification stays enabled.
grep -q '^DisableSandbox' /etc/pacman.conf || sed -i '/^\[options\]/a DisableSandbox' /etc/pacman.conf
pacman-key --init
pacman-key --populate archlinuxarm
mapfile -t stock < <(pacman -Qq | grep -E "^linux-aarch64$|^linux-firmware" || true)
if ((${#stock[@]})); then pacman -Rdd --noconfirm "${stock[@]}"; fi
pacman -Syu --noconfirm
mapfile -t packages < /root/ace3-build/scripts/base-packages.list
pacman -S --needed --noconfirm "${packages[@]}"
id builder >/dev/null 2>&1 || useradd -m builder
chown -R builder:builder /root/ace3-build/packages
# Build files are moved outside root's private home for makepkg.
mkdir -p /opt/ace3-packages
cp -a /root/ace3-build/packages/. /opt/ace3-packages/
chown -R builder:builder /opt/ace3-packages
for dir in /opt/ace3-packages/*; do
 (cd "$dir"
  if [[ -f payload.tar.gz ]] && find . -maxdepth 1 -name '*.pkg.tar.*' -newer payload.tar.gz -newer PKGBUILD | grep -q .; then
   echo "Reusing current package: $dir"
  else
   runuser -u builder -- makepkg --noconfirm --cleanbuild --force
  fi
 )
 # Metrics library links against the locally packaged upstream FastRPC.
 if [[ ${dir##*/} == fastrpc-aston ]]; then
  fastrpc_package=$(find "$dir" -maxdepth 1 -name '*.pkg.tar.*' ! -name '*.sig' | sort -V | tail -1)
  pacman -U --noconfirm "$fastrpc_package"
 fi
done
# Ace3 firmware replaces the stock device-irrelevant firmware payloads.
mapfile -t fw < <(pacman -Qq | grep '^linux-firmware' || true)
if ((${#fw[@]})); then pacman -Rdd --noconfirm "${fw[@]}"; fi
mapfile -t local_packages < <(for dir in /opt/ace3-packages/*; do find "$dir" -maxdepth 1 -name "*.pkg.tar.*" ! -name "*.sig" | sort -V | tail -1; done)
pacman -U --noconfirm "${local_packages[@]}"
id ace3 >/dev/null 2>&1 || useradd -m -G wheel,video,render,input -s /bin/bash ace3
printf 'ace3:%s\n' "$(cat /root/ace3-build/secrets/login.password)" > /root/ace3-password.tmp
chpasswd < /root/ace3-password.tmp
rm /root/ace3-password.tmp
passwd -l root
userdel -r alarm 2>/dev/null || true
userdel builder
install -dm700 -o ace3 -g ace3 /home/ace3/.ssh
install -m600 -o ace3 -g ace3 /root/ace3-build/secrets/ace3_ssh_ed25519.pub /home/ace3/.ssh/authorized_keys
printf '%%wheel ALL=(ALL:ALL) ALL\n' > /etc/sudoers.d/10-wheel
chmod 440 /etc/sudoers.d/10-wheel
printf 'oneplus-aston-arch\n' > /etc/hostname
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/;s/^#zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
printf 'LANG=zh_CN.UTF-8\n' > /etc/locale.conf
mkdir -p /etc/NetworkManager/system-connections /etc/NetworkManager/conf.d /etc/ssh/sshd_config.d
printf "[main]\ndns=default\nrc-manager=file\n\n[device-ace3-usb]\nmatch-device=interface-name:usb0\nmanaged=0\n" > /etc/NetworkManager/conf.d/20-ace3-usb.conf
install -m600 /root/ace3-build/secrets/wifi.nmconnection /etc/NetworkManager/system-connections/
printf 'PermitRootLogin no\nIPQoS none\n' > /etc/ssh/sshd_config.d/20-ace3.conf
ssh-keygen -A
install -m755 /root/ace3-build/scripts/ace3-usb-debug /usr/local/sbin/
install -m755 /root/ace3-build/scripts/ace3-boot-log /usr/local/sbin/
install -m644 /root/ace3-build/scripts/ace3-usb-debug.service /etc/systemd/system/
install -m644 /root/ace3-build/scripts/ace3-boot-log.service /etc/systemd/system/
install -m755 /root/ace3-build/scripts/ace3-otg-manager /usr/local/sbin/
install -m644 /root/ace3-build/scripts/ace3-otg-manager.service /etc/systemd/system/
install -m755 /root/ace3-build/scripts/ace3-sensor-prepare /usr/local/sbin/
install -m644 /root/ace3-build/scripts/ace3-sensor-prepare.service /etc/systemd/system/
install -Dm644 /root/ace3-build/scripts/90-ace3-accelerometer.rules /etc/udev/rules.d/90-ace3-accelerometer.rules
cp -a /root/ace3-build/scripts/alsa-ucm2/. /usr/share/alsa/ucm2/
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/20-ace3.conf <<'EOF'
[General]
DisplayServer=wayland
InputMethod=qtvirtualkeyboard
[Wayland]
CompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1
[Autologin]
User=ace3
Session=plasma.desktop
EOF
install -dm755 -o ace3 -g ace3 /home/ace3/.config/systemd/user/plasma-plasmashell.service.d
install -m644 -o ace3 -g ace3 /root/ace3-build/scripts/kde-defaults/20-compat-renderer.conf /home/ace3/.config/systemd/user/plasma-plasmashell.service.d/
install -m644 -o ace3 -g ace3 /root/ace3-build/scripts/kde-defaults/kwinoutputconfig.json /home/ace3/.config/
install -m644 -o ace3 -g ace3 /root/ace3-build/scripts/kde-defaults/kscreenlockerrc /home/ace3/.config/
install -m644 -o ace3 -g ace3 /root/ace3-build/scripts/kde-defaults/powerdevilrc /home/ace3/.config/
install -m644 -o ace3 -g ace3 /root/ace3-build/scripts/kde-defaults/plasmakeyboardrc /home/ace3/.config/
install -dm755 -o ace3 -g ace3 /home/ace3/.config/systemd/user/plasma-kwin_wayland.service.d
install -m644 -o ace3 -g ace3 /root/ace3-build/scripts/kde-defaults/20-compat-compositor.conf /home/ace3/.config/systemd/user/plasma-kwin_wayland.service.d/
install -m644 -o ace3 -g ace3 /root/ace3-build/scripts/kde-defaults/30-qtquick-software.conf /home/ace3/.config/systemd/user/plasma-kwin_wayland.service.d/
install -dm755 -o ace3 -g ace3 /home/ace3/.config/systemd/user/plasma-ksplash.service.d
install -m644 -o ace3 -g ace3 /root/ace3-build/scripts/kde-defaults/20-compat-renderer.conf /home/ace3/.config/systemd/user/plasma-ksplash.service.d/
# Root and backing filesystem were mounted by our loop-root initramfs.
printf '/dev/loop0 / ext4 defaults,noatime 0 0\n' > /etc/fstab
systemctl enable NetworkManager sshd sddm bluetooth ace3-usb-debug ace3-boot-log ace3-sensor-prepare ace3-otg-manager serial-getty@ttyGS0.service
systemctl set-default graphical.target
printf 'net.ipv4.ip_forward = 0\n' > /etc/sysctl.d/50-ace3.conf
rm -f /etc/machine-id
: > /etc/machine-id
pacman -Q > /etc/ace3-package-manifest
# Explicitly check binary linkage, key services and a genuine Arch installation.
test -x /usr/bin/pacman
test -x /sbin/init
test -f /usr/share/wayland-sessions/plasma.desktop
ldd /usr/share/FlClash/FlClash | grep 'not found' && exit 1 || true
ldd /usr/share/localsend_app/localsend_app | grep 'not found' && exit 1 || true
printf 'Arch Linux ARM / Ace3 image build complete\n' > /etc/ace3-build-status
