#!/usr/bin/env bash

_ros_root() { printf '%s\n' "${LTG_ROS_ROOT:-/opt/ros}"; }

detect_ros1() {
  LTG_DETECTED_ROS1_DISTRO=""
  if [[ -n "${LTG_TEST_ROS1_PRESENT:-}" ]]; then
    [[ "$LTG_TEST_ROS1_PRESENT" == "1" ]] || return 1
    LTG_DETECTED_ROS1_DISTRO="${LTG_TEST_ROS1_DISTRO:-noetic}"
    return 0
  fi

  local root
  root="$(_ros_root)"
  if [[ -f "$root/noetic/setup.bash" ]]; then
    LTG_DETECTED_ROS1_DISTRO="noetic"
    return 0
  fi

  if [[ "${LTG_TEST_DISABLE_COMMAND_DETECTION:-0}" != "1" ]]; then
    if command_exists rosversion; then
      LTG_DETECTED_ROS1_DISTRO="$(rosversion -d 2>/dev/null || true)"
      [[ -n "$LTG_DETECTED_ROS1_DISTRO" ]] && return 0
    fi
    if package_installed ros-noetic-ros-core || package_installed ros-noetic-ros-base || package_installed ros-noetic-desktop-full; then
      LTG_DETECTED_ROS1_DISTRO="noetic"
      return 0
    fi
  fi
  return 1
}

detect_ros2() {
  LTG_DETECTED_ROS2_DISTRO=""
  if [[ -n "${LTG_TEST_ROS2_PRESENT:-}" ]]; then
    [[ "$LTG_TEST_ROS2_PRESENT" == "1" ]] || return 1
    LTG_DETECTED_ROS2_DISTRO="${LTG_TEST_ROS2_DISTRO:-humble}"
    return 0
  fi

  local root
  root="$(_ros_root)"
  if [[ -f "$root/humble/setup.bash" ]]; then
    LTG_DETECTED_ROS2_DISTRO="humble"
    return 0
  fi

  if [[ "${LTG_TEST_DISABLE_COMMAND_DETECTION:-0}" != "1" ]]; then
    if command_exists ros2; then
      LTG_DETECTED_ROS2_DISTRO="${ROS_DISTRO:-unknown}"
      return 0
    fi
    if package_installed ros-humble-ros-core || package_installed ros-humble-ros-base || package_installed ros-humble-desktop; then
      LTG_DETECTED_ROS2_DISTRO="humble"
      return 0
    fi
  fi
  return 1
}

setup_rosdep() {
  apt_install python3-rosdep
  if [[ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]]; then
    run_as_root rosdep init
  fi
  rosdep update
}

_add_ros_env_line() {
  local distro="$1" home bashrc line
  home="$(invoking_home)"
  bashrc="$home/.bashrc"
  line="source /opt/ros/$distro/setup.bash"
  add_line_once "$line" "$bashrc"
}

install_ros1_noetic() {
  log_install "ROS 1 Noetic"
  apt_install curl gnupg lsb-release

  local key_tmp
  key_tmp="$(mktemp)"
  curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc -o "$key_tmp"
  gpg --dearmor --yes --output "${key_tmp}.gpg" "$key_tmp"
  run_as_root install -m 0644 "${key_tmp}.gpg" /usr/share/keyrings/ros1-archive-keyring.gpg
  rm -f "$key_tmp" "${key_tmp}.gpg"

  printf 'deb [arch=%s signed-by=/usr/share/keyrings/ros1-archive-keyring.gpg] https://packages.ros.org/ros/ubuntu focal main\n' "$LTG_ARCH" \
    | run_as_root tee /etc/apt/sources.list.d/ros1.list >/dev/null
  LTG_APT_UPDATED=0
  apt_update_once
  run_as_root apt-get install -y ros-noetic-desktop-full python3-rosdep python3-rosinstall python3-rosinstall-generator python3-wstool build-essential
  setup_rosdep
  _add_ros_env_line noetic
  log_ok "ROS 1 Noetic installed"
}

install_ros2_humble() {
  log_install "ROS 2 Humble"
  apt_install curl gnupg lsb-release software-properties-common
  run_as_root add-apt-repository -y universe

  local key_tmp
  key_tmp="$(mktemp)"
  curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o "$key_tmp"
  run_as_root install -m 0644 "$key_tmp" /usr/share/keyrings/ros-archive-keyring.gpg
  rm -f "$key_tmp"

  printf 'deb [arch=%s signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] https://packages.ros.org/ros2/ubuntu jammy main\n' "$LTG_ARCH" \
    | run_as_root tee /etc/apt/sources.list.d/ros2.list >/dev/null
  LTG_APT_UPDATED=0
  apt_update_once
  run_as_root apt-get install -y ros-humble-desktop ros-dev-tools python3-rosdep
  setup_rosdep
  _add_ros_env_line humble
  log_ok "ROS 2 Humble installed"
}

install_requested_ros() {
  local mode="$1"
  case "$mode" in
    ros1)
      log_check "ROS 1"
      if detect_ros1; then
        log_ok "ROS 1 ${LTG_DETECTED_ROS1_DISTRO} already installed"
        log_skip "ROS 1 installation"
        return 0
      fi
      install_ros1_noetic
      ;;
    ros2)
      log_check "ROS 2"
      if detect_ros2; then
        log_ok "ROS 2 ${LTG_DETECTED_ROS2_DISTRO} already installed"
        log_skip "ROS 2 installation"
        return 0
      fi
      install_ros2_humble
      ;;
    *) log_error "Unknown ROS mode: $mode"; return 1 ;;
  esac
}
