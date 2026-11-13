# 应用安装流程审查

日期：2026-11-13。目标：Ubuntu 22.04、Intel Core i5 / amd64、已安装 ROS2 Humble，仅补装 Clash Verge Rev 和 NoMachine。

## 已修正的问题

| 原问题 | 修正 |
|---|---|
| `install.sh` 没有执行权限，README 中的直接执行命令失败 | 提交可执行权限 |
| 安装后的 CLI 因 `/usr/local/lib` 存在而选错模块目录 | 检查具体模块文件，并支持安装后的模块子目录 |
| 只想安装应用，却必须进入 ROS 模式并安装开发工具 | 新增 `--apps-only`，仅补齐缺少的下载工具和应用运行依赖 |
| 缺乏只读检查入口 | 新增 `--check`，不执行安装或配置修改 |
| NoMachine 9.8.3 amd64 下载链接已经返回 HTML | 移除无效下载路径，要求可信本地 amd64 DEB，并在应用安装前检查 |
| 指定本地文件不存在时可能转而下载，搜索可能拿到错误架构的包 | 显式路径不存在即停止；自动搜索限制架构；转成绝对路径供 APT 安装 |
| 只检查架构，无法可靠拒绝错误包或 HTML | 检查 DEB 包名、架构，固定下载版本还检查版本 |
| 校验或 APT 失败可能继续输出安装成功，尤其在条件调用中 | 对关键操作显式传播失败状态，仅成功后打印完成信息 |
| NoMachine 客户端 `nxplayer` 被误当成服务端已经安装 | 按服务端包或 `nxserver` 检测 |
| 任意 ROS2 命令可能被误识别为 Humble | 命令检测须匹配 Humble；保留目标 setup 文件和软件包检测 |
| 文档声称 AMD64 官方下载、ARM64 官方回退始终可用 | 更新各语言说明，明确本地包方案与失效下载限制 |

## 下载核验

- [Clash Verge Rev 官方 v2.5.2 Release](https://github.com/clash-verge-rev/clash-verge-rev/releases/tag/v2.5.2)：核对两个架构的资产、SHA-256；仅取 amd64 包前 256 KiB 读取控制元数据，确认 `clash-verge`、`2.5.2`、`amd64` 及 GTK/WebKit 运行依赖。
- [Linux_togo NoMachine Release](https://github.com/ssybh2/Linux_togo/releases/tag/nomachine)：目前仅有 ARM64 9.8.3-1；核对资产和 SHA-256，并取前 256 KiB 检查包名、版本、架构。
- 原 NoMachine 9.8.3 amd64 官方下载地址重定向到官网 HTML，不能作为安装包来源。旧 ARM64 官方回退地址也已失效。
- 当前官网 [Personal Edition](https://download.nomachine.com/personal-edition/) 要求订阅激活或试用，未将其自动替代旧版。
- 已只读检查本机已有的 `nomachine_9.7.3_1_amd64.deb`，元数据为 `nomachine / 9.7.3-1 / amd64`，可由用户复制到新电脑作为本地输入；未上传该二进制文件。

固定下载的校验值见 [README_CN.md](../README_CN.md)。用户自行提供的未知本地版本仅做元数据检查，不代表已验证其来源或内容完整性。

## 验证范围

- 8 个 Bash 文件分别通过 `bash -n`。
- 原检测测试：36 项通过。
- 新增安装回归测试：17 项通过。使用临时 DEB、临时安装目录和模拟 APT/curl/sudo，覆盖安装后模块查找、应用完整流程、ROS 不被调用、缺失文件、错误架构/包名、HTML 响应、哈希不符、APT 失败及精简依赖等情况。
- 未执行系统软件安装，未修改本机 ROS、网络、服务或桌面会话；未进行真实 GUI 和跨电脑远程桌面连接测试。
- 本次重点为已有 Humble 时的应用安装路径，未在全新 Ubuntu 20.04/22.04 上验证 ROS 完整安装模式。

安装后的订阅导入、代理启用、NoMachine 网络可达性与桌面会话仍需在目标电脑验证。参考 [Clash 官方文档](https://www.clashverge.dev/install.html)和 [NoMachine DEB 安装文档](https://kb.nomachine.com/AR01L00775)。
