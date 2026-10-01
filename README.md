# Arch Linux ARM for OnePlus Ace 3 (aston)

独立的 Arch Linux ARM / KDE Plasma 适配工程。参考 archlinux-sheng 的打包方式，使用工作区已有的 Aston 7.2 内核，不克隆或改写 Ubuntu 工程作为 Arch 分支。

## 布局

- 内核源码：相邻 [aston-mainline](https://github.com/Quiet-of-far/aston-mainline/tree/aston-7.2)，Aston 7.2 移植分支；对应提交见 [PROVENANCE.md](PROVENANCE.md)。
- 根文件系统：Arch Linux ARM aarch64，pacman 完整更新；桌面 KDE Plasma / Wayland，SDDM。
- 直接分区部署：Arch 独占原有 256 GiB ext4 Linux 分区 `/dev/sda15`，不受 32 GiB loop 镜像限制。`/etc/ace3-direct-root` 标记用于选择直接挂载路径。
- initramfs 内置于 Arch 专用内核（追加设备树未传递外部 ramdisk 信息）：直接挂载 `/dev/sda15` 并 switch_root。无直接部署标记时仍兼容旧 `rootfs.img` / `/dev/loop0` 启动路径。分区布局仅适用于已准备好该 Linux 分区的手机。
- 保留的模型与 MC 服务目录：`/home/ace3/test`；`/home/ubuntu/test` 仅是兼容旧脚本的链接，手机已不保留 Ubuntu 系统。
- 仅使用 `fastboot boot build/boot-arch-aston.img`；不刷写 boot/init_boot。
- 内核、Ace 3 固件、LocalSend 1.17.0 和 FlClash 0.8.84 用独立 pacman 包安装。

## 构建

主机构建 initramfs，ARM64 Linux 环境提供原生 chroot 构建（Arch 或原来的 Ubuntu）。手机构建时须连接 USB 网络，且不要重启。

1. 准备相邻 Ubuntu 工程中缓存的 ARM64 deb、`build/kernel-7.2/modules-7.2.tar.gz` 和 `Image_w_dtb.gz`。这些是构建输入，不使用 Ubuntu 根文件系统。
2. `podman build -t ace3-arch-builder .`（基础镜像 `ace3-ubuntu-builder:24.04` 来自本机已有构建环境）。
3. `python3 scripts/stage-packages.py`。
4. `scripts/build-busybox.sh`、`scripts/build-kernel.sh`。后者复用已有编译对象，给 Arch 单独内置 initramfs 并打包临时启动镜像。随后再次执行 `python3 scripts/stage-packages.py --only linux-oneplus-aston`，让 pacman 内核包包含 Arch 专用内核。
5. 下载 Arch Linux ARM aarch64 基础包到 `build/ArchLinuxARM-aarch64-latest.tar.gz`。当前镜像地址：`https://mirrors.tuna.tsinghua.edu.cn/archlinuxarm/os/ArchLinuxARM-aarch64-latest.tar.gz`。
6. 在忽略的 `secrets/` 下准备 `login.password`、`ace3_ssh_ed25519.pub`、`wifi.nmconnection`。不要将凭据提交到 Git。
7. 将基础包及包含 `scripts packages secrets` 的 `project-input.tar.gz` 传至手机 `/var/lib/archlinux-aston/build-input/`，输入归档须为 0600。
8. 在 ARM64 Linux 环境以 root 执行 `scripts/build-on-device.sh`。脚本在私有挂载命名空间构建、启用 pacman 签名验证、生成本地包和软件包清单。

`build-on-device.sh` 生成用于初次验证的 32 GiB loop 镜像，不会自动覆盖手机分区。直接部署需要先核对并迁移完整根文件系统、配置直接挂载 fstab 和上述标记，再验证临时启动。

`build-on-device.sh` 遇到失败退出并卸载镜像。重新执行会继续使用原镜像和软件包缓存；用户创建和包构建支持重试；若日志显示挂载清理失败，应先检查占用，不能在旧挂载上重复启动。

## 调试

Arch 用户 `ace3`，密码来自本机 `secrets/login.password`。USB 提供 NCM 网络和 ACM 串口，手机地址 `192.168.77.2/24`，主机需配置 `192.168.77.1/24`。

```sh
ssh -o IPQoS=none -i secrets/ace3_ssh_ed25519 ace3@192.168.77.2
```

USB ACM 串口也提供正常登录控制台：电脑端执行 `screen /dev/ttyACM0 115200`，使用 `ace3` 和既有登录密码；`Ctrl+A` 后按 `D` 可脱离。串口设备编号以实际枚举为准。

SSH 主机指纹须使用构建阶段生成的 `arch-host-key.pub` 验证。Wi-Fi 使用用户当前提供的配置，不依赖 DHCP 地址。直接分区启动的早期日志位于 `/var/log/ace3-boot/`，开机服务日志位于 `/var/log/ace3-kernel-tests/`。兼容的循环镜像启动路径仍将开机日志保存在 backing 分区 `/.backing/var/lib/archlinux-aston/boot-debug/`，早期内核日志在同目录上级的 `early-kmsg.log`。

## 当前验证状态

2026-10-01：Arch Linux ARM / KDE Plasma 6.7.5，7.2 内核，FD740 OpenGL ES 桌面合成，缩放 2.5 倍。默认 60 Hz；90/60/30 Hz 画面通过用户验证，120 Hz 错位仍在修复。Qt Quick 锁屏及虚拟键盘使用软件渲染以规避 GPU 冻结；中英文和 Shift 解锁、电源键熄屏亮屏及正常重启已通过。自动锁屏和挂起仍关闭，深度挂起未验证。

四方向旋转、触摸、USB 调试、无 PD / 有 PD 的 OTG 键鼠、内置麦克风录音、蓝牙 A2DP 回放和实体 NFC 卡检测已通过。三路相机可输出帧，画质标定按用户要求暂停，主摄和指纹未完成适配；快充最大功率未确定。具体条件及未通过项见 [VALIDATION.md](VALIDATION.md)。

原生 llama.cpp Hexagon v73 HTP + CPU 回落已执行 Qwen3.5-9B Q4_0 推理，单会话有效；QAIRT/QNN Linux 对 SM8550 的兼容问题仍存在。测速参数和成绩见验证记录，不代表纯 NPU 或 GPU 测速。

参考：[archlinux-sheng](https://github.com/code002-2/archlinux-sheng)、[sm8550-mainline](https://github.com/map220v/sm8550-mainline)。
