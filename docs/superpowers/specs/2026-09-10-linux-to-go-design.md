# Linux To Go — Design Specification

Date: 2026-09-10

## 1. Goal

Turn `ssybh2/Linux_togo` into a reusable Ubuntu bootstrap tool for newly installed Linux computers.

After cloning the repository and running the bootstrap installer once, users should be able to run:

```bash
linux-to-go -ros1
linux-to-go -ros2
```

The tool installs the common software stack plus the requested ROS family, while skipping software that is already installed.

## 2. Supported operating-system matrix

The first release intentionally supports only these combinations:

| Ubuntu | CLI mode | ROS distribution |
|---|---|---|
| Ubuntu 20.04 | `-ros1` / `--ros1` | ROS 1 Noetic |
| Ubuntu 22.04 | `-ros2` / `--ros2` | ROS 2 Humble |

The tool uses strict matching.

Examples:

- Ubuntu 22.04 + `linux-to-go -ros2` -> supported.
- Ubuntu 20.04 + `linux-to-go -ros1` -> supported.
- Ubuntu 22.04 + `linux-to-go -ros1` -> stop with an explanatory error.
- Ubuntu 20.04 + `linux-to-go -ros2` -> stop with an explanatory error.

No Docker, source-built ROS, unsupported ROS/Ubuntu combinations, or automatic OS upgrades are attempted in the first release.

## 3. Main user experience

Initial bootstrap:

```bash
git clone https://github.com/ssybh2/Linux_togo.git
cd Linux_togo
sudo ./install.sh
```

The bootstrap copies the CLI into `/usr/local/bin/linux-to-go` and installs its supporting scripts under `/usr/local/lib/linux-to-go`.

Typical use:

```bash
linux-to-go -ros1
```

or:

```bash
linux-to-go -ros2
```

The command prints clear status messages such as:

```text
[INFO] Ubuntu 22.04 detected
[INFO] Architecture: amd64
[CHECK] ROS 2 ...
[OK] ROS 2 Humble already installed
[SKIP] ROS 2 installation
[CHECK] Clash Verge Rev ...
[INSTALL] Clash Verge Rev 2.5.2
[CHECK] NoMachine ...
[INSTALL] NoMachine
```

## 4. Repository structure

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
├── tests/
│   └── test_detection.sh
└── docs/
    └── superpowers/specs/
```

The project remains Bash-based to keep the bootstrap dependency-free on a fresh Ubuntu installation.

## 5. CLI behavior

The main command supports both short and long forms:

```bash
linux-to-go -ros1
linux-to-go --ros1
linux-to-go -ros2
linux-to-go --ros2
linux-to-go --help
```

Exactly one ROS mode is required.

Invalid or conflicting arguments terminate before any installation starts.

## 6. System detection

Before changing the machine, the tool must determine:

- distribution name from `/etc/os-release`;
- Ubuntu version (`20.04` or `22.04`);
- CPU architecture using `dpkg --print-architecture` with `uname -m` as diagnostic information;
- whether the process can elevate through `sudo`.

Supported architectures for the first release:

- `amd64`
- `arm64`

Unsupported distributions, Ubuntu versions, and architectures fail early with a clear message.

## 7. Idempotency

Every major component must be checked before installation.

A second run should not reinstall components already present.

The status model is:

- `[CHECK]` detection in progress
- `[OK]` component is present and usable
- `[SKIP]` installation intentionally omitted
- `[INSTALL]` installation is starting
- `[WARN]` recoverable condition
- `[ERROR]` unrecoverable condition

## 8. ROS detection and installation

### 8.1 Requested-family logic

The command only checks the family requested on the command line.

For `-ros1`:

1. Verify Ubuntu 20.04.
2. Detect an existing ROS 1 installation.
3. If ROS 1 is already present, report the detected distribution and skip ROS installation.
4. If ROS 1 is absent, install ROS Noetic.

For `-ros2`:

1. Verify Ubuntu 22.04.
2. Detect an existing ROS 2 installation.
3. If ROS 2 is already present, report the detected distribution and skip ROS installation.
4. If ROS 2 is absent, install ROS 2 Humble.

An installed ROS 1 does not count as ROS 2, and an installed ROS 2 does not count as ROS 1.

### 8.2 ROS 1 detection

Detection should use more than a single environment variable because a fresh shell may not have sourced ROS.

Signals include:

- `/opt/ros/*/setup.bash` containing a ROS 1 distribution such as Noetic;
- `rosversion -d` when available;
- Debian packages matching `ros-noetic-*`.

### 8.3 ROS 2 detection

Signals include:

- `/opt/ros/*/setup.bash` containing a ROS 2 distribution such as Humble;
- availability of the `ros2` command when sourced or globally available;
- Debian packages matching `ros-humble-*`.

### 8.4 ROS 1 Noetic installation

On Ubuntu 20.04, the installer uses the official ROS package repository and installs the standard desktop environment plus common bootstrap/development tools.

The target package is:

```text
ros-noetic-desktop-full
```

It also installs and initializes `rosdep` when necessary.

### 8.5 ROS 2 Humble installation

On Ubuntu 22.04, the installer enables the official ROS 2 apt source and installs:

```text
ros-humble-desktop
ros-dev-tools
```

It also initializes `rosdep` when necessary.

### 8.6 Shell environment

The installer adds only the matching ROS setup line when it is not already present:

Ubuntu 20.04 / Noetic:

```bash
source /opt/ros/noetic/setup.bash
```

Ubuntu 22.04 / Humble:

```bash
source /opt/ros/humble/setup.bash
```

The line is added idempotently to the invoking user's `~/.bashrc`.

## 9. Clash Verge Rev 2.5.2

The requested fixed release is `v2.5.2` from the official `clash-verge-rev/clash-verge-rev` GitHub Releases page.

Linux package names used by the installer:

```text
Clash.Verge_2.5.2_amd64.deb
Clash.Verge_2.5.2_arm64.deb
```

The installer:

1. checks whether Clash Verge Rev is already installed;
2. selects the package matching `amd64` or `arm64`;
3. downloads the package from the official GitHub release URL;
4. installs it with `apt install ./package.deb`;
5. removes the temporary package after successful installation.

For the amd64 package, the known SHA-256 for the official v2.5.2 release is:

```text
035c83ed14b16df1dd397e5d710b34bedd5d27beb6678549ceaeeadf9bc167ed
```

The script should verify checksums when a verified checksum is encoded for the selected architecture.

## 10. NoMachine

### 10.1 Uploaded package

The supplied local file is:

```text
nomachine_9.8.3_1_arm64.deb
```

Package metadata:

```text
Package: nomachine
Version: 9.8.3-1
Architecture: arm64
```

It is suitable only for ARM64 systems.

### 10.2 Public-repository handling

The NoMachine binary itself will not be committed to this public repository because NoMachine's license restricts redistribution without written permission.

Instead, the repository will contain installer logic and documentation that obtain NoMachine from an official NoMachine download endpoint or direct the user to the official download page when an automated official URL cannot be safely resolved.

The installer must never download NoMachine from mirrors or third-party file hosts.

### 10.3 Existing-installation detection

Signals include:

- `dpkg-query -W nomachine`;
- `/usr/NX/bin/nxplayer`;
- `/usr/NX/bin/nxserver`.

If NoMachine is present, installation is skipped.

### 10.4 Architecture handling

The installer supports `amd64` and `arm64` and must choose the corresponding official DEB package.

If the user manually places a legally obtained NoMachine `.deb` in a documented local override path, the installer may use it after validating that its Debian `Architecture` matches the host architecture. This provides a path for using the user's existing NoMachine 9 package without redistributing it through GitHub.

## 11. Common packages

Before optional components, the tool installs only the small common bootstrap set required by the installers, including:

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

Additional packages are installed only by the component that needs them.

## 12. Failure behavior

The tool uses `set -Eeuo pipefail` and an error handler that reports the failed stage.

Important rules:

- OS/ROS mismatch fails before package installation.
- Unsupported CPU architecture fails before downloads.
- Network/download failure stops the affected installation and keeps the downloaded temporary area disposable.
- An already-installed component is not treated as an error.
- `rosdep init` already initialized is treated as a valid state.
- apt lock errors are reported rather than forcing lock deletion.

## 13. Security and safety

- Use HTTPS sources only.
- Prefer official upstream repositories and release URLs.
- Do not pipe arbitrary remote shell scripts directly into `bash`.
- Verify fixed-release checksums when known.
- Use temporary directories created with `mktemp -d`.
- Never store user proxy subscriptions, credentials, or ROS workspace data in this repository.

## 14. Documentation

Two user-facing documents will be provided:

- `README.md` — English
- `README_CN.md` — Chinese

Both explain:

- supported Ubuntu/ROS combinations;
- bootstrap installation;
- `linux-to-go -ros1` and `linux-to-go -ros2`;
- ROS detection/skip behavior;
- Clash Verge Rev 2.5.2 package links;
- NoMachine architecture and licensing behavior;
- troubleshooting and uninstalling the `linux-to-go` command.

## 15. Testing strategy

Because changing ROS and desktop software on the development machine would be destructive, the first test layer focuses on deterministic detection and argument handling.

Tests will cover:

- Ubuntu 20.04 + `-ros1` accepted;
- Ubuntu 22.04 + `-ros2` accepted;
- mismatched ROS request rejected;
- unsupported Ubuntu version rejected;
- `amd64` and `arm64` package selection;
- ROS already installed -> skip;
- Clash Verge already installed -> skip;
- NoMachine already installed -> skip;
- invalid CLI arguments rejected.

The scripts will expose detection functions that can be tested using environment/file-command mocks rather than performing actual apt installations during automated tests.

## 16. Chosen approach and alternatives

Chosen approach: modular Bash CLI installed into `/usr/local/bin`.

Reasons:

- Bash is present on the supported Ubuntu releases.
- No Python environment is required before bootstrap.
- Installation stages remain easy to inspect and debug.
- Component-specific logic stays isolated in `lib/`.

Rejected for the first release:

- one giant shell script, because it becomes hard to test and maintain;
- Python CLI, because it introduces an extra bootstrap/runtime dependency;
- Ansible, because it requires installing and understanding another provisioning system before the tool can run;
- Dockerized ROS, because the requested behavior is native machine setup.

## 17. Success criteria

The first release is complete when a user can clone the repository on a supported fresh Ubuntu machine, run `sudo ./install.sh`, then run the matching `linux-to-go` ROS command and receive an idempotent setup of:

1. common bootstrap tools;
2. Clash Verge Rev 2.5.2;
3. NoMachine from an official source or validated local override;
4. ROS Noetic on Ubuntu 20.04 when `-ros1` is requested, or ROS 2 Humble on Ubuntu 22.04 when `-ros2` is requested;
5. shell environment setup without duplicate `.bashrc` entries.
