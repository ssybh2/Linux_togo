# Linux To Go

新电脑环境部署工具：图形界面检测 Ubuntu、amd64 / arm64 和已有 ROS，安装对应 ROS、Clash Verge 与 NoMachine。

## 克隆后运行

```bash
# 若没有 git：sudo apt update && sudo apt install -y git
git clone https://github.com/ssybh2/Linux_togo.git
cd Linux_togo
./setup.sh
```

以普通桌面用户运行。首次缺少窗口依赖时，程序会在终端请求 sudo 安装 `python3-tk`；随后打开部署窗口。检查界面中的检测结果、选择 ROS 和应用，再点击 **开始部署**。系统安装会请求管理员密码，并显示实时日志。

- 自动检测 ROS 1 / ROS 2，无需提前 source；已有 ROS 默认保留，已有应用跳过。
- 未检测到 ROS 时，在窗口选择 ROS 1 或 ROS 2；不兼容选项禁用并说明适用系统。
- 自动按当前系统软件包架构选择 amd64 / arm64。Intel 和 AMD 的 x86-64 CPU 都使用 amd64。
- 应用直接使用[本仓库 Releases](https://github.com/ssybh2/Linux_togo/releases)，下载后检查 SHA-256、DEB 包名、版本和架构，再由 APT 安装依赖。
- **预览安装计划** 不下载或安装软件。安装失败时保留日志，修复网络/依赖后可重试，已安装组件跳过。

## 兼容性

| Ubuntu | 可安装 ROS | Clash Verge 2.5.10 | NoMachine |
| --- | --- | --- | --- |
| 20.04 | ROS 1 Noetic（2025年5月已结束维护） | 标准源缺少 WebKit 4.1，界面禁用 | 自动匹配架构 |
| 22.04 | ROS 2 Humble | 支持 | 自动匹配架构 |
| 24.04 | ROS 2 Jazzy | 支持 | 自动匹配架构 |

支持 amd64、arm64。不会将 Noetic 软件源混入 22.04 / 24.04，也不会在 20.04 安装 Humble。其他 Linux 发行版和 Ubuntu 版本会报告不支持并停止。

Clash 为两架构 **2.5.10**；NoMachine 为 amd64 **9.7.3-1**、arm64 **9.8.3-1**，与仓库已上传资产一致。20.04 如需 Clash，应先使用有兼容构建的受支持系统；工具不会强行混用其他 Ubuntu 版本的软件源。

## 无桌面 / 命令行

```bash
./setup.sh --check                         # 只检测
./setup.sh --auto                          # 有ROS则保留，否则终端选择
./setup.sh --ros2 --dry-run                 # 预览
./setup.sh --ros2                           # 22.04 Humble / 24.04 Jazzy
./setup.sh --ros1 --skip-clash              # 20.04 Noetic + NoMachine
./setup.sh --apps-only                     # 只安装应用
./setup.sh --apps-only --skip-nomachine     # 只安装 Clash
```

不必先执行 `install.sh`。如需全局命令，可执行 `sudo ./install.sh`，再使用 `linux-to-go --gui` / `linux-to-go --check`。

## 安装完成后

Clash Verge 需自行导入订阅并选择节点；程序不提供订阅或自动更改系统代理。NoMachine 安装包会配置远程服务，服务检查：`sudo /usr/NX/bin/nxserver --status`。ROS 在新终端生效。

图形界面日志：`~/.local/state/linux-to-go/`，或 `$XDG_STATE_HOME/linux-to-go/`。下载失败、校验失败、sudo拒绝、APT依赖冲突均报告失败，不会显示部署成功。APT 禁止删除现有软件包；依赖冲突需先修复系统。

完整说明：[中文](README_CN.md) · [English](README_EN.md)。旧的[한국어](README_KR.md) / [ภาษาไทย](README_TH.md) 为历史说明，以当前中文/英文流程为准。

## 更新与测试

```bash
git pull --ff-only
./setup.sh

bash tests/test_detection.sh
python3 -m unittest discover -s tests -p 'test_*.py' -v
```

自动测试拦截 APT、网络和 sudo，使用临时 DEB，不更改本机软件环境。四个实际 Release 包及 ROS官方软件源包的校验、图形界面预览已经检查；全新系统完整安装仍需在目标机器验证。详见 [验证记录](docs/bootstrap-validation.md)。

## add terminal VPN stream from clashverge
```bash
export http_proxy="http://127.0.0.1:7897"
export https_proxy="http://127.0.0.1:7897"
export all_proxy="socks5h://127.0.0.1:7897"

export HTTP_PROXY="$http_proxy"
export HTTPS_PROXY="$https_proxy"
export ALL_PROXY="$all_proxy"
```
## Codex
download by this cmd: <br>
```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```
## Launch codex
```bash 
source ~/.bashrc 
export PATH="$HOME/.local/bin:$PATH"
```
