# Linux To Go 图形部署说明

入口：[README](README.md)。在普通用户终端执行 `./setup.sh` 即可，不必先安装本工具到系统目录。

## 窗口流程

1. 自动识别 Ubuntu 版本与 `dpkg --print-architecture`，仅接受 amd64 / arm64。
2. 检测 `/opt/ros`、已安装 ROS 包、当前 source 的 ROS。已有 ROS 默认选择保留。
3. 未安装 ROS 时，选择兼容版本：20.04→Noetic；22.04→Humble；24.04→Jazzy。不兼容项禁用。
4. 勾选 Clash Verge、NoMachine，预览计划或开始部署。缺少 Tk 时终端先安装窗口依赖。
5. 输入一次 sudo 密码（sudo可能在密码错误时重试），执行日志持续显示。密码由独立窗口直接交给 sudo，不写入日志。
6. 完成后重新检测；失败时显示退出码和日志路径，可修复后重试。安装中不关闭窗口，以免中断 APT。

## Release 安装包

| 应用 | 架构 | Release tag | 文件 |
| --- | --- | --- | --- |
| Clash Verge | amd64 | x64clash | Clash.Verge_2.5.10_amd64.deb |
| Clash Verge | arm64 | arm64clash | Clash.Verge_2.5.10_arm64.deb |
| NoMachine | amd64 | amd64 | nomachine_9.7.3_1_amd64.deb |
| NoMachine | arm64 | nomachine | nomachine_9.8.3_1_arm64.deb |

SHA-256 固定在 `lib/clash-verge.sh`、`lib/nomachine.sh`，与 GitHub 资产 digest 及实下载一致。不会盲目选择最新 Release（本仓库各架构使用不同 tag）。发布新包后必须同步文件名、版本和校验值。`packages/` 或 `LINUX_TO_GO_NOMACHINE_DEB` 仍可提供可信本地 NoMachine 包；未知版本本地包仅检查包名/架构，来源由提供者保证。

## 系统限制

Clash 2.5.10 需要 `libwebkit2gtk-4.1-0`，20.04标准源不能满足，界面禁用；命令行需 `--skip-clash`。ROS1 Noetic 已于2025年5月结束维护。不会用不匹配的软件源安装，22.04/24.04需要ROS1时本工具不提供源码或容器安装。

ROS 使用官方 `ros-infrastructure/ros-apt-source` 1.3.0 的软件源与密钥管理包；对应 focal/jammy/noble 包均校验哈希。安装 desktop 和开发工具，初始化 rosdep，成功后追加用户 `.bashrc` 一次。采用 `--no-remove` 阻止 APT 删除系统软件；系统源、网络或依赖异常会停止。不会自动升级整个操作系统。

Clash 需要已有网络才能下载安装，安装器不会自动提供代理订阅。首次使用时自行导入订阅、选择节点。NoMachine安装包会启动服务；连接使用目标系统账号与局域网IP，默认TCP4000。程序不改防火墙、路由或桌面协议。

## 检查和日志

```bash
./setup.sh --check
./setup.sh --ros2 --dry-run
./setup.sh --apps-only
sudo /usr/NX/bin/nxserver --status
```

图形界面：`~/.local/state/linux-to-go/*.log`（尊重 XDG_STATE_HOME）；终端模式输出可自行重定向。程序不删除 APT lock，等待锁最多120秒。网络错误、哈希错误、错误架构、安装失败均不会报成功。已装组件跳过，因此重跑不等于升级软件。

官方参考：[Humble](https://docs.ros.org/en/humble/Installation/Ubuntu-Install-Debs.html)、[Jazzy](https://docs.ros.org/en/jazzy/Installation/Ubuntu-Install-Debs.html)、[ROS软件源管理](https://github.com/ros-infrastructure/ros-apt-source)、[NoMachine DEB](https://kb.nomachine.com/AR01L00775)。
