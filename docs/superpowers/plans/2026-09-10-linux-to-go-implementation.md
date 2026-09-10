# Linux To Go Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Bash-based Ubuntu bootstrap CLI that installs Clash Verge Rev 2.5.2, NoMachine 9.8.3, and the requested ROS family while skipping components already installed.

**Architecture:** A small `linux-to-go` CLI delegates system detection, common package handling, Clash Verge installation, NoMachine installation, and ROS installation to focused scripts under `lib/`. The bootstrap `install.sh` copies the CLI and libraries to `/usr/local`. Tests source the library functions with deterministic environment overrides so no real package installation occurs.

**Tech Stack:** Bash, apt/dpkg, curl, GNU coreutils, ROS apt repositories.

**Spec:** `docs/superpowers/specs/2026-09-10-linux-to-go-design.md`

## Global Constraints

- Ubuntu 20.04 only supports `-ros1` / `--ros1` and installs ROS 1 Noetic.
- Ubuntu 22.04 only supports `-ros2` / `--ros2` and installs ROS 2 Humble.
- `amd64` and `arm64` are supported; unsupported architectures fail before downloads.
- Existing requested ROS family is detected and skipped.
- Clash Verge Rev is pinned to v2.5.2 and uses official GitHub release assets with SHA-256 verification.
- NoMachine is pinned to v9.8.3 and downloaded from official NoMachine URLs; a local `.deb` override is supported and architecture-validated.
- NoMachine binary files are not committed to this public repository.
- Installation stages are idempotent and use HTTPS only.

---

### Task 1: Detection and CLI contract

**Files:** `tests/test_detection.sh`, `lib/common.sh`, `lib/system.sh`, `bin/linux-to-go`.

**Interfaces:** produces `detect_system`, `validate_ros_request`, `parse_ros_mode`, `run_as_root`, and status logging helpers.

- [ ] Write tests for Ubuntu/ROS matching, architecture validation, and CLI aliases.
- [ ] Run `bash tests/test_detection.sh` and verify it fails because implementation functions do not exist.
- [ ] Implement minimal detection and parsing functions.
- [ ] Re-run tests and verify all assertions pass.

### Task 2: ROS detection and installation

**Files:** modify `tests/test_detection.sh`; create `lib/ros.sh`.

**Interfaces:** produces `detect_ros1`, `detect_ros2`, `install_ros1_noetic`, `install_ros2_humble`, `install_requested_ros`.

- [ ] Add tests showing existing Noetic/Humble installs are detected using test override directories.
- [ ] Verify the new assertions fail before implementation.
- [ ] Implement family-specific detection and strict distro installation using official ROS apt repositories.
- [ ] Re-run tests and verify pass.

### Task 3: Clash Verge Rev 2.5.2

**Files:** modify `tests/test_detection.sh`; create `lib/clash-verge.sh`.

**Interfaces:** produces `clash_asset_name`, `clash_asset_sha256`, `clash_asset_url`, `clash_is_installed`, `install_clash_verge`.

- [ ] Add tests for amd64/arm64 asset selection and checksums.
- [ ] Verify failure before implementation.
- [ ] Implement official v2.5.2 URLs and SHA-256 validation.
- [ ] Re-run tests and verify pass.

### Task 4: NoMachine 9.8.3

**Files:** modify `tests/test_detection.sh`; create `lib/nomachine.sh`, `packages/README.md`, `packages/.gitignore`.

**Interfaces:** produces `nomachine_asset_name`, `nomachine_asset_url`, `nomachine_is_installed`, `find_nomachine_local_package`, `validate_deb_architecture`, `install_nomachine`.

- [ ] Add tests for amd64/arm64 official asset selection and local override matching.
- [ ] Verify failure before implementation.
- [ ] Implement official NoMachine 9.8.3 URLs using `/9.8/Linux/` for amd64 and `/9.8/Arm/` for arm64, plus local override architecture validation.
- [ ] Re-run tests and verify pass.

### Task 5: Bootstrap installer and orchestration

**Files:** create `install.sh`; modify `bin/linux-to-go` and `tests/test_detection.sh`.

**Interfaces:** bootstrap installs `/usr/local/bin/linux-to-go` and `/usr/local/lib/linux-to-go/*.sh`; CLI sequence is parse -> detect -> strict validate -> common packages -> Clash -> NoMachine -> requested ROS.

- [ ] Add dry-run orchestration tests proving mismatches stop before installs and matching modes select the correct target distro.
- [ ] Verify failure before orchestration implementation.
- [ ] Implement bootstrap and orchestration.
- [ ] Re-run tests and verify pass.

### Task 6: User documentation

**Files:** create `README.md`, `README_CN.md`.

- [ ] Document clone/bootstrap commands, supported matrix, component behavior, official download links, NoMachine redistribution note, ROS skip behavior, troubleshooting, and uninstall in English.
- [ ] Create equivalent Chinese documentation with language-switch links.
- [ ] Run syntax checks and repository tests after docs are added.

### Task 7: Final verification

- [ ] Run `bash -n install.sh bin/linux-to-go lib/*.sh tests/test_detection.sh`.
- [ ] Run `bash tests/test_detection.sh` and require zero failures.
- [ ] Confirm no `.deb` binary is included under `packages/`.
- [ ] Re-read GitHub files and verify Ubuntu/ROS matrix, Clash version/checksums, and NoMachine version/URLs.