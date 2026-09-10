#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

failures=0
passes=0

pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }
assert_eq() {
  local expected="$1" actual="$2" name="$3"
  if [[ "$expected" == "$actual" ]]; then pass "$name"; else fail "$name (expected '$expected', got '$actual')"; fi
}
assert_success() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then pass "$name"; else fail "$name"; fi; }
assert_failure() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then fail "$name"; else pass "$name"; fi; }

# Production files intentionally sourced before they exist for TDD red phase.
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/system.sh"

LTG_TEST_OS_ID=ubuntu LTG_TEST_UBUNTU_VERSION=20.04 LTG_TEST_ARCH=amd64 detect_system
assert_eq "ubuntu" "$LTG_OS_ID" "detect ubuntu id"
assert_eq "20.04" "$LTG_UBUNTU_VERSION" "detect ubuntu 20.04"
assert_eq "amd64" "$LTG_ARCH" "detect amd64"
assert_success "20.04 accepts ros1" validate_ros_request ros1
assert_failure "20.04 rejects ros2" validate_ros_request ros2

LTG_TEST_OS_ID=ubuntu LTG_TEST_UBUNTU_VERSION=22.04 LTG_TEST_ARCH=arm64 detect_system
assert_success "22.04 accepts ros2" validate_ros_request ros2
assert_failure "22.04 rejects ros1" validate_ros_request ros1
assert_eq "humble" "$(target_ros_distro ros2)" "ros2 target is humble"
assert_eq "noetic" "$(target_ros_distro ros1)" "ros1 target is noetic"

LTG_TEST_OS_ID=ubuntu LTG_TEST_UBUNTU_VERSION=22.04 LTG_TEST_ARCH=armhf detect_system
assert_failure "armhf rejected" validate_supported_system

assert_eq "ros1" "$(parse_ros_mode -ros1)" "parse -ros1"
assert_eq "ros1" "$(parse_ros_mode --ros1)" "parse --ros1"
assert_eq "ros2" "$(parse_ros_mode -ros2)" "parse -ros2"
assert_eq "ros2" "$(parse_ros_mode --ros2)" "parse --ros2"
assert_failure "invalid mode rejected" parse_ros_mode --foo

source "$ROOT_DIR/lib/ros.sh"

tmp_ros="$(mktemp -d)"
trap 'rm -rf "$tmp_ros"' EXIT
mkdir -p "$tmp_ros/noetic" "$tmp_ros/humble"
touch "$tmp_ros/noetic/setup.bash" "$tmp_ros/humble/setup.bash"
LTG_ROS_ROOT="$tmp_ros" LTG_TEST_DISABLE_COMMAND_DETECTION=1 detect_ros1
assert_eq "noetic" "$LTG_DETECTED_ROS1_DISTRO" "detect existing ROS1 Noetic"
LTG_ROS_ROOT="$tmp_ros" LTG_TEST_DISABLE_COMMAND_DETECTION=1 detect_ros2
assert_eq "humble" "$LTG_DETECTED_ROS2_DISTRO" "detect existing ROS2 Humble"
rm -f "$tmp_ros/noetic/setup.bash" "$tmp_ros/humble/setup.bash"
assert_failure "ROS1 absent when no setup/package/command" env LTG_ROS_ROOT="$tmp_ros" LTG_TEST_DISABLE_COMMAND_DETECTION=1 bash -c 'source "$1/lib/common.sh"; source "$1/lib/ros.sh"; detect_ros1' _ "$ROOT_DIR"
assert_failure "ROS2 absent when no setup/package/command" env LTG_ROS_ROOT="$tmp_ros" LTG_TEST_DISABLE_COMMAND_DETECTION=1 bash -c 'source "$1/lib/common.sh"; source "$1/lib/ros.sh"; detect_ros2' _ "$ROOT_DIR"

source "$ROOT_DIR/lib/clash-verge.sh"
assert_eq "Clash.Verge_2.5.2_amd64.deb" "$(clash_asset_name amd64)" "Clash amd64 asset"
assert_eq "Clash.Verge_2.5.2_arm64.deb" "$(clash_asset_name arm64)" "Clash arm64 asset"
assert_eq "035c83ed14b16df1dd397e5d710b34bedd5d27beb6678549ceaeeadf9bc167ed" "$(clash_asset_sha256 amd64)" "Clash amd64 checksum"
assert_eq "598a5a852d7bf9dc40a976780ef2afc9a4e5bfe7b99533e5f956f9e2f9def72f" "$(clash_asset_sha256 arm64)" "Clash arm64 checksum"
assert_eq "https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.5.2/Clash.Verge_2.5.2_amd64.deb" "$(clash_asset_url amd64)" "Clash official amd64 URL"
assert_failure "Clash unsupported arch rejected" clash_asset_name armhf

source "$ROOT_DIR/lib/nomachine.sh"
assert_eq "nomachine_9.8.3_1_amd64.deb" "$(nomachine_asset_name amd64)" "NoMachine amd64 asset"
assert_eq "nomachine_9.8.3_1_arm64.deb" "$(nomachine_asset_name arm64)" "NoMachine arm64 asset"
assert_eq "https://download.nomachine.com/download/9.8/Linux/nomachine_9.8.3_1_amd64.deb" "$(nomachine_asset_url amd64)" "NoMachine official amd64 URL"
assert_eq "https://download.nomachine.com/download/9.8/Arm/nomachine_9.8.3_1_arm64.deb" "$(nomachine_asset_url arm64)" "NoMachine official arm64 URL"
assert_eq "be874820b9539e836d44fdfb2311a588253bd192e0e43393d819251e42a057ad" "$(nomachine_asset_sha256 arm64)" "NoMachine uploaded arm64 checksum"

tmp_nm="$(mktemp -d)"
touch "$tmp_nm/nomachine_9.8.3_1_arm64.deb"
LTG_NOMACHINE_PACKAGE_DIR="$tmp_nm"
assert_eq "$tmp_nm/nomachine_9.8.3_1_arm64.deb" "$(find_nomachine_local_package arm64)" "NoMachine local override found"
rm -rf "$tmp_nm"
unset LTG_NOMACHINE_PACKAGE_DIR

assert_success "CLI 20.04 ros1 happy path" env \
  LTG_TEST_OS_ID=ubuntu LTG_TEST_UBUNTU_VERSION=20.04 LTG_TEST_ARCH=amd64 \
  LTG_TEST_SKIP_COMMON=1 LTG_TEST_CLASH_PRESENT=1 LTG_TEST_NOMACHINE_PRESENT=1 LTG_TEST_ROS1_PRESENT=1 \
  bash "$ROOT_DIR/bin/linux-to-go" -ros1
assert_success "CLI 22.04 ros2 happy path" env \
  LTG_TEST_OS_ID=ubuntu LTG_TEST_UBUNTU_VERSION=22.04 LTG_TEST_ARCH=arm64 \
  LTG_TEST_SKIP_COMMON=1 LTG_TEST_CLASH_PRESENT=1 LTG_TEST_NOMACHINE_PRESENT=1 LTG_TEST_ROS2_PRESENT=1 \
  bash "$ROOT_DIR/bin/linux-to-go" --ros2
assert_failure "CLI rejects ros1 on Ubuntu 22.04" env \
  LTG_TEST_OS_ID=ubuntu LTG_TEST_UBUNTU_VERSION=22.04 LTG_TEST_ARCH=amd64 \
  LTG_TEST_SKIP_COMMON=1 bash "$ROOT_DIR/bin/linux-to-go" -ros1
assert_failure "CLI requires one mode" bash "$ROOT_DIR/bin/linux-to-go"

printf '\n%d passed, %d failed\n' "$passes" "$failures"
(( failures == 0 ))
