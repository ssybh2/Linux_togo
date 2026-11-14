# Linux To Go

Ubuntu 机器人开发环境安装工具：Clash Verge Rev、NoMachine，以及可选的 ROS 安装。

[中文详细说明](README_CN.md) · [English](README_EN.md) · [한국어](README_KR.md) · [ภาษาไทย](README_TH.md)

## 已有 ROS2 Humble：只安装两个应用

适用于 Ubuntu 22.04。Intel Core i5 / AMD x86-64 电脑使用 **amd64**，ARM 电脑使用 arm64。

**amd64 需要先准备本地 NoMachine 安装包。** 原 NoMachine 9.8.3 官方链接已失效；请将旧电脑上可信的 `nomachine_*_amd64.deb` 复制到新电脑，例如 `~/Downloads/nomachine_9.7.3_1_amd64.deb`。不要使用 ARM64 包。

```bash
# 没有 git 时先运行：sudo apt update && sudo apt install -y git
git clone https://github.com/ssybh2/Linux_togo.git ~/Linux_togo
cd ~/Linux_togo
sudo ./install.sh

# 将路径替换成实际存在的 amd64 安装包
LINUX_TO_GO_NOMACHINE_DEB="$HOME/Downloads/nomachine_9.7.3_1_amd64.deb" linux-to-go --apps-only

linux-to-go --check
sudo /usr/NX/bin/nxserver --status
```

`--apps-only` 不调用 ROS 安装流程，不修改 ROS 软件源或 `.bashrc`，不额外安装编译工具。应用自身必需的运行依赖由 APT 处理。已安装应用直接跳过。

如果 NoMachine 已安装，或使用 ARM64 设备，可直接运行：

```bash
linux-to-go --apps-only
```

安装完成后，以普通桌面用户打开 Clash Verge，导入自己的订阅并选择节点，再按需要开启代理。NoMachine 安装包通常会启动服务；另一台电脑上的 NoMachine 客户端可通过本机局域网 IP 连接，默认使用 TCP 4000 和 Ubuntu 登录账号。

## 下载与校验

- Clash Verge Rev 固定为 **2.5.2**：官方 GitHub Release，校验 SHA-256、包名、版本和架构。
- NoMachine ARM64：本仓库 Release 中的 **9.8.3-1**，校验 SHA-256 和 DEB 元数据。
- NoMachine AMD64：使用用户提供的本地 DEB，检查包名和架构；没有包时在安装任何组件前停止并提示。

当前 NoMachine 官网提供的 [Personal Edition](https://download.nomachine.com/personal-edition/) 需要订阅激活或试用，因此脚本不会自动将旧版替换为该产品。详细步骤与校验值见[安装说明](README_CN.md)。

## 包含 ROS 的安装模式

| 系统 | 命令 | 目标 |
|---|---|---|
| Ubuntu 20.04 | `linux-to-go -ros1` | ROS 1 Noetic |
| Ubuntu 22.04 | `linux-to-go -ros2` | ROS 2 Humble |

两种模式也会安装应用，AMD64 同样需要提前提供 NoMachine DEB。已有 Humble 的电脑优先使用 `--apps-only`。本次修正重点为应用安装流程，未在全新系统验证上述 ROS 完整安装模式。

## 更新

```bash
cd ~/Linux_togo
git pull --ff-only
sudo ./install.sh
linux-to-go --check
```

更新脚本后，按需要重新执行 `--apps-only`。已安装应用不会自动升级。

## 测试

```bash
for script in install.sh bin/linux-to-go lib/*.sh tests/*.sh; do
  bash -n "$script" || break
done
bash tests/test_detection.sh
python3 -m unittest discover -s tests -p 'test_*.py' -v
```

测试使用临时 DEB 和模拟 APT/网络命令，不安装系统软件。[审查记录](docs/install-audit.md)。
## add terminal VPN stream from clashverge
export http_proxy="http://127.0.0.1:7897"
export https_proxy="http://127.0.0.1:7897"
export all_proxy="socks5h://127.0.0.1:7897"

export HTTP_PROXY="$http_proxy"
export HTTPS_PROXY="$https_proxy"
export ALL_PROXY="$all_proxy"

