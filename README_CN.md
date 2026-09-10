# Linux To Go

[English](./README.md)

`Linux To Go` 用于把一台刚安装好的 Ubuntu 电脑快速配置成机器人开发环境。完成一次 bootstrap 后，用户只需要一条命令，就可以自动处理基础工具、**Clash Verge Rev 2.5.2**、**NoMachine 9.8.3** 和对应的 ROS 环境。

## 支持关系

| Ubuntu | 命令 | ROS 目标 |
|---|---|---|
| **Ubuntu 20.04 LTS** | `linux-to-go -ros1` | **ROS 1 Noetic** |
| **Ubuntu 22.04 LTS** | `linux-to-go -ros2` | **ROS 2 Humble** |

当前支持 **amd64** 和 **arm64**。

版本关系采用严格匹配：Ubuntu 22.04 执行 `-ros1`，或 Ubuntu 20.04 执行 `-ros2`，都会在开始安装软件之前直接停止并提示正确命令。

## 一分钟开始

```bash
git clone https://github.com/ssybh2/Linux_togo.git
cd Linux_togo
sudo ./install.sh
```

之后使用普通登录用户运行：

```bash
# Ubuntu 20.04
linux-to-go -ros1

# Ubuntu 22.04
linux-to-go -ros2
```

同时支持：

```bash
linux-to-go --ros1
linux-to-go --ros2
```

## 一条命令会完成什么

```text
linux-to-go -ros1 / -ros2
        |
        +-- 检测 Ubuntu 版本与 CPU 架构
        +-- 检查 Ubuntu / ROS 是否匹配
        +-- 安装缺少的基础工具
        +-- 检查并安装 Clash Verge Rev 2.5.2
        +-- 检查并安装 NoMachine 9.8.3
        |     +-- 已安装 -> SKIP
        |     +-- arm64 -> 本仓库 GitHub Release -> SHA-256 -> apt 安装
        |     +-- amd64 -> NoMachine 官方源 -> apt 安装
        |     +-- ARM64 Release 下载失败 -> 回退 NoMachine 官方源
        +-- 只检查命令指定的 ROS 家族
              +-- 已安装 -> SKIP
              +-- 未安装 -> 安装 Noetic 或 Humble
```

整个安装流程按照幂等方式设计：已经存在的组件会跳过，不会主动重复安装。

## Clash Verge Rev 2.5.2

Linux To Go 固定使用 **Clash Verge Rev v2.5.2**，从 Clash Verge Rev 官方 GitHub Release 下载。

| 架构 | 安装包 | SHA-256 |
|---|---|---|
| amd64 | [Clash.Verge_2.5.2_amd64.deb](https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.5.2/Clash.Verge_2.5.2_amd64.deb) | `035c83ed14b16df1dd397e5d710b34bedd5d27beb6678549ceaeeadf9bc167ed` |
| arm64 | [Clash.Verge_2.5.2_arm64.deb](https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.5.2/Clash.Verge_2.5.2_arm64.deb) | `598a5a852d7bf9dc40a976780ef2afc9a4e5bfe7b99533e5f956f9e2f9def72f` |

下载后会先校验 SHA-256，再执行安装。

## NoMachine 9.8.3

NoMachine 已经正式封装进 **`linux-to-go -ros1` 和 `linux-to-go -ros2`** 两条流程。

### ARM64：自动从本仓库 Release 下载

本仓库 Release 中已经有：

| 架构 | 安装包 | SHA-256 |
|---|---|---|
| arm64 | [nomachine_9.8.3_1_arm64.deb](https://github.com/ssybh2/Linux_togo/releases/download/nomachine/nomachine_9.8.3_1_arm64.deb) | `be874820b9539e836d44fdfb2311a588253bd192e0e43393d819251e42a057ad` |

Release 页面：<https://github.com/ssybh2/Linux_togo/releases/tag/nomachine>

ARM64 设备正常执行 `linux-to-go` 时**不需要手动下载**。如果系统中没有 NoMachine，脚本会自动执行：

```text
Linux_togo GitHub Release
    -> 下载 nomachine_9.8.3_1_arm64.deb
    -> 校验 SHA-256
    -> 检查 DEB Architecture=arm64
    -> sudo apt-get install
```

如果本仓库 Release 暂时下载失败，会自动回退到配置好的 NoMachine 官方 ARM64 下载地址。

如果希望手动安装，也可以：

```bash
wget https://github.com/ssybh2/Linux_togo/releases/download/nomachine/nomachine_9.8.3_1_arm64.deb
sudo apt install ./nomachine_9.8.3_1_arm64.deb
```

### AMD64

目前 `Linux_togo` 自己的 Release 里只有 ARM64 包。因此普通 Intel / AMD x86-64 电脑运行 `linux-to-go` 时，会继续从 NoMachine 配置的官方下载服务获取 `nomachine_9.8.3_1_amd64.deb`。

### 本地安装包覆盖

如果需要，仍然可以指定本地 NoMachine DEB：

```bash
LINUX_TO_GO_NOMACHINE_DEB=/绝对路径/nomachine_9.8.3_1_arm64.deb \
  linux-to-go -ros2
```

安装前脚本会用 `dpkg-deb` 检查软件包架构，避免把 ARM64 包安装到 amd64 电脑上。

## ROS：先检测，没装才安装

工具不会无条件重新安装 ROS。

执行 `linux-to-go -ros1` 时，只检查 **ROS 1**。已经安装 ROS 1 就直接跳过；没有安装时，在 Ubuntu 20.04 上安装 **ROS Noetic**。

执行 `linux-to-go -ros2` 时，只检查 **ROS 2**。已经安装 ROS 2 就直接跳过；没有安装时，在 Ubuntu 22.04 上安装 **ROS 2 Humble**。

检测不仅依赖当前终端有没有 `source` ROS，还会检查 `/opt/ros`、ROS 命令和 Debian 软件包状态，因此新终端也能识别已有 ROS。

### Ubuntu 20.04 / ROS 1 Noetic

```bash
linux-to-go -ros1
```

ROS 1 不存在时，脚本安装 Noetic desktop 与常用开发工具，必要时初始化 `rosdep`，并且只向登录用户的 `~/.bashrc` 添加一次：

```bash
source /opt/ros/noetic/setup.bash
```

### Ubuntu 22.04 / ROS 2 Humble

```bash
linux-to-go -ros2
```

ROS 2 不存在时，脚本安装 `ros-humble-desktop`、`ros-dev-tools`，必要时初始化 `rosdep`，并且只向 `~/.bashrc` 添加一次：

```bash
source /opt/ros/humble/setup.bash
```

## 仓库结构

```text
Linux_togo/
├── README.md
├── README_CN.md
├── install.sh
├── bin/linux-to-go
├── lib/
│   ├── common.sh
│   ├── system.sh
│   ├── clash-verge.sh
│   ├── nomachine.sh
│   └── ros.sh
├── packages/
├── tests/test_detection.sh
└── docs/
```

`sudo ./install.sh` 会把命令安装到 `/usr/local/bin/linux-to-go`，运行模块放到 `/usr/local/lib/linux-to-go/`。

## 更新 Linux To Go

```bash
cd Linux_togo
git pull
sudo ./install.sh
```

然后重新运行对应的 `-ros1` 或 `-ros2`。已经存在的软件会按照检测结果跳过。

## 常见问题

如果提示 `linux-to-go: command not found`，重新执行 `sudo ./install.sh`，然后检查：

```bash
command -v linux-to-go
```

如果 Ubuntu / ROS 参数不匹配，请按照本文最上方的版本表选择命令，不建议强行绕过。

如果 APT 被锁定，请等待其他 `apt` / `dpkg` 操作正常结束，不要手动删除 lock 文件。

查看本地 NoMachine 包架构：

```bash
dpkg-deb -f /path/to/nomachine.deb Package Version Architecture
```

## 开发与测试

```bash
bash -n install.sh bin/linux-to-go lib/*.sh tests/test_detection.sh
bash tests/test_detection.sh
```

测试覆盖 Ubuntu / ROS 严格匹配、已有 ROS 时跳过安装、amd64 / arm64 架构选择、Clash Verge 包与校验值，以及 **NoMachine ARM64 从 Linux_togo Release 自动下载并保留官方回退地址**的逻辑。
