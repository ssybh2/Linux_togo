# Linux To Go

Clone and run the graphical environment installer as your normal desktop user:

```bash
git clone https://github.com/ssybh2/Linux_togo.git
cd Linux_togo
./setup.sh
```

The launcher installs `python3-tk` if missing, detects Ubuntu and package architecture (amd64/arm64), and shows existing ROS installations. Select compatible ROS and applications, preview the plan, then start deployment. Existing applications are skipped; existing ROS is preserved by default. An isolated password dialog authorizes sudo; passwords are not logged.

| Ubuntu | ROS option | Clash Verge 2.5.10 |
| --- | --- | --- |
| 20.04 | Noetic (EOL since May 2025) | Disabled: requires WebKit 4.1 unavailable in standard Focal repositories |
| 22.04 | Humble | Supported |
| 24.04 | Jazzy | Supported |

Both applications come from this repository's Releases, with pinned hashes and DEB metadata validation. Clash: 2.5.10 on both architectures. NoMachine: amd64 9.7.3-1, arm64 9.8.3-1. Intel x86-64 uses amd64 too.

```bash
./setup.sh --check
./setup.sh --auto                    # terminal fallback
./setup.sh --ros2 --dry-run          # no changes
./setup.sh --ros2                    # Humble or Jazzy according to Ubuntu
./setup.sh --ros1 --skip-clash        # Focal only
./setup.sh --apps-only
```

No preliminary tool installation is required. Optional global command: `sudo ./install.sh`, then `linux-to-go --gui`. Logs are stored in `~/.local/state/linux-to-go/` (respects XDG_STATE_HOME). ROS source/key management uses official, hash-verified ros-apt-source packages. Installation stops on failure; APT is prohibited from removing installed packages. Re-running skips components already installed.

Import your own Clash subscription after installation. Check NoMachine with `sudo /usr/NX/bin/nxserver --status`. ROS is available in a new terminal. Unsupported distributions or combinations are rejected before installation; source/container ROS installations are outside this tool's scope.

Tests use mocked APT/network commands and temporary DEBs. Real release downloads, metadata, hashes and GUI preview have been verified; a complete installation on pristine target systems has not been performed here. See [validation](docs/bootstrap-validation.md) and the [Chinese guide](README_CN.md).
