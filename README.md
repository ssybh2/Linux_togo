# Linux To Go 🚀

> **Ubuntu 机器人开发环境一键部署工具**

语言切换：

- 🇨🇳 **中文（当前页面）**
- 🇬🇧 [English](./README_EN.md)
- 🇰🇷 [한국어](./README_KR.md)

---

## 项目简介

`Linux To Go` 是一个面向机器人、ROS 和 AI 开发者的 Ubuntu 自动化环境配置工具。

只需要一次初始化，即可通过一条命令自动完成：

- 基础开发环境安装
- Clash Verge Rev 2.5.2 安装
- NoMachine 9.8.3 远程桌面安装
- ROS 环境检测与安装

设计目标：让新的 Ubuntu 设备可以快速变成可用于机器人开发的工作站。

---

## 支持环境

| Ubuntu | 命令 | ROS版本 |
|---|---|---|
| Ubuntu 20.04 LTS | `linux-to-go -ros1` | ROS 1 Noetic |
| Ubuntu 22.04 LTS | `linux-to-go -ros2` | ROS 2 Humble |

支持架构：

- amd64
- arm64

工具会严格检查 Ubuntu 与 ROS 匹配关系：

- Ubuntu 20.04 → ROS 1 Noetic
- Ubuntu 22.04 → ROS 2 Humble

不支持组合会在安装前自动阻止。

---

## 快速开始

```bash
git clone https://github.com/ssybh2/Linux_togo.git
cd Linux_togo
sudo ./install.sh
```

安装完成后：

Ubuntu 20.04:

```bash
linux-to-go -ros1
```

Ubuntu 22.04:

```bash
linux-to-go -ros2
```

---

## 自动执行流程

```text
linux-to-go
    |
    +-- 检测 Ubuntu 版本
    +-- 检测 CPU 架构
    +-- 检查 ROS 是否已经安装
    +-- 安装 Clash Verge Rev 2.5.2
    +-- 安装 NoMachine 9.8.3
    +-- 安装 ROS Noetic / Humble
    +-- 自动配置开发环境
```

所有模块均采用幂等设计：

已经安装的软件会自动检测并跳过，不会重复安装。

---

## 主要功能

### 🌐 Clash Verge Rev 2.5.2

- 支持 amd64 / arm64
- 官方 Release 下载
- SHA-256 校验

### 🖥 NoMachine 9.8.3

- ARM64 使用 Linux_togo Release 自动下载
- AMD64 使用官方源
- 自动检测架构

### 🤖 ROS 自动管理

支持：

- ROS 1 Noetic
- ROS 2 Humble

安装前自动检测已有 ROS：

```text
已安装 → SKIP
未安装 → 自动安装
```

---

## 仓库结构

```text
Linux_togo/
├── install.sh
├── bin/linux-to-go
├── lib/
│   ├── common.sh
│   ├── system.sh
│   ├── clash-verge.sh
│   ├── nomachine.sh
│   └── ros.sh
├── packages/
└── tests/
```

---

## 更新

```bash
cd Linux_togo
git pull
sudo ./install.sh
```

---

## English / 한국어

完整英文说明：

[README_EN.md](./README_EN.md)

한국어 문서:

[README_KR.md](./README_KR.md)
