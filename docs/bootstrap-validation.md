# Graphical bootstrap validation — 2026-11-15

Implementation extends the existing CLI, preserving its module boundaries and
local NoMachine override. New clone-and-run entrypoint: `./setup.sh`.

## Checked on the development host

- Ubuntu 22.04 / amd64 detection, installed ROS 2 Humble recognized without sourcing.
- Tk window rendered on the actual desktop; existing ROS defaults to preserve.
- No-ROS ARM64 / Ubuntu 24.04 and AMD64 / Ubuntu 20.04 UI states rendered;
  incompatible ROS options and Focal Clash installation disabled.
- GUI plan preview executed through the actual backend, displayed logs,
  returned success, with no sudo or package installation.
- All shell files pass `bash -n`; `git diff --check` passes.
- Shell detection suite: 36 checks.
- Python unittest suite: 31 tests including an optional real downloaded-DEB audit.
  Tests cover supported OS/arch choices, both-generation detection, pre-existing
  ROS, no-display/no-stdin refusal, official source package selection,
  ROS success/failure sequencing, both app download paths, APT failures,
  checksum mismatches, HTML downloads and wrong architecture rejection.

## Actual release assets downloaded and inspected

All four application assets were downloaded from Linux_togo Releases, hashed,
and inspected with `dpkg-deb`. Hashes match GitHub asset digests.

| Asset | SHA-256 |
| --- | --- |
| Clash.Verge_2.5.10_amd64.deb | add8564811ba4d2305da443288d23a26c5ed19674b676a0bb58b99ec4f7d13cf |
| Clash.Verge_2.5.10_arm64.deb | 729c3bdc84207984fd894cc0ff14e6451fc9335060b5c7efbe378a9f4dbdf8fd |
| nomachine_9.7.3_1_amd64.deb | 81e0f8b48c7a4d3c16dac0401b9d188353e4a237498284d267a05c5176fd95fc |
| nomachine_9.8.3_1_arm64.deb | be874820b9539e836d44fdfb2311a588253bd192e0e43393d819251e42a057ad |

Clash declares `libwebkit2gtk-4.1-0`, which is not available from standard Focal
repositories. Ubuntu 20.04 therefore offers ROS1 and NoMachine, not a forced
installation of this Clash binary.

ROS apt-source 1.3.0 packages for focal, jammy and noble were downloaded from
`ros-infrastructure/ros-apt-source`. Hash and package/version/all-architecture
validation pass against the production installation function with APT intercepted.
Noetic rosdep updates include end-of-life distributions so its definitions are
not silently omitted. Official docs were read from the ros2_documentation repository because the docs
website presented an anti-bot page. Humble targets Jammy; Jazzy targets Noble.

## Scope of verification

No system applications, ROS distributions, repositories, services or shell
configuration were installed/modified on the development host. Full real package
installation has not been exercised on pristine amd64 and arm64 systems. The
password dialog code is included, but no real sudo authorization was requested
for installing applications during development. New targets require working
network access, suitable Ubuntu repositories, sudo rights and sufficient disk.
Network and dependency failures are surfaced in the UI; completed package
changes remain and re-running skips already installed components.
