#!/usr/bin/env bash

detect_system() {
  if [[ -n "${LTG_TEST_OS_ID:-}" ]]; then
    LTG_OS_ID="$LTG_TEST_OS_ID"
    LTG_UBUNTU_VERSION="${LTG_TEST_UBUNTU_VERSION:-}"
    LTG_ARCH="${LTG_TEST_ARCH:-}"
    return 0
  fi

  [[ -r /etc/os-release ]] || { log_error "/etc/os-release not found"; return 1; }
  # shellcheck disable=SC1091
  source /etc/os-release
  LTG_OS_ID="${ID:-}"
  LTG_UBUNTU_VERSION="${VERSION_ID:-}"
  if command_exists dpkg; then
    LTG_ARCH="$(dpkg --print-architecture)"
  else
    case "$(uname -m)" in
      x86_64) LTG_ARCH="amd64" ;;
      aarch64|arm64) LTG_ARCH="arm64" ;;
      *) LTG_ARCH="$(uname -m)" ;;
    esac
  fi
}

validate_supported_system() {
  [[ "${LTG_OS_ID:-}" == "ubuntu" ]] || { log_error "Linux To Go currently supports Ubuntu only."; return 1; }
  case "${LTG_UBUNTU_VERSION:-}" in
    20.04|22.04) ;;
    *) log_error "Unsupported Ubuntu version: ${LTG_UBUNTU_VERSION:-unknown}. Supported: 20.04, 22.04."; return 1 ;;
  esac
  case "${LTG_ARCH:-}" in
    amd64|arm64) ;;
    *) log_error "Unsupported architecture: ${LTG_ARCH:-unknown}. Supported: amd64, arm64."; return 1 ;;
  esac
}

target_ros_distro() {
  case "$1" in
    ros1) printf 'noetic\n' ;;
    ros2) printf 'humble\n' ;;
    *) return 1 ;;
  esac
}

validate_ros_request() {
  local mode="$1"
  validate_supported_system || return 1
  case "$mode:$LTG_UBUNTU_VERSION" in
    ros1:20.04|ros2:22.04) return 0 ;;
    ros1:*) log_error "ROS 1 Noetic is supported by Linux To Go on Ubuntu 20.04 only. Detected Ubuntu $LTG_UBUNTU_VERSION."; return 1 ;;
    ros2:*) log_error "ROS 2 Humble is supported by Linux To Go on Ubuntu 22.04 only. Detected Ubuntu $LTG_UBUNTU_VERSION."; return 1 ;;
    *) log_error "Unknown ROS mode: $mode"; return 1 ;;
  esac
}

parse_ros_mode() {
  [[ $# -eq 1 ]] || return 1
  case "$1" in
    -ros1|--ros1) printf 'ros1\n' ;;
    -ros2|--ros2) printf 'ros2\n' ;;
    *) return 1 ;;
  esac
}
