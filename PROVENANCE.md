# 构建输入

- Arch 参考工程：`code002-2/archlinux-sheng`，提交记录见 `reference/upstream-commit.txt`。保留包清单供比较，没有复制其小米专用内核、固件、设备服务。
- 系统基础：TUNA HTTPS 镜像的 Arch Linux ARM aarch64 包，下载时间 2026-09-30；基础包哈希保存在 `build/SHA256SUMS`。pacman 更新和安装保持签名校验。
- 内核：本地 `aston-mainline` 的 Aston 7.2 移植，基于 map220v/sm8550-mainline `f6e265ec752f3bbf31a49860d9d13ed2762036ec`，适配源码提交为 `9214027556c8c9a5b920a9914f42b26cab9f4171`（Quiet-of-far/aston-mainline 的 aston-7.2 分支）。提交前已验证构建的内核释放标识为 `7.2.0-sm8550-gf6e265ec752f-dirty`。
- BusyBox：官方 1.37.0 源码，最小静态 ARM64 构建，用于 initramfs；GPL-2.0。
- mkbootimg：沿用工作区已有 AOSP Python 工具，源文件保留其 Apache-2.0 标注。
- 固件：工作区缓存 `firmware-oneplus-aston-a15.deb`，Android 15 设备固件；专有许可。仅供当前设备使用。
- LocalSend：缓存 ARM64 deb `1.17.0+58`，本地 pacman 包版本 1.17.0。
- FlClash：缓存 ARM64 deb `0.8.84+202505013`，本地 pacman 包版本 0.8.84。

`secrets/`、输入归档、镜像和二进制 payload 均不进入 Git。构建清单与日志必须和输出镜像一起保留；这份说明不表示实机验证已经通过。

## 本轮硬件参考

- OnePlusOSS SM8550 Android 15 原厂模块源码：`oneplus/sm8550_v_15.0.0_oneplus11`，Aston NFC 配置确认 SN220T（23801）及 SN220U（23861）；OTG 属性参考 `vendor/oplus/kernel/charger/charger_ic/oplus_battery_sm8550.{c,h}`。仅作为接口依据，未直接并入完整 Android 充电驱动。
- KDE Plasma/6.7 `libkscreen/src/doctor/doctor.cpp` 确认 `output.1.autoRotatePolicy.always`，解决外接鼠标后旋转策略停用。

- Qualcomm FastRPC 主线兼容用户库：本轮 main 源码归档 SHA-256 `a89b8bc68927f30325836edb7553b6320fc9eb2c7c53121ec4af773f4e7367cf`，原生构建时启用 upstream driver interface。QAIRT 及 CDSP 文件来自用户本地 SDK 与本机 Android，保留在忽略的 build/，未作为仓库源码公开。

FastRPC 归档内 Git commit：`d247519650fe5cb16de6c78edaa95bcc4be25073`。

- Qualcomm libqcnpuperf：按用户要求浅克隆到工作区 `../libqcnpuperf`，main 固定提交 `d35e702d7b4485e3ce2b43270276074b2a78df87`。CPU 用户库通过 FastRPC 调用本机既有 libsysmonquery_skel.so 采集 CDSP 指标；不包含 QNN HTP 模型执行引擎。Arch 构建使用本地源码归档。

- llama.cpp：本地浅克隆官方 ggml-org/llama.cpp，固定提交 4453b535fd15cd5b9d5ccb956ebd38dc325c98fc。Podman ghcr.io/snapdragon-toolchain/arm64-linux:v0.7（Hexagon SDK 6.6.0.0 / tools 19.0.07）。本地私有补丁 patches/llama-htp-window.patch：可选禁止 CPU 运算及同步宿主 IOMMU 映射窗口；不代表上游已合并。模型为用户本地 Qwen3.5-9B-Q3_K_M，Q4_0 从该文件重新量化，原文件保留。

- 电源键动作枚举依据 KDE powerdevil v6.7.5 `daemon/powerdevilenums.h`：ToggleScreenOnOff=128；https://github.com/KDE/powerdevil/blob/v6.7.5/daemon/powerdevilenums.h 。本地 scripts/kde-defaults/powerdevilrc 保留自动挂起关闭，仅启用短按屏幕开关。

- GPU 恢复等待参考：KDE 锁屏实机堆栈及 Freedreno 维护者讨论（2025-07-25）确认 GPU/GMU 锁与 fault coredump 完成等待的循环风险：https://www.mail-archive.com/freedreno@lists.freedesktop.org/msg39111.html 。本地超时补丁 patches/gpu-coredump-wait-timeout.patch 基于当前源码编写，尚非上游合并方案。

- 虚拟键盘双语配置依据 KDE plasma-keyboard v6.7.5 src/plasmakeyboardsettings.kcfg 与 src/qml/main.qml 的 enabledLocales / updateLocales：空列表仅启用系统语言。配置为 en_US,zh_CN，保留系统中文语言。

2026-10-01 FastRPC stale-channel entry guard and mapping-error cleanup: locally authored against the saved CDSP restart Oops. Related upstream discussion (not applied verbatim): https://lkml.rescloud.iu.edu/hypermail/linux/kernel/2608.0/12287.html ; teardown fixes reviewed with unresolved cleanup concerns: https://lists.openwall.net/linux-kernel/2026/07/30/351 . Idle restart regression only; concurrent active teardown is not claimed fixed.

AA551 refresh sequences extracted from device backup stock-dtbo/entry.1, /fragment@92/__overlay__/qcom,mdss_mdp@ae00000/qcom,mdss_dsi_panel_AA551_P_3_A0004_dsc_cmd/qcom,mdss-dsi-display-timings: timing@sdc_fhd_60, timing@sdc_fhd_90, timing@oplus_fhd_120. Generated panel-aa551-mode-commands.h contains only command payloads; Qualcomm vendor packet flags are not MIPI virtual channels and are not passed as such. 30 Hz has no vendor sequence and retains 60 Hz panel configuration with host pacing. New local mode bridge conveys selected mode to prepare. Upstream sheng-7.2 still f6e265ec752f3bbf31a49860d9d13ed2762036ec on this check.

指纹新参考： https://github.com/wrobelda/goodix-fp-spi-linux （2026-10-01 检查）。仅把其 QSEECOM / smcinvoke 区分与内核接口作为研究资料；项目验证的是 Xiaomi Pad 5 Pro 的 GF3626 / gfenu，光学 GW 未测试，不能宣称支持本机 G7s_uff。须先确认本机 HAL/TA 的传输和协议，再决定移植；尚未导入其驱动或修改指纹认证配置。

本机指纹协议证据：从 PJE110_15.0.0.860 当前只读 EROFS odm/vendor 取得 service_uff、libQSEEComAPI 及 uff_gx/uff_spi 分段 TA，保存到忽略的 build/stock-fingerprint-reference，带 SHA256SUMS。service_uff 动态依赖 libQSEEComAPI，导入 start_app / shutdown_app / send_cmd / send_modified_cmd；可以确认存在 legacy QSEECom 路径，但具体 G7s 的协议尚未完成验证，不套用 gfenu 命令。未拷贝标定或模板。

#30 120 Hz 对照改用同一本机原厂 DTBO 的 timing@sdc_fhd_120 命令；默认 60 Hz 和可用模式保留。QSEE lookup 诊断模块本地编写，只依赖已有 SCM 查询接口。厂商 HAL 的 GNU objdump PLT 名称因 24 字节 BTI stub 显示错位，分析时已通过 .rela.plt GOT 地址解析实际调用；不可直接用显示标签推断 QSEE 参数。
