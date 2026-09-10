# Linux To Go

[English](./README.md)

`Linux To Go` 的目标是把一台刚安装好的 Ubuntu 电脑快速配置成可用的机器人开发环境。执行一次命令后，它会自动处理基础工具、**Clash Verge Rev 2.5.2**、**NoMachine 9.8.3**，以及命令中指定的 ROS 环境。

第一版刻意采用严格的 Ubuntu / ROS 对应关系，避免新电脑因为错误版本组合而把系统环境配乱。

| Ubuntu | 命令 | ROS 目标 |
|---|---|---|
| **Ubuntu 20.04 LTS** | `linux-to-go -ros1` | **ROS 1 Noetic** |
| **Ubuntu 22.04 LTS** | `linux-to-go -ros2` | **ROS 2 Humble** |

当前支持 **amd64** 和 **arm64** 两种 CPU 架构。

> 在 Ubuntu 22.04 上执行 `-ros1`，或者在 Ubuntu 20.04 上执行 `-ros2`，程序会直接停止并提示正确用法。第一版不会通过 Docker、源码编译 ROS 或自动升级系统来绕过这个兼容规则。

---

## 一分钟快速开始

先克隆仓库并安装一次 `linux-to-go` 命令：

```bash
git clone https://github.com/ssybh2/Linux_togo.git
cd Linux_togo
sudo ./install.sh
```

之后建议使用**普通登录用户**运行 `linux-to-go`；真正需要修改系统的位置，脚本会自行调用 `sudo`。

Ubuntu 20.04：

```bash
linux-to-go -ros1
```

Ubuntu 22.04：

```bash
linux-to-go -ros2
```

同时支持长参数：

```bash
linux-to-go --ros1
linux-to-go --ros2
```

查看帮助：

```bash
linux-to-go --help
```

---

## 一条命令具体会做什么

执行顺序固定为：

```text
1. 检测 Ubuntu 版本和 CPU 架构
2. 在修改系统之前检查 Ubuntu / ROS 是否严格匹配
3. 安装必要的基础工具
4. 检查 Clash Verge Rev；没有安装才安装 2.5.2
5. 检查 NoMachine；没有安装才安装 9.8.3
6. 只检查本次命令指定的 ROS 家族
   ├── 已经安装 -> 跳过 ROS 安装
   └── 尚未安装 -> 安装 Noetic 或 Humble
7. 只向 ~/.bashrc 添加一次对应的 ROS 环境加载命令
```

典型输出类似：

```text
[INFO] Ubuntu 22.04 detected
[INFO] Architecture: amd64
[INFO] Requested target: humble
[CHECK] Clash Verge Rev
[SKIP] Clash Verge Rev installation
[CHECK] NoMachine
[SKIP] NoMachine installation
[CHECK] ROS 2
[OK] ROS 2 humble already installed
[SKIP] ROS 2 installation
[OK] Linux To Go completed
```

### ROS 会先检测，再决定是否安装

这是本工具的核心行为之一：

- `linux-to-go -ros1` **只判断 ROS 1 是否已安装**。
- `linux-to-go -ros2` **只判断 ROS 2 是否已安装**。
- 已经有 ROS 1 并不代表 ROS 2 已安装，反过来也一样。
- 如果目标 ROS 已存在，就直接显示 `[SKIP]`，不会重复安装。

检测并不只看当前终端有没有 `source` ROS。程序还会检查 `/opt/ros` 下的标准安装目录、可用的 ROS 命令和对应 Debian 软件包，因此即使刚打开的新终端尚未加载 `setup.bash`，也能识别已经安装的 ROS。

---

## Clash Verge Rev 2.5.2

当前版本固定使用 **Clash Verge Rev v2.5.2**，直接从项目官方 GitHub Release 下载。

Linux 官方 DEB：

| 架构 | 安装包 | SHA-256 |
|---|---|---|
| amd64 | [Clash.Verge_2.5.2_amd64.deb](https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.5.2/Clash.Verge_2.5.2_amd64.deb) | `035c83ed14b16df1dd397e5d710b34bedd5d27beb6678549ceaeeadf9bc167ed` |
| arm64 | [Clash.Verge_2.5.2_arm64.deb](https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.5.2/Clash.Verge_2.5.2_arm64.deb) | `598a5a852d7bf9dc40a976780ef2afc9a4e5bfe7b99533e5f956f9e2f9def72f` |

官方 Release 页面：<https://github.com/clash-verge-rev/clash-verge-rev/releases/tag/v2.5.2>

脚本在安装之前会对下载的 DEB 计算 SHA-256，并与官方 Release 中的摘要进行比对。

---

## NoMachine 9.8.3

Linux To Go 固定目标为 **NoMachine 9.8.3**。如果本机没有 NoMachine，程序会根据 CPU 架构选择对应 DEB，并从 NoMachine 官方下载服务获取安装包。

预期包名：

```text
amd64: nomachine_9.8.3_1_amd64.deb
arm64: nomachine_9.8.3_1_arm64.deb
```

开发本工具时提供的 ARM64 NoMachine 包已经实际校验：

```text
Package:      nomachine
Version:      9.8.3-1
Architecture: arm64
SHA-256:      be874820b9539e836d44fdfb2311a588253bd192e0e43393d819251e42a057ad
```

NoMachine 官方于 2026 年 9 月 4 日发布 9.8.3。官方更新说明：<https://kb.nomachine.com/SU09X00285>

### 为什么 GitHub 仓库里没有直接存 NoMachine DEB

NoMachine 的最终用户许可协议限制未经书面授权的软件再分发。因此，本公开仓库保存的是**自动安装逻辑，而不是把 NoMachine 二进制重新发布一份**。实际安装时由用户设备直接从 NoMachine 官方服务下载。

官方许可信息：<https://www.nomachine.com/licensing>

这样仍然保持了一键安装体验，同时不会把受再分发限制的软件包作为本仓库附件公开提供。

### 使用你自己已有的 NoMachine 安装包

如果本地已经有合法取得的 `.deb`，可以直接指定：

```bash
LINUX_TO_GO_NOMACHINE_DEB=/绝对路径/nomachine_9.8.3_1_arm64.deb \
  linux-to-go -ros2
```

脚本会调用 `dpkg-deb` 读取软件包元数据。如果包的 `Architecture` 与电脑架构不一致，会拒绝安装。

如果直接在仓库目录运行 CLI，也可以把自己的安装包放进 `packages/`。该目录通过 `.gitignore` 排除了 `.deb`，防止不小心提交到公开仓库。

详细说明见 [`packages/README.md`](./packages/README.md)。

---

## Ubuntu 20.04：自动配置 ROS 1 Noetic

执行：

```bash
linux-to-go -ros1
```

程序先检测 ROS 1。如果已经存在，直接跳过。如果没有，则配置 ROS 软件源并安装：

```text
ros-noetic-desktop-full
python3-rosdep
python3-rosinstall
python3-rosinstall-generator
python3-wstool
build-essential
```

必要时还会初始化 `rosdep`，并且只向当前登录用户的 `~/.bashrc` 添加一次：

```bash
source /opt/ros/noetic/setup.bash
```

安装结束后重新打开终端，或者立即执行：

```bash
source /opt/ros/noetic/setup.bash
```

---

## Ubuntu 22.04：自动配置 ROS 2 Humble

执行：

```bash
linux-to-go -ros2
```

程序先检测 ROS 2。如果已经存在，直接跳过。如果没有，则配置 ROS 2 软件源并安装：

```text
ros-humble-desktop
ros-dev-tools
python3-rosdep
```

必要时会初始化 `rosdep`，并且只向当前登录用户的 `~/.bashrc` 添加一次：

```bash
source /opt/ros/humble/setup.bash
```

安装结束后重新打开终端，或者立即执行：

```bash
source /opt/ros/humble/setup.bash
```

---

## 自动安装的基础工具

脚本首先准备一个尽量小的基础集合：

```text
ca-certificates
curl
wget
gnupg
lsb-release
software-properties-common
build-essential
git
```

APT 本身具有幂等性，已经存在的软件包不会因为再次执行 Linux To Go 就被无意义地重新替换。

---

## 仓库结构

```text
Linux_togo/
├── README.md
├── README_CN.md
├── install.sh
├── bin/
│   └── linux-to-go
├── lib/
│   ├── common.sh
│   ├── system.sh
│   ├── clash-verge.sh
│   ├── nomachine.sh
│   └── ros.sh
├── packages/
│   ├── .gitignore
│   └── README.md
├── tests/
│   └── test_detection.sh
└── docs/
    └── superpowers/
        ├── specs/
        └── plans/
```

执行 `install.sh` 后运行文件位于：

```text
/usr/local/bin/linux-to-go
/usr/local/lib/linux-to-go/
```

---

## 常见问题

### `linux-to-go: command not found`

回到仓库根目录重新执行：

```bash
sudo ./install.sh
```

然后检查：

```bash
command -v linux-to-go
```

正常应显示：

```text
/usr/local/bin/linux-to-go
```

### Ubuntu 与 ROS 参数不匹配

例如：

```text
[ERROR] ROS 1 Noetic is supported by Linux To Go on Ubuntu 20.04 only.
```

按照本文开头的兼容表选择正确命令即可。这个错误是主动保护机制，而不是安装故障。

### APT 被锁定

如果另一项 `apt` / `dpkg` 操作正在执行，请让它正常结束后再重试。**不要手动删除 APT lock 文件。**

### 本地 NoMachine 包架构不匹配

可以先检查：

```bash
dpkg-deb -f /path/to/nomachine.deb Package Version Architecture
```

amd64 电脑使用 amd64 包；arm64 电脑使用 arm64 包。

### ROS 已安装，但当前终端找不到命令

重新打开终端，或者手动加载：

```bash
# Ubuntu 20.04 / ROS 1
source /opt/ros/noetic/setup.bash

# Ubuntu 22.04 / ROS 2
source /opt/ros/humble/setup.bash
```

---

## 更新 Linux To Go

由于 `/usr/local` 中是仓库脚本的安装副本，更新后重新执行一次 bootstrap：

```bash
cd Linux_togo
git pull
sudo ./install.sh
```

然后重新运行相应的 `-ros1` 或 `-ros2` 即可。已经存在的组件会按检测结果跳过。

---

## 只卸载 Linux To Go 工具

下面两条命令**只删除 Linux To Go 本身**，不会卸载 ROS、Clash Verge Rev 或 NoMachine：

```bash
sudo rm -f /usr/local/bin/linux-to-go
sudo rm -rf /usr/local/lib/linux-to-go
```

---

## 开发与测试

测试使用环境变量和临时目录模拟不同 Ubuntu / ROS 状态，不会真的在测试机器上安装 ROS 或桌面软件。

Shell 语法检查：

```bash
bash -n install.sh bin/linux-to-go lib/*.sh tests/test_detection.sh
```

运行行为测试：

```bash
bash tests/test_detection.sh
```

测试覆盖 Ubuntu / ROS 严格对应关系、目标 ROS 已安装时跳过、amd64 / arm64 选择、Clash Verge 下载信息与校验值、NoMachine 包选择，以及 CLI 参数行为。

---

## 安全说明

Linux To Go 只通过 HTTPS 从对应软件的上游服务获取安装内容。Clash Verge Rev 2.5.2 的 amd64 和 arm64 包都会执行 SHA-256 校验；开发时提供的 NoMachine 9.8.3 ARM64 包摘要也已经固定用于额外完整性验证。临时下载文件使用 `mktemp` 创建并在安装后清理。

建议在重要生产设备上使用前先阅读一遍脚本；对于本文档未声明支持的 Ubuntu 版本，不要强行绕过版本检查。
