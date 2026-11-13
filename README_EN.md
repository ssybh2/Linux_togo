# Linux To Go

Ubuntu application and optional ROS installer. [中文](README.md) · [한국어](README_KR.md) · [ภาษาไทย](README_TH.md)

Supports Ubuntu 20.04 / 22.04 on amd64 and arm64. Intel Core i5 PCs use **amd64**.

## Existing ROS installation

Use `--apps-only` to install Clash Verge Rev and NoMachine without invoking ROS installation or changing ROS sources or shell configuration. This mode installs only missing bootstrap utilities and application runtime dependencies, without extra compiler tools.

**On amd64, first copy a trusted existing NoMachine DEB to the new PC.** The former NoMachine 9.8.3 vendor URL now redirects to HTML. The repository release contains only ARM64. Do not use the ARM64 package on Intel/AMD PCs.

```bash
# If git is missing: sudo apt update && sudo apt install -y git
git clone https://github.com/ssybh2/Linux_togo.git ~/Linux_togo
cd ~/Linux_togo
sudo ./install.sh

# Replace with your actual local package path
LINUX_TO_GO_NOMACHINE_DEB="$HOME/Downloads/nomachine_9.7.3_1_amd64.deb" linux-to-go --apps-only
linux-to-go --check
sudo /usr/NX/bin/nxserver --status
```

If NoMachine is already installed, or on ARM64, use `linux-to-go --apps-only` without the environment variable. Missing or invalid explicit packages fail before application installation. Local packages are checked for package name and architecture; arbitrary local versions have no pinned checksum.

Clash Verge Rev **2.5.2** comes from its official GitHub release, with SHA-256 and DEB metadata verification. ARM64 NoMachine **9.8.3-1** comes from this repository's release with a pinned SHA-256. Failed downloads no longer fall back to retired vendor URLs. Current [NoMachine Personal Edition](https://download.nomachine.com/personal-edition/) requires subscription activation or a trial and is not substituted automatically.

After installation, launch Clash Verge as a regular desktop user, import your own subscription and choose a node before enabling your desired proxy mode. Connect to NoMachine from another client using the PC's LAN IP and Ubuntu credentials (default TCP 4000). The installer does not configure subscriptions, system proxies, firewall rules or desktop sessions.

## Other modes and updates

- `linux-to-go --check`: report installed components without installing anything.
- `linux-to-go -ros1`: Ubuntu 20.04, optional ROS 1 Noetic installation.
- `linux-to-go -ros2`: Ubuntu 22.04, optional ROS 2 Humble installation.

ROS modes also install the applications and require a local NoMachine package on amd64. This review focused on application installation; fresh-system ROS installation was not validated.

```bash
cd ~/Linux_togo
git pull --ff-only
sudo ./install.sh
linux-to-go --check
```

Installed applications are skipped, not automatically upgraded. See [Chinese details](README_CN.md) for checksums and [audit notes](docs/install-audit.md) for fixes and test scope.
