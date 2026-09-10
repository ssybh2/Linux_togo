# Linux To Go

[中文说明](./README_CN.md)

`Linux To Go` is a small, repeatable bootstrap tool for preparing a fresh Ubuntu computer for robotics development. It installs the common desktop tools used by this project, **Clash Verge Rev 2.5.2**, **NoMachine 9.8.3**, and the ROS family requested on the command line.

The first release intentionally supports a strict ROS/Ubuntu matrix so a fresh machine cannot accidentally receive an unsupported ROS distribution.

| Ubuntu | Command | ROS target |
|---|---|---|
| **20.04 LTS** | `linux-to-go -ros1` | **ROS 1 Noetic** |
| **22.04 LTS** | `linux-to-go -ros2` | **ROS 2 Humble** |

Supported CPU architectures: **amd64** and **arm64**.

> `linux-to-go -ros1` on Ubuntu 22.04 and `linux-to-go -ros2` on Ubuntu 20.04 are deliberately rejected. Linux To Go does not use Docker, source-built ROS, or an OS upgrade to bypass this compatibility rule.

---

## Quick start

Clone this repository and install the command once:

```bash
git clone https://github.com/ssybh2/Linux_togo.git
cd Linux_togo
sudo ./install.sh
```

Then run the command as your **normal login user**. The installer requests `sudo` only for system changes.

Ubuntu 20.04:

```bash
linux-to-go -ros1
```

Ubuntu 22.04:

```bash
linux-to-go -ros2
```

Long aliases are also supported:

```bash
linux-to-go --ros1
linux-to-go --ros2
```

Show help:

```bash
linux-to-go --help
```

---

## What happens when the command runs

The order is intentionally predictable:

```text
1. Detect Ubuntu version and CPU architecture
2. Reject an unsupported Ubuntu / ROS combination before modifying the machine
3. Install common bootstrap packages
4. Check and install Clash Verge Rev 2.5.2 if necessary
5. Check and install NoMachine 9.8.3 if necessary
6. Check only the requested ROS family
   ├── already installed -> SKIP ROS installation
   └── not installed     -> install Noetic or Humble
7. Add the matching ROS setup line to ~/.bashrc once
```

Typical output looks like:

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

### ROS detection is family-specific

`-ros1` checks for ROS 1. `-ros2` checks for ROS 2. Linux To Go does **not** treat an installed ROS 1 as an installed ROS 2, or vice versa.

The detection logic does not rely only on the current shell environment. It also checks standard installations under `/opt/ros`, ROS commands when available, and relevant Debian packages. This means an already-installed ROS can still be detected even when the current terminal has not sourced its `setup.bash` yet.

If the requested family is already installed, Linux To Go leaves it in place and does not reinstall it.

---

## Clash Verge Rev 2.5.2

Linux To Go pins Clash Verge Rev to **v2.5.2** and downloads the package directly from the project's official GitHub Release.

Official Linux DEB packages:

| Architecture | Package | SHA-256 |
|---|---|---|
| amd64 | [Clash.Verge_2.5.2_amd64.deb](https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.5.2/Clash.Verge_2.5.2_amd64.deb) | `035c83ed14b16df1dd397e5d710b34bedd5d27beb6678549ceaeeadf9bc167ed` |
| arm64 | [Clash.Verge_2.5.2_arm64.deb](https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.5.2/Clash.Verge_2.5.2_arm64.deb) | `598a5a852d7bf9dc40a976780ef2afc9a4e5bfe7b99533e5f956f9e2f9def72f` |

Release page: <https://github.com/clash-verge-rev/clash-verge-rev/releases/tag/v2.5.2>

The installer verifies the downloaded DEB with the release SHA-256 before installation.

---

## NoMachine 9.8.3

Linux To Go targets **NoMachine 9.8.3**. The repository now also provides the ARM64 package as a GitHub Release asset so ARM Linux users can download the exact package directly from this project.

### Repository Release download

| Architecture | Package | Download | SHA-256 |
|---|---|---|---|
| arm64 | `nomachine_9.8.3_1_arm64.deb` | [Download from Linux_togo Releases](https://github.com/ssybh2/Linux_togo/releases/download/nomachine/nomachine_9.8.3_1_arm64.deb) | `be874820b9539e836d44fdfb2311a588253bd192e0e43393d819251e42a057ad` |

Release page: <https://github.com/ssybh2/Linux_togo/releases/tag/nomachine>

The uploaded Release asset has the following verified metadata:

```text
Package:      nomachine
Version:      9.8.3-1
Architecture: arm64
Size:         77,575,208 bytes
SHA-256:      be874820b9539e836d44fdfb2311a588253bd192e0e43393d819251e42a057ad
```

For manual installation on an ARM64 Ubuntu machine:

```bash
wget https://github.com/ssybh2/Linux_togo/releases/download/nomachine/nomachine_9.8.3_1_arm64.deb
sudo apt install ./nomachine_9.8.3_1_arm64.deb
```

You can also download it from a browser through the Release page above.

### Use the Release package with Linux To Go

If you want Linux To Go to use the package downloaded from this repository Release instead of downloading another copy, run:

```bash
wget https://github.com/ssybh2/Linux_togo/releases/download/nomachine/nomachine_9.8.3_1_arm64.deb

LINUX_TO_GO_NOMACHINE_DEB="$PWD/nomachine_9.8.3_1_arm64.deb" \
  linux-to-go -ros2
```

The installer reads the package metadata using `dpkg-deb` and rejects the package if its Debian `Architecture` does not match the host.

> The currently uploaded repository Release contains the **ARM64** build. Do not install this file on an `amd64` / Intel / AMD x86-64 computer. For those machines, Linux To Go continues to select the appropriate amd64 package through its NoMachine installer logic.

NoMachine announced version 9.8.3 on 4 September 2026. See the official update notice: <https://kb.nomachine.com/SU09X00285>

---

## ROS 1 Noetic — Ubuntu 20.04

On Ubuntu 20.04, run:

```bash
linux-to-go -ros1
```

Linux To Go first looks for an existing ROS 1 installation. If one is found, ROS installation is skipped. Otherwise it configures the ROS package repository and installs:

```text
ros-noetic-desktop-full
python3-rosdep
python3-rosinstall
python3-rosinstall-generator
python3-wstool
build-essential
```

It also initializes `rosdep` when necessary and adds this line to the login user's `~/.bashrc` once:

```bash
source /opt/ros/noetic/setup.bash
```

After a new installation, open a new terminal or run:

```bash
source /opt/ros/noetic/setup.bash
```

---

## ROS 2 Humble — Ubuntu 22.04

On Ubuntu 22.04, run:

```bash
linux-to-go -ros2
```

Linux To Go first looks for an existing ROS 2 installation. If one is found, ROS installation is skipped. Otherwise it configures the ROS 2 package repository and installs:

```text
ros-humble-desktop
ros-dev-tools
python3-rosdep
```

It also initializes `rosdep` when necessary and adds this line to the login user's `~/.bashrc` once:

```bash
source /opt/ros/humble/setup.bash
```

After a new installation, open a new terminal or run:

```bash
source /opt/ros/humble/setup.bash
```

---

## Common packages

The bootstrap stage installs a small base set used by the component installers:

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

APT itself is idempotent, so packages that are already present are retained rather than unnecessarily replaced.

---

## Repository layout

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

`install.sh` installs the runtime files to:

```text
/usr/local/bin/linux-to-go
/usr/local/lib/linux-to-go/
```

---

## Troubleshooting

### `linux-to-go: command not found`

Run the bootstrap again from the repository root:

```bash
sudo ./install.sh
```

Then confirm:

```bash
command -v linux-to-go
```

Expected:

```text
/usr/local/bin/linux-to-go
```

### Wrong ROS mode for this Ubuntu release

Example:

```text
[ERROR] ROS 1 Noetic is supported by Linux To Go on Ubuntu 20.04 only.
```

Use the command matching the compatibility table. Linux To Go intentionally does not force an unsupported ROS/Ubuntu combination.

### APT is locked

Close another package manager or wait for an existing `apt`/`dpkg` operation to finish, then run Linux To Go again. Do **not** delete APT lock files manually.

### NoMachine local package architecture mismatch

Check the package:

```bash
dpkg-deb -f /path/to/nomachine.deb Package Version Architecture
```

Use an `amd64` package on an amd64 machine and an `arm64` package on an arm64 machine.

### ROS installed but commands are unavailable in this terminal

Open a new terminal, or source the setup file explicitly:

```bash
# Ubuntu 20.04 / ROS 1
source /opt/ros/noetic/setup.bash

# Ubuntu 22.04 / ROS 2
source /opt/ros/humble/setup.bash
```

---

## Update Linux To Go

The installed CLI is a copy of the repository scripts. To update it:

```bash
cd Linux_togo
git pull
sudo ./install.sh
```

Then run the appropriate ROS command again. Existing components will be detected and skipped where applicable.

---

## Remove Linux To Go itself

This removes only the bootstrap command and its helper scripts; it does **not** uninstall ROS, Clash Verge Rev, or NoMachine.

```bash
sudo rm -f /usr/local/bin/linux-to-go
sudo rm -rf /usr/local/lib/linux-to-go
```

---

## Development and tests

The tests use environment overrides and temporary directories; they do not install ROS or desktop applications.

Syntax check:

```bash
bash -n install.sh bin/linux-to-go lib/*.sh tests/test_detection.sh
```

Run the behavior tests:

```bash
bash tests/test_detection.sh
```

The suite covers the Ubuntu/ROS compatibility matrix, ROS-installed detection, architecture handling, Clash Verge assets and checksums, NoMachine package selection, and CLI argument behavior.

---

## Security notes

Linux To Go downloads software over HTTPS. Clash Verge Rev v2.5.2 downloads are checksum-verified for both supported architectures. The repository-hosted NoMachine 9.8.3 ARM64 Release asset is documented with its SHA-256 digest so users can verify the downloaded package before installation.

Review the scripts before running them on machines that contain important data, especially when using the project beyond its documented Ubuntu versions.
