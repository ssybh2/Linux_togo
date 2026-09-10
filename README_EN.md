# Linux To Go 🚀

> One-click Ubuntu bootstrap tool for robotics development.

Language:

- 🇨🇳 [中文](./README.md)
- 🇬🇧 **English (current page)**
- 🇰🇷 [한국어](./README_KR.md)

---

## Introduction

`Linux To Go` is an automated Ubuntu environment setup tool for robotics, ROS and AI development.

After one bootstrap step, users can configure a fresh Ubuntu machine with:

- Common development tools
- Clash Verge Rev 2.5.2
- NoMachine 9.8.3
- ROS environment detection and installation

The goal is to turn a clean Ubuntu installation into a ready-to-use robotics workstation quickly.

---

## Supported Matrix

| Ubuntu | Command | ROS |
|---|---|---|
| Ubuntu 20.04 LTS | `linux-to-go -ros1` | ROS 1 Noetic |
| Ubuntu 22.04 LTS | `linux-to-go -ros2` | ROS 2 Humble |

Supported architectures:

- amd64
- arm64

The Ubuntu and ROS versions are strictly matched.

---

## Quick Start

```bash
git clone https://github.com/ssybh2/Linux_togo.git
cd Linux_togo
sudo ./install.sh
```

Then run:

```bash
linux-to-go -ros1
```

or

```bash
linux-to-go -ros2
```

---

## Features

### Clash Verge Rev 2.5.2

- amd64 / arm64 support
- Official release download
- SHA-256 verification

### NoMachine 9.8.3

- Automatic architecture detection
- ARM64 GitHub Release package
- AMD64 official download fallback

### ROS Management

Supported:

- ROS 1 Noetic
- ROS 2 Humble

Existing ROS installations are detected and skipped automatically.

---

## Update

```bash
cd Linux_togo
git pull
sudo ./install.sh
```

For the complete Chinese documentation, see [README.md](./README.md).
