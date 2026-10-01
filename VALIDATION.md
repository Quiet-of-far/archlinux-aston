# Ace3 Arch 实机验证（2026-09-30）

独立 Arch Linux ARM KDE 工程；根镜像位于现有 Ubuntu 分区内，Ubuntu 保留。全部启动验证使用 `fastboot boot`，未刷写启动分区。

## 已验证

- KDE Plasma / Wayland、FD740 GPU 合成、2.5 倍缩放运行。DSC 参数匹配面板 PPS，并开启 block prediction 后，用户确认整体显示正常、文字横线消失。
- 用户分别确认 90、60、30 Hz 标称模式下动态画面正常。120 Hz 仍随机错位；165 Hz 曾出现自动重启，未确认原因，默认保持 60 Hz。
- DRM WAIT_VBLANK 事件计数在不同标称模式下存在不一致，不能作为面板实际扫描频率的最终证明。浏览器 UFO Test 在标称 60 Hz 下报告 42–45 FPS，原因仍需分析。
- LocalSend / FlClash 中文字体实机已正常；应用修正尚需完整并入可重复构建的包。
- BMI260 采样和四方向自动旋转经用户确认正确。修复 SPI 模块自动加载别名、暖启动复位及固件初始化；规则使用轮询并避开 SSC 抢占。新驱动重新加载后旋转正常，完整重启发现首次绑定仍失败，晚期重新绑定恢复；已加入 ace3-sensor-prepare 有界启动重试服务，内核 #20 的完整启动中服务成功，用户确认旋转正常。KDE 默认“仅平板模式自动旋转”在接鼠标后停止旋转，已改为“始终自动旋转”，用户确认连接键鼠时旋转恢复正常。
- 内置麦克风录制实际说话/拍手，蓝牙耳机 回放录音，用户确认声音清楚。
- 蓝牙耳机实际配对、信任、A2DP 回放及重启后自动重连正常。尚未单独验证耳机麦克风。
- 修复 IMX355 电源属性名及复位极性后，前摄 S5K3P9、超广角 IMX355、微距 OV02B1B 均注册并输出帧。
- CDSP FastRPC 实际能力查询成功，返回 HVX/VTCM 等信息；这不等于 NPU 模型推理验证通过。
- USB NCM SSH、Wi-Fi SSH 均可用。USB-C OTG 主机模式须另行实测。
- 电量驱动已移除 Oplus 固件提供的固定 50% 假电池及不存在的无线充电接口，保留 BQ28Z610 实际电池和 USB 输入信息；实机模块加载通过。

## 尚未通过或待验证

- 相机输出存在颜色/网格等画质异常；主摄 IMX890 尚无驱动接入。不能宣称前后摄完整可用。
- NFC 实体卡已实测检测到 MIFARE 协议，射频检测通路通过。此前手机空白门卡未检出，不能据此认定所有 NFC 功能异常。保留配置变体与内核 #20 原始初始化对照均检测成功。控制器启用后卸载存在 info_lock 重入死锁，已修正 nxp_nci_remove 的关闭顺序；#20 启用状态卸载在 15 秒超时内成功，重新加载及启用通过。0xf36 是未处理的厂商通知，未证明它阻断读卡。
- 用户提供 QAIRT 2.50.40.260831 本地 SDK。官方 FastRPC 用户库已原生编译，补齐本机 Android CDSP shell/runtime 后，QNN 平台验证器实际 DSP 求和测试通过。量化模型已编译，但 Linux HTP 库启动报 Unsupported SoC model 43；SDK overview 对 SM8550 仅列 aarch64-android。HTP 模型推理尚未通过，不能将 DSP 求和成功等同 NPU 推理完整支持。
- 指纹尚未接入主线驱动；Android 标识为 Goodix G_OPTICAL_G7s_uff，光学型；仍需厂商协议及可信应用接入。用户已说明换屏后 Android 本身也无法成功识别指纹。
- OTG 自动角色切换失败（UCSI 初始化失败）。手动切换为 host 并接扩展坞 PD 供电后，扩展坞、键鼠和 RTL8153 网卡成功枚举。手机无外部供电时未枚举；向外供电和自动角色切换待修复，用户确认鼠标移动和键盘输入正常。
- 小米 67 W 充电器直连测试：驱动报告约 5.04 V、0.67–0.74 A，电池满电 100%，未观察到高电压快充协商。该满电测试不能确认最大充电功率；USB 类型报告为 SDP，仍需对照 Android 原厂协议。
- 自动锁屏虚拟键盘、熄屏唤醒及挂起尚未解决；当前调试配置关闭自动锁屏/熄屏/挂起。
- 已统一生成默认临时启动镜像、内核包 7.2.0-8 与固件包 15.0.0.860-2，并在手机安装。完整临时启动检查已通过桌面、旋转和 NFC 检测，旧手工模块覆盖已备份后清理。

## 构建与备份

本机 build/ 中的首次 rootfs 归档为旧快照，不包含所有后续实机修正；最终交付前需更新。旧快照 SHA-256：`1f13a714460253086e87a725f2d937e1ce22fc89cdf1b0ed68268c1247c3263d`。

构建产物位于忽略的 build/，登录和 Wi-Fi 凭据位于忽略的 secrets/。诊断照片、录音及日志为本地测试资料。

## 当前恢复点

手机运行默认临时启动镜像 #20，内核包 7.2.0-8 已安装并统一使用包内压缩模块。桌面和旋转正常；原始 NFC 初始化检测实体 MIFARE 卡成功，关闭/卸载/重新启用测试通过。当前使用 USB 调试，继续排查 OTG 自动切换和向外供电。

OTG 排查：已编译并临时加载只读诊断模块，在 USB 电源接口增加 Aston 专用 `oplus/` 状态。接电脑时 `otg_ap_enable`、`otg_switch`、`otg_vbus_enable`、`typec_mode` 均读回 0；尚未修改供电控制，诊断模块未写入包 8。
随后固件报告 `typec_mode=1`、USB 输入 online=0，并收到原厂 OTG enable 通知 0x50；主线当前不处理该通知，VBUS enable 仍为 0。这支持“检测到了 OTG，但未执行供电”的判断，仍等待用户确认接线后继续受保护的供电验证。日志 `build/otg-readonly-attach.log`。

2026-10-01 OTG：限时供电测试在无 PD 扩展坞上枚举鼠标、Hub 和 RTL8153，用户确认鼠标可移动；退出后 VBUS 读回 0。已启动临时自动 OTG 服务，根据原厂 typec_mode 切换 host/device，低电量、高温、过流或读取失败时关闭输出；供电由 30 秒内核租约兜底，服务每 10 秒续期。当前尚待拔插及 PD 切换验证，服务未设为开机启动，新增模块尚未并入内核包。保守诊断限值不代表完成了完整原厂充电/热管理移植。

无 PD 拔插复测：用户确认鼠标及旋转正常。初版服务在接 PD 时误将电源角色变化当成数据角色变化，鼠标失效；保留已建立的 OTG 主机角色并加入 5 秒断开判定后，用户确认 PD 切换时鼠标及旋转正常。实测 role=host、USB online=1、otg_vbus_enable=0，停止手机输出并保留数据主机。冷启动直接接已供电扩展坞、短于 5 秒的转接电脑、异常掉电/过流切断还未实测，不能视为完整 UCSI 移植。
内核包 `7.2.0-9` 已安装；默认临时启动镜像已更新，OTG 服务已启用开机启动。脚本语法检查、实际模块编译、无 PD 拔插和接入 PD 数据/供电分离均通过；完整重启验证待进行。

内核 #21 / 包 7.2.0-9 完整临时启动通过：用户确认桌面和旋转正常，OTG 服务自动 active，USB 调试正常，HasAccelerometer=true，系统无失败服务。日志 `build/kernel9-fresh-boot-validation.log`。本次退出前一轮 Arch 至 bootloader 顺利完成；未刷写启动分区。

前摄控制修正：S5K3P9 曝光/增益控件原本未连接 s_ctrl，开流还覆盖用户值。已接入 CCI 写入并删除覆盖，通过临时模块采集测试帧，物体可辨认但偏色/噪点未解决。手动曝光 1000、gain code 256 的采集元数据反映对应值；代码到实际增益倍数尚需标定，libcamera sensor helper / tuning 仍缺失。热解绑发现旧驱动 regulator 引用告警，进一步修正 probe 的 runtime PM 计数和电源错误退出，尚待编译与新启动验证。临时模块在 /home/ace3 加载，未覆盖包 9 文件。

包 7.2.0-10 / 内核 #22 临时启动通过，三路传感器注册，前摄连续两次开流均收到帧并回到 runtime suspended，未见 S5K3P9 供电错误或 regulator 不平衡日志。早期 disp_cc_mdss_mdp_clk_src 的 RCG 初始化告警仍存在，已单独记录，不能宣称所有启动日志问题解决。前摄 gain 转换、裁剪选择接口及 ISP 调校仍待补齐。

2026-10-01 用户要求暂停相机标定，优先 NPU。Qualcomm libqcnpuperf 按要求浅克隆，提交 d35e702d7b4485e3ce2b43270276074b2a78df87，原生构建并安装 `libqcnpuperf-aston 1.0.r1.d35e702-1`。原先手工 FastRPC 已备份并纳入 `fastrpc-aston 0.0.1.r1.d247519-1`；Arch 合并 /usr/sbin 的包装路径已修正为 /usr/bin，禁用剥离 DSP 二进制。实测 libqcnpuperf 的 CDSP open/query/close 成功，返回 5 个指标，架构代码 0x73、Q6 时钟 460800 kHz，HVX/HMX 空闲利用率为 0。新 FastRPC 下 QNN DSP 求和测试再次通过。HTP 量化模型仍失败于 Unsupported SoC model 43，缺少性能采集库并非该阻塞点。支持 SM8550 的 Linux HTP 运行库仍待提供或适配，不得标为 NPU 模型推理成功。日志 `build/npu-after-libqcnpuperf-validation.log`、`build/qnn-validator-after-packaged-fastrpc.log`。

QAIRT 2.42.0.251225 对照（2026-10-01）：使用该版本的 ARM64 OE Linux gcc11.2 运行库、V73 stub/skel、net-run、头文件和示例量化模型，独立部署 `/home/ace3/qnn-test-2.42`，未混用 2.50 库。模型原生编译成功，平台验证器 DSP 求和通过。默认 HTP 推理失败于 Unsupported SoC model 43 / Invalid dsp arch，device creation 退出 11；按文档通过 backend extensions 显式配置真实 SoC=43、arch=v73、unsigned PD 后，配置解析成功，但库提示真实设备忽略 ARCH/SOC 配置，同样退出 11，未执行图。该版本 SDK 支持表对 SM8550 仍只列 aarch64-android。额外 CPU backend 对照退出 10（backend initialization failure），未用 CPU 结果代替 NPU 验证。日志：`build/qnn-2.42-platform-validator.log`、`build/qnn-2.42-model-build.log`、`build/qnn-2.42-htp-test.log`、`build/qnn-2.42-htp-config-test.log`。相机标定仍按用户要求暂停。

## 2026-10-01 llama.cpp 原生 HTP 推理

官方 llama.cpp 4453b535fd15cd5b9d5ccb956ebd38dc325c98fc，ARM64 Linux / Hexagon v73，实际初始化 HMX=1、HVX=4、VTCM=8 MB。使用原生 FastRPC，绕开 QNN Linux 对 SoC 43 的限制；QNN 本身仍未通过。构建未启用 Vulkan/OpenCL，所以本次回落仅 CPU。

Bonsai PTQ1_0 是 Prism 私有类型，官方 HTP 不支持，未运行该模型。按用户指定改测 Qwen3.5-9B。原始 Q3_K_M 不支持完整 HTP 算子卸载，已保留原件，并使用 allow-requantize/pure 派生 Q4_0；重新量化可能损失质量。

宿主 IOMMU 32 位地址空间无法同时映射完整权重。已提供本地补丁，在 DSP 操作同步完成后逐出不再需要的宿主权重映射。单会话、1536 MiB 映射窗口、128 MiB MBUF、1536 MiB VMEM。

llama-bench：pp64/tg32，batch/ubatch=64、4 CPU 线程、FA on、f16 KV、两轮采样（含单独 warmup）。单位 token/s：

| 模型 | 大权重逐出阈值 | pp64 | tg32 |
|---|---:|---:|---:|
| Q3_K_M 原始 | 64 MiB | 7.60 | 2.91 |
| Q4_0 派生 | 64 MiB | 132.98 | 2.15 |
| Q4_0 派生，优化参数 | 256 MiB | 166.78 | 5.32 |

Q4_0 最佳值与 Q3_K_M 使用不同逐出阈值，不能视为完全相同配置比较。Q3_K_M 的 256 MiB 配置生成阶段映射失败，不计为有效成绩。无 CPU-only 或 GPU 基线，不能宣称加速倍数或纯 NPU 速度。

手机命令：`sudo /home/ace3/run-qwen-htp.sh '你的提示词'`。默认 2048 context、最多 256 tokens，可追加 `-n 512`。脚本按该 GGUF 的模板显式关闭思考，实际 smoke 输出“4”；不是仅完成加载。运行脚本与测速脚本在 scripts/，本地补丁在 patches/llama-htp-window.patch。

双虚拟 HTP 会话触发 CDSP fatal/SSR，随后旧 FastRPC 文件描述符映射导致内核 Oops；重启恢复。仅单会话已验证，禁止把双会话失败当作通过；异常恢复路径仍待修复。日志与 JSON 保存在忽略的 build/。当前恢复点为内核 #22 / 包 7.2.0-10，2026-10-01 再次临时启动通过、系统无失败服务。

锁屏/电源键复测：本轮原版 #22 的手动锁屏，用户确认密码框可呼出键盘；未复现此前键盘问题。调试配置把 PowerButtonAction 设为 0（无动作），依据 KDE 6.7.5 PowerButtonAction 枚举改为 128（ToggleScreenOnOff），实机配置重新加载，用户确认短按熄屏/亮屏可用。仅 DPMS 切换，不代表 deep suspend 已验证；自动锁屏/自动挂起仍关闭。

锁屏期间 GPU 出现 GMU OOB GPU_SET 超时、preemption timed out、hangcheck recover，用户观察短暂卡死后恢复。保存 build/gpu-lock-screen-{kernel,kwin}.log；已生成独立对照镜像 boot-arch-aston-no-preempt.img，cmdline msm.enable_preemption=0，默认镜像未覆盖，尚待启动实测。

关闭抢占对照尚未实际启动：2026-10-01 11:25 左右正常退出 #22 时 USB gadget 保留、SSH 停止，超过常规关机时间仍未进入 bootloader，等待用户强制重启。需在下次启动读取前一轮 journal，不能将停滞直接归因于 GPU。

关机日志回收：上一轮 journal 停在关闭 KWin；30 秒后 kwin_wayland_wrapper 报进程仍运行，90 秒后 logind 才移除 session。可见的 shutdown transaction / BlueZ / PipeWire 错误发生于停止服务期间，尚不足以解释阻塞，GPU 超时及 KWin 退出路径是当前调查重点。完整日志 build/previous-shutdown-full.log 与 previous-boot-kernel.log。

首次关闭抢占测试镜像仅写 boot header cmdline，但 CONFIG_CMDLINE_FORCE=y 导致参数被忽略（实际仍 -1），该轮不计为关闭抢占验证。已在专用 #23 Image 中编入 msm.enable_preemption=0；原默认 #22 启动镜像保持，构建目录 .config 已恢复。该对照不含额外驱动源码改动。

#23 msm.enable_preemption=0 已确认生效，但锁屏后仍冻结。日志首次 GPU fault 指向 kscreenlocker_greet（CP 读取 iova=0），同时出现 GMU OOB 超时。因此关闭抢占不是充分修复；默认 #22 不改。准备 Qt Quick 软件渲染对照：用户 KWin 服务添加临时 30-qtquick-software.conf（QT_QUICK_BACKEND=software），KWIN_COMPOSE=O2ES 仍保留。尚待新会话验证。

关机阻塞栈已捕获（build/shutdown-runtime-pm-stacks.log）：recover worker 在 a6xx_gmu_set_oob 等待 fault_coredump_done；IOMMU IRQ fault dump 阻塞 msm_gpu_fault_crashstate_capture 的 gpu->lock；KWin 等待 rpm_resume，reboot 系统调用等待 device_shutdown 的 pm_runtime_barrier。GPU/GMU 转储等待的锁循环支持死锁判断。保存并 sync 后 SysRq 紧急重启成功，回到原版 #22，再正常退出准备测试内核。

已修改 a6xx_gmu_set_oob 与 a6xx_hfi_wait_for_msg_interrupt，转储等待统一使用 2 秒截止时间，超时返回原有错误路径而非永久阻塞。专用 #24 内核已编译；默认 #22 镜像未覆盖，Qt Quick 软件配置已禁用以隔离变量。该补丁只处理等待死锁，不表示已修复原始 GPU fault；实机验证待进行。

#24 实机第一轮：用户确认外接键盘解锁后菜单/窗口操作与电源键熄屏亮屏正常，未出现冻结。虚拟键盘无法切到英文并非驱动问题：plasma-keyboard 在 enabledLocales 为空时只启用 Qt 系统语言 zh_CN。已配置 plasmakeyboardrc [General] enabledLocales=en_US,zh_CN，并 --notify 热加载，默认构建配置同步加入；待屏幕键盘英文/Shift/实际解锁确认。#24 后续日志仍见短暂 GMU OOB 超时，但 KWin 未处于 D 状态、无失败服务，不能宣称原始 GPU fault 已根治。

#24 第二次锁屏启用双语键盘后仍冻结。当前线程抓取未见上一轮 gpu->lock / fault_coredump_done 的 D 状态锁循环，但日志继续有 GMU OOB 超时及抢占恢复。等待超时修正不能视为完整冻结修复。临时启用 KWin 用户服务 30-qtquick-software.conf，让它启动的锁屏/虚拟键盘 Qt Quick 软件渲染，KWin 合成继续 O2ES；准备正常退出后的重启验证。双语键盘实际解锁尚未通过。

#24 第二轮正常关机仍超过 55 秒未进入 bootloader，SSH 已停止。不能标记关机修复完成；Qt Quick 软件渲染配置已经保存，下一次启动验证。需要在后续临时配置中让 sshd 不随默认 shutdown 依赖提前退出，保留认证的 USB 调试通道以读取停止阶段堆栈；该配置仅用于诊断，不加入默认系统。


#24 Qt Quick 软件渲染规避措施已通过用户实测：英文/中文切换、Shift 大小写密码解锁、菜单操作和电源键熄屏亮屏均正常。锁屏及 plasma-keyboard 继承 QT_QUICK_BACKEND=software；KWin supportInformation 仍显示 freedreno FD740 / OpenGL ES 3.2，桌面 GPU 合成保留。该轮未见 GPU 超时/故障，正常关机成功进入 fastboot；不能据此宣称原始 GPU 驱动故障已根治。成功退出日志仍有 /.backing 卸载目标忙，但没有阻止本轮重启，不能将它直接视为此前长时间关机的原因。日志 build/qtquick-software-shutdown.log。

已将双语 plasmakeyboardrc、PowerButtonAction=128 及 Qt Quick 软件渲染用户服务配置纳入 configure-arch.sh。GPU 转储等待 2 秒截止补丁保存为 patches/gpu-coredump-wait-timeout.patch。内核包 7.2.0-11 已安装，默认临时镜像改为 #24；未修改启动分区。临时 sshd shutdown 诊断 drop-in 已移除，DefaultDependencies=yes 恢复；正在验证恢复默认 SSH 依赖后的正常退出和默认镜像启动。自动锁屏/自动挂起仍禁用，deep suspend 未验证。

最终默认镜像验证通过：恢复 sshd 默认依赖后的正常重启进入 fastboot，fastboot boot 默认 boot-arch-aston.img 成功；实机 uname #24、包 7.2.0-11、传感器准备服务 active、系统无失败服务。双语键盘及 Qt Quick 软件渲染配置持久化，KWin 仍为 freedreno FD740 / OpenGL ES 3.2 Mesa 26.2.3 GPU 合成；本轮检查未见 GPU fault / GPU_SET / preemption timed / hangcheck。

#25 / 包 7.2.0-12 临时启动成功，系统无失败服务。FastRPC 新增入口拒绝断开通道的旧 fd，修正失败映射的 DMA unmap / table 清空，避免双重清理。实机回归：32 次 4 KiB DMA buffer / 8 KiB 请求均返回 EINVAL，原缓冲区仍可 mmap 读写；保留旧 fd 停启 CDSP 后，停机和重启阶段 MEM_MAP 均返回 EPIPE，新 fd 仍正常拒绝越界长度。随后 Qwen HTP 实际输出 4，退出 0，无 Oops。测试仅覆盖空闲 CDSP 的停启，入口检查不是对并发 teardown 竞态的完整解决，也不表示双 HTP 会话已修复。程序 scripts/diagnostics/fastrpc-restart-check.c，补丁 patches/fastrpc-stale-channel-map-cleanup.patch。

刷新率诊断：#25 之前默认 60 Hz 模式下，Qt Quick 软件动画期间 DRM WAIT_VBLANK 计数约 118.219 Hz。静止画面下计数等待会阻塞，不能直接等同物理扫描。原厂 DTBO 含独立 60/90/120 Hz 模式切换命令，现驱动 prepare 后硬编码 60 Hz 序列，未根据选择的 DRM 模式切换。准备 mode bridge 传递刷新率并按原厂序列设置面板。30 Hz 仍仅为主机 pacing，原厂 DTBO 未提供该模式序列；不猜写未知寄存器。

#26 / 包 7.2.0-13 已编译并进入临时启动验证。面板通过受管理的 mode bridge 接收 DRM adjusted mode，prepare 使用相应原厂 60/90/120 Hz 切换序列；保留既有 DSC 修正和软件 Qt Quick 规避措施。30 Hz 暂沿用 60 Hz 面板配置，仅改变主机更新节奏。尚待实机动态显示确认，不计为 120 Hz 修复成功。

#26 120 Hz 模式命令实机失败：用户报告整屏花屏，立即恢复 60 Hz 后用户确认正常。已构建 #27，将 AA551 120 Hz 命令配套到原厂 DSI 1.1136 Gbps（byte clock 139.2 MHz，pixel clock 按原 RGB101010 比例 148.48 MHz），只影响 120 Hz；尚待实测。不得将 #26 记为已修复。

Wi-Fi：驱动未取得有效 MAC，重启随机地址；已将 用户 Wi-Fi 连接的 cloned-mac-address 设为 stable，并更新私有构建输入，后续启动使用 NetworkManager 持久身份生成地址。当前电量 100%，仍不适合据此判断最高充电功率。

#27 120 Hz 配套时钟实测仍失败：用户报告黑屏，已切回 60 Hz 并撤回时钟覆盖。实际读回 DSI bit clock 1113600000、byte 139200000、pixel 148480000，不能以请求未生效解释失败。#27 的 90 Hz 原厂模式序列用户确认正常。#28 构建撤回时钟改动；120 Hz 模式命令仍未修复，不计为成功。

Qt Quick 独立动画对照：使用实际打开 renderD128 的 OpenGL QML 进程，默认 Mesa 与 FD_MESA_DEBUG=noubwc 各运行约 25 秒，均退出 0，未见 GPU fault / 超时。这一简化用例没有复现锁屏故障，因此不能据此认定禁用 UBWC 是修复；保留锁屏和屏幕键盘的软件渲染规避。

#28 / 包 7.2.0-14 已安装并通过 fastboot boot 启动，uname 已核实，启动检查无失败服务。切换到 60 Hz 后读取 super 的前 1 MiB 只读元数据，USB SCP 在约 1020 KiB 时停滞，随后 USB SSH / ping 无响应，但宿主仍枚举 NCM 与 ACM、未记录 USB 断开。Wi-Fi 备用连接暂未找到。该轮稳定性待定位，不能记为通过。未刷写启动分区。

#28 USB 连接后来自动恢复。journal 未见 GPU fault / 内核崩溃，OTG 角色未发生变化；后续 8.5 MiB 只读参考文件传输完成，系统仍无失败服务，HasAccelerometer=true。不能由此解释首次停滞，保留 build/kernel28-link-stall.log 和 kernel28-stall-services.log。

通过 super 原始元数据创建只读 dm-linear vendor_a / odm_a 映射并以 EROFS ro 挂载，找到本机 service_uff 的 libQSEEComAPI.so 依赖与 start_app/send_cmd/send_modified_cmd 导入，以及本机 uff_gx、uff_spi 固件。仅复制厂商二进制到私有忽略的 build 参考目录，未访问指纹模板/标定文件，随后卸载并移除 dm 映射。光学 G7s_uff 尚无已验证 Linux 认证链路。

#29 / 包 7.2.0-15：将 DRM preferred mode 从 120 Hz 改为已验证的 60 Hz，避免 fbcon / 新桌面配置默认使用已知异常模式。120/90/60/30 等模式仍保留，120 Hz 没有因此修复。完整内核及模块编译成功、包校验安装完成，准备临时启动验证。

#29 临时启动核实成功：uname #29、包 7.2.0-15、首次 AA551 prepare 为 60 Hz、DRM 当前 60 Hz；无失败服务，传感器准备 active，HasAccelerometer=true。没有观察到本轮 GPU fault / OOB 超时 / hangcheck。启动日志 build/kernel29-boot-validation.log；仍需用户确认显示及旋转，120 Hz 与原始 Qt Quick GPU 冻结未宣称修复。

#30 / 包 7.2.0-16 临时启动：只将 120 Hz 切换序列从 timing@oplus_fhd_120 改为 timing@sdc_fhd_120；其余 DSC、时钟、60/90 序列、60 Hz preferred mode 保持。原厂 Oplus 序列带 OSYNC 同步配置（hsync skew=2），标准 SDC 120 序列不带这组配置（skew=0）；这仅提供对照依据，不代表已经找到根因。DRM 120 Hz 与面板 selected 120 日志均已核实，三分钟 systemd timer 自动恢复 60 Hz。待用户动态画面确认。

本机只读 QSEE 应用查询：SCM 探测 QSEECom version=0x1402000；上游 allowlist 跳过该机器。外部 GPL 诊断模块仅调用 qcom_scm_qseecom_app_get_id，uff_gx/uff_spi 均返回 -ENOENT，未执行加载、命令、GPIO、电源或标定/模板操作，随后卸载模块。证明存在可查询的 legacy QSEE 路径及未预加载应用，但不表示指纹认证已打通。源码 scripts/diagnostics/qsee-lookup.c，日志 build/kernel30-qsee-display-validation.log。

#30 SDC 120 Hz 实测：用户确认仅动态错位，其他正常；此前整屏花屏已不再出现。启动刷日志无错位时使用的是默认 60 Hz，不能将启动表现作为 120 Hz 通过证据。三分钟 timer 已恢复到 DRM 60 Hz，未见本轮 GPU fault。保留 boot-arch-aston-kernel30.img 作为对照。准备 #31，在相同 SDC 120 命令下单独复测原厂 1.1136 Gbps / byte 139.2 MHz / pixel 148.48 MHz，以区分此前 OSYNC 序列与时钟同时影响的结果。

#31 时钟对照已临时启动：沿用包 7.2.0-16 的相同 SDC 面板模块，只更换含 AA551 120 Hz 时钟覆盖的内核 Image。默认镜像保留 #30；#31 保存为 boot-arch-aston-kernel31-stock-clock.img。已读回 byte=139200000、pixel 请求=148480000、PHY DSI bit rate=1113600000，与 DRM/面板 120 Hz 同时生效，待用户结果。三分钟 timer 恢复 60 Hz。

120 Hz 进一步候选（未实施）：#31 DSI 寄存器转储 STREAM0 WC=0x279（633 bytes），COMMAND_COMPRESSION_CTRL=0x39003951；当前 panel dsc_slice_per_pkt=1，632-byte chunk、两 slices => 两 packets/line。既有 Android awake2 原始物理转储对应寄存器（Linux debug offset 比原始物理 offset 少 4）WC=0x4f1（1265 bytes），应为两 slices 合成一 packet/line。需在已有效 SDC/PPS 条件下做单变量对照；不能把旧花屏阶段封包对照未改善当作现阶段已排除。

#32 / 包 7.2.0-17 单变量封包对照失败：SDC 120 命令和原速率下 dsc_slice_per_pkt=2，寄存器 WC=0x4f1、compression=0x39003911、chunk=0x278 已读回与 Android 一致，用户报告黑屏。已切 60 Hz、撤回源码改动、降回包 7.2.0-16，并临时启动 #30；用户确认显示和动态操作正常。默认镜像、打包 payload 及缓存的 Image_w_dtb.gz/modules-7.2.tar.gz 已从 #30/包16 恢复。包重建 fakeroot 发出一次 payload warning，归档文件及安装 Image/面板模块 uid/gid 正确、pacman 校验仅发现 depmod 重生成的索引不同；未把这一警告当作打包失败忽略。#31 用户不在场，尚无显示反馈，不计为通过/失败。

USB 串口备用调试入口：已启用 serial-getty@ttyGS0，使用标准登录/PAM，不配置自动 root 登录；电脑 /dev/ttyACM0 已读到 Arch 登录提示，configure-arch.sh 同步持久启用。phone-sudo.py 新增 SSH keepalive，使失联时及时返回而非长时间挂住；语法检查及实际 SSH 调用通过。串口提供认证控制台不等于能处理全内核锁死，未作此宣称。

#31 在用户在场时复测：标准 SDC 120 Hz、1.1136 Gbps 实际速率、单切片封包均生效，用户确认整屏花屏。该对照现在计为失败，已正常重启后 fastboot boot 恢复 #30；uname、60 Hz DRM 状态、SDDM 和串口登录服务核实正常，无启动分区刷写。

#30 同步计数诊断：新增 scripts/diagnostics/display-te-readonly.py，仅以 O_RDONLY / PROT_READ 采样 INTF1 的 TE 和完成帧计数。短暂软件 Qt Quick 动画下，60/90/120 Hz 的三秒采样分别为 TE 96.663/103.324/59.331 Hz、完成帧 40.665/60.994/58.998 Hz；DRM WAIT_VBLANK 为 105.149/110.883/67.159 Hz。计数与标称模式并不相等，但 IRQ/计数可能受按需时钟、动画负载与采样窗口影响，不能将这些结果直接报告为面板物理扫描频率或根因。各模式 tearcheck 的 vsync_count 均为 56（vtotal×刷新率近似恒定），高度随模式正确变化，external TE 位开启。未写硬件寄存器；测量结束恢复 60 Hz。日志 build/kernel30-te-mode-measurement.log。120 Hz 修复仍未完成。

## 256 GiB 直接分区迁移（2026-10-01）

按用户要求移除手机 Ubuntu：先用 rsync -aHAXx 暂存完整 Arch 根文件系统，并对原 test 目录建立逐文件 SHA-256、类型、模式和符号链接目标清单。暂存及直接启动后的清单均完全相同：49,725 个条目、10,762,084,391 字节文件数据，含 20 个 GGUF 和 1,347 个 MC 区域文件。保留目录为 /home/ace3/test，/home/ubuntu/test 仅为兼容旧脚本的符号链接。Java 与原 llama.cpp 的版本命令实际执行成功；未启动 MC 服务端，未将本轮视为模型速度测试。

#33 / 包 7.2.0-18 使用已提交 Aston 内核源码及支持直接根分区的内置 initramfs。实机根挂载为 /dev/sda15（256 GiB ext4，文件系统约 252 GiB），无 loop 设备；用户确认 KDE 桌面、触摸及自动旋转正常。系统无失败服务，GPU/EXT4 未见本轮错误。全目录校验通过后删除旧 Ubuntu 文件及旧 loop 镜像，仅保留旧内核诊断日志到 /var/log/ace3-kernel-tests/legacy-looproot。卷标为 arch-aston，保留块设为 1%；清理后约使用 33 GiB、可用约 217–218 GiB。手机启动仍仅使用 fastboot boot，不刷写启动分区。

清理旧系统与镜像后再次正常重启到 bootloader，并用默认 boot-arch-aston.img 临时启动：仍为 /dev/sda15 直接根挂载、#33 / 包18、60 Hz，传感器准备和桌面服务正常，无失败服务，保留目录清单一致。确认启动不再依赖已删除的 loop 镜像或 Ubuntu 目录；根目录所有者为 root:root。
