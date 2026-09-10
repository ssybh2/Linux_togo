# Linux To Go

[中文说明](./README_CN.md)

`Linux To Go` is a repeatable Ubuntu bootstrap tool for robotics development. After one bootstrap step, a user can run a single command to install the common environment, **Clash Verge Rev 2.5.2**, **NoMachine 9.8.3**, and the requested ROS distribution.

## Supported matrix

| Ubuntu | Command | ROS target |
|---|---|---|
| **20.04 LTS** | `linux-to-go -ros1` | **ROS 1 Noetic** |
| **22.04 LTS** | `linux-to-go -ros2` | **ROS 2 Humble** |

Supported CPU architectures: **amd64** and **arm64**.

The mapping is intentionally strict. `-ros1` on Ubuntu 22.04 and `-ros2` on Ubuntu 20.04 are rejected before package installation starts.

## Quick start

```bash
git clone https://github.com/ssybh2/Linux_togo.git
cd Linux_togo
sudo ./install.sh
```

Then run the command as the normal login user:

```bash
# Ubuntu 20.04
linux-to-go -ros1

# Ubuntu 22.04
linux-to-go -ros2
```

Long aliases are also supported:

```bash
linux-to-go --ros1
linux-to-go --ros2
```

## What the command does

```text
linux-to-go -ros1 / -ros2
        |
        +-- Detect Ubuntu version and CPU architecture
        +-- Validate the Ubuntu/ROS combination
        +-- Install common bootstrap packages if required
        +-- Check/install Clash Verge Rev 2.5.2
        +-- Check/install NoMachine 9.8.3
        |     +-- already installed -> SKIP
        |     +-- arm64 -> Linux_togo GitHub Release -> SHA-256 -> apt install
        |     +-- amd64 -> official NoMachine source -> apt install
        |     +-- ARM64 Release download failure -> official NoMachine fallback
        +-- Check only the requested ROS family
              +-- already installed -> SKIP
              +-- missing -> install Noetic or Humble
```

The installers are designed to be idempotent: already-installed components are detected and skipped instead of intentionally reinstalling them.

## Clash Verge Rev 2.5.2

Linux To Go pins Clash Verge Rev to **v2.5.2** and uses the project's official GitHub Release.

| Architecture | Package | SHA-256 |
|---|---|---|
| amd64 | [Clash.Verge_2.5.2_amd64.deb](https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.5.2/Clash.Verge_2.5.2_amd64.deb) | `035c83ed14b16df1dd397e5d710b34bedd5d27beb6678549ceaeeadf9bc167ed` |
| arm64 | [Clash.Verge_2.5.2_arm64.deb](https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.5.2/Clash.Verge_2.5.2_arm64.deb) | `598a5a852d7bf9dc40a976780ef2afc9a4e5bfe7b99533e5f956f9e2f9def72f` |

Both supported packages are SHA-256 verified before installation.

## NoMachine 9.8.3

NoMachine installation is now part of **both** `linux-to-go -ros1` and `linux-to-go -ros2`.

### ARM64: automatic download from this repository

The repository Release contains:

| Architecture | Package | SHA-256 |
|---|---|---|
| arm64 | [nomachine_9.8.3_1_arm64.deb](https://github.com/ssybh2/Linux_togo/releases/download/nomachine/nomachine_9.8.3_1_arm64.deb) | `be874820b9539e836d44fdfb2311a588253bd192e0e43393d819251e42a057ad` |

Release page: <https://github.com/ssybh2/Linux_togo/releases/tag/nomachine>

On an ARM64 machine, no manual download is required. If NoMachine is absent, Linux To Go automatically:

```text
GitHub Release
    -> download nomachine_9.8.3_1_arm64.deb
    -> verify SHA-256
    -> verify DEB Architecture=arm64
    -> sudo apt-get install
```

If the repository Release cannot be downloaded, the installer falls back to the configured official NoMachine ARM64 endpoint.

Manual installation is still possible:

```bash
wget https://github.com/ssybh2/Linux_togo/releases/download/nomachine/nomachine_9.8.3_1_arm64.deb
sudo apt install ./nomachine_9.8.3_1_arm64.deb
```

### AMD64

The current Linux_togo Release contains only the ARM64 package. On Intel/AMD x86-64 machines, Linux To Go therefore continues to download the matching `nomachine_9.8.3_1_amd64.deb` from NoMachine's configured official download service.

### Local package override

A local package can still be forced when needed:

```bash
LINUX_TO_GO_NOMACHINE_DEB=/absolute/path/to/nomachine_9.8.3_1_arm64.deb \
  linux-to-go -ros2
```

The package architecture is checked with `dpkg-deb` before installation.

## ROS detection before installation

The tool does **not** blindly reinstall ROS.

For `linux-to-go -ros1`, it checks specifically for ROS 1. If ROS 1 is already present, it skips ROS installation. Otherwise, on Ubuntu 20.04 it installs **ROS Noetic**.

For `linux-to-go -ros2`, it checks specifically for ROS 2. If ROS 2 is already present, it skips ROS installation. Otherwise, on Ubuntu 22.04 it installs **ROS 2 Humble**.

Detection uses standard `/opt/ros` installations, ROS commands when available, and Debian package state, so a new terminal does not need to have sourced ROS for the installation to be detected.

### Ubuntu 20.04 / ROS 1 Noetic

```bash
linux-to-go -ros1
```

When ROS 1 is missing, the installer installs the Noetic desktop environment and development/bootstrap tools, initializes `rosdep` when required, and adds this line to the login user's `~/.bashrc` once:

```bash
source /opt/ros/noetic/setup.bash
```

### Ubuntu 22.04 / ROS 2 Humble

```bash
linux-to-go -ros2
```

When ROS 2 is missing, the installer installs `ros-humble-desktop`, `ros-dev-tools`, initializes `rosdep` when required, and adds this line to `~/.bashrc` once:

```bash
source /opt/ros/humble/setup.bash
```

## Repository layout

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

`sudo ./install.sh` installs the CLI to `/usr/local/bin/linux-to-go` and the runtime modules to `/usr/local/lib/linux-to-go/`.

## Update Linux To Go

```bash
cd Linux_togo
git pull
sudo ./install.sh
```

Then run the matching `-ros1` or `-ros2` command again. Installed components will be detected and skipped where applicable.

## Troubleshooting

If `linux-to-go` is not found, rerun `sudo ./install.sh` and check `command -v linux-to-go`.

If the Ubuntu/ROS combination is rejected, use the supported matrix at the top of this README rather than forcing an unsupported combination.

If APT is locked, wait for the current `apt`/`dpkg` operation to finish. Do not delete APT lock files manually.

For a local NoMachine package, inspect its metadata with:

```bash
dpkg-deb -f /path/to/nomachine.deb Package Version Architecture
```

## Development and tests

```bash
bash -n install.sh bin/linux-to-go lib/*.sh tests/test_detection.sh
bash tests/test_detection.sh
```

The test suite covers the Ubuntu/ROS compatibility matrix, ROS installed/skip behavior, architecture selection, Clash Verge package/checksum selection, and the NoMachine ARM64 Linux_togo Release URL with official fallback behavior.
