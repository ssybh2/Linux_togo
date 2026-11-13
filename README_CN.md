# Linux To Go：安装说明

[首页与安装命令](README.md) · [English](README_EN.md)

## 选择模式

支持 Ubuntu 20.04 / 22.04 的 amd64、arm64 设备。Intel Core i5 的 Dell 电脑属于 amd64，可用 `dpkg --print-architecture` 确认。

| 场景 | 命令 |
|---|---|
| 已有 ROS，只安装 Clash Verge 和 NoMachine | `linux-to-go --apps-only` |
| 只检查现状，不安装软件 | `linux-to-go --check` |
| Ubuntu 20.04，需要安装 ROS 1 Noetic | `linux-to-go -ros1` |
| Ubuntu 22.04，需要安装 ROS 2 Humble | `linux-to-go -ros2` |

`sudo ./install.sh` 将入口安装到 `/usr/local/bin/linux-to-go`，模块安装到 `/usr/local/lib/linux-to-go/`。之后使用普通登录用户运行命令，需要安装系统包时会调用 sudo。

## 已有 Humble 的 Intel / AMD 电脑

原 NoMachine 9.8.3 amd64 官方地址已返回网页，不能继续当作 DEB 安装。本仓库 Release 目前仅有 ARM64 包。

请将旧电脑上已获得的可信 `nomachine_*_amd64.deb` 复制到新电脑。如果文件是 `nomachine_9.7.3_1_amd64.deb`，可执行：

```bash
dpkg-deb -f "$HOME/Downloads/nomachine_9.7.3_1_amd64.deb" Package Version Architecture
# 应显示 nomachine、9.7.3-1、amd64

LINUX_TO_GO_NOMACHINE_DEB="$HOME/Downloads/nomachine_9.7.3_1_amd64.deb" linux-to-go --apps-only
linux-to-go --check
sudo /usr/NX/bin/nxserver --status
```

路径必须指向实际文件，也可以使用其他已获得的可信 NoMachine amd64 版本。明确指定不存在的文件、错误包名或错误架构时，脚本停止，不回退到其他下载。未知本地版本没有内置 SHA-256，元数据检查不能代替来源可信性验证。

NoMachine 已安装时无需指定安装包。仓库内直接运行 `./bin/linux-to-go --apps-only` 时，也会查找 `packages/` 中匹配架构的包；安装后的全局命令请使用上面的显式路径。

`--apps-only` 仅补齐缺少的 `ca-certificates`、`curl`，再安装应用及必需运行依赖，不额外安装 `build-essential` 等编译工具，也不调用 ROS 安装、ROS 软件源配置或 shell 环境修改流程。APT 仍可能安装或升级应用所需的共享运行库。

## Clash Verge Rev

固定安装[官方 Release v2.5.2](https://github.com/clash-verge-rev/clash-verge-rev/releases/tag/v2.5.2)：

| 架构 | 文件 | SHA-256 |
|---|---|---|
| amd64 | `Clash.Verge_2.5.2_amd64.deb` | `035c83ed14b16df1dd397e5d710b34bedd5d27beb6678549ceaeeadf9bc167ed` |
| arm64 | `Clash.Verge_2.5.2_arm64.deb` | `598a5a852d7bf9dc40a976780ef2afc9a4e5bfe7b99533e5f956f9e2f9def72f` |

脚本校验下载内容的 SHA-256、DEB 包名 `clash-verge`、版本和架构，然后通过 APT 安装运行依赖。不会编译 Clash 源码。

安装后从应用菜单以普通用户启动，导入自己的订阅、选择节点，再按需要开启系统代理或 TUN。安装工具不提供订阅，不自动更改系统代理、路由或防火墙。详见[官方安装文档](https://www.clashverge.dev/install.html)。

## NoMachine ARM64

ARM64 自动使用[本仓库 Release](https://github.com/ssybh2/Linux_togo/releases/tag/nomachine)：

```text
文件：nomachine_9.8.3_1_arm64.deb
Package: nomachine
Version: 9.8.3-1
Architecture: arm64
SHA-256: be874820b9539e836d44fdfb2311a588253bd192e0e43393d819251e42a057ad
```

下载失败会停止并提示提供本地包，已移除失效的官方回退地址。不会自动换装需要激活的新版 [NoMachine Personal Edition](https://download.nomachine.com/personal-edition/)。

## NoMachine 连接检查

```bash
sudo /usr/NX/bin/nxserver --status
hostname -I
```

安装包通常自动启动服务。另一台电脑安装 NoMachine 客户端，在相同局域网内用这里的 IP、默认 TCP 4000、目标 Ubuntu 的用户名和密码连接。服务状态正常后再排查网络可达性和桌面会话。脚本不自动修改防火墙或切换 Wayland/Xorg。

参考：[官方 Linux DEB 安装说明](https://kb.nomachine.com/AR01L00775)。

## ROS 与更新

已有 Humble 时推荐使用 `--apps-only`，即使当前终端没有 source ROS 也可使用。

保留的 `-ros1` / `-ros2` 模式会检测目标 ROS，已存在则跳过；不存在时安装对应 desktop 与开发工具，并配置 `.bashrc`。本次未在全新系统执行完整 ROS 安装验证；全新 ROS 环境请同时参考 [ROS Humble 官方文档](https://docs.ros.org/en/humble/Installation/Ubuntu-Install-Debs.html)。

更新方法见[首页](README.md#更新)。已安装应用会跳过，更新脚本不等于升级应用。APT 被占用时等待其他安装任务完成，不删除 lock 文件。

测试方法与范围见[首页](README.md#测试)和[审查记录](docs/install-audit.md)。
