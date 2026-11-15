#!/usr/bin/env bash

_ros_root() { printf '%s\n' "${LTG_ROS_ROOT:-/opt/ros}"; }

# Detection does not require the user to have sourced ROS. Standard prefixes,
# installed packages and active source-built environments are all recognized.
_detect_ros() {
  local generation="$1" distro root setup version
  local override="LTG_TEST_ROS${generation}_PRESENT" override_distro="LTG_TEST_ROS${generation}_DISTRO"
  if [[ -n "${!override:-}" ]]; then
    [[ "${!override}" == 1 ]] || return 1
    printf '%s\n' "${!override_distro:-$([[ "$generation" == 1 ]] && echo noetic || echo humble)}"
    return 0
  fi
  root="$(_ros_root)"
  for setup in "$root"/*/setup.bash; do
    [[ -f "$setup" ]] || continue
    distro="$(basename "$(dirname "$setup")")"
    if [[ "$generation" == 1 ]]; then
      case "$distro" in noetic|melodic|kinetic|indigo) printf '%s\n' "$distro"; return 0 ;; esac
    else
      case "$distro" in ardent|bouncy|crystal|dashing|eloquent|foxy|galactic|humble|iron|jazzy|kilted|lyrical|rolling) printf '%s\n' "$distro"; return 0 ;; esac
    fi
    if [[ -f "$(dirname "$setup")/share/ros_environment/environment/1.ros_version.sh" ]]; then
      version="$(sed -n 's/^export ROS_VERSION=\([12]\).*/\1/p' "$(dirname "$setup")/share/ros_environment/environment/1.ros_version.sh")"
      [[ "$version" != "$generation" ]] || { printf '%s\n' "$distro"; return 0; }
    fi
  done
  [[ "${LTG_TEST_DISABLE_COMMAND_DETECTION:-0}" != 1 ]] || return 1
  if [[ "${ROS_VERSION:-}" == "$generation" && -n "${ROS_DISTRO:-}" ]]; then
    if { [[ "$generation" == 1 ]] && command_exists rosversion; } || { [[ "$generation" == 2 ]] && command_exists ros2; }; then
      printf '%s\n' "$ROS_DISTRO"; return 0
    fi
  fi
  # Covers installations under a custom prefix with a Debian package record.
  local rows package status
  rows="$(dpkg-query -W -f='${Package} ${Status}\n' 'ros-*-ros-core' 'ros-*-ros-base' 'ros-*-desktop*' 2>/dev/null || true)"
  while read -r package status; do
    [[ "$status" == 'install ok installed' ]] || continue
    distro="${package#ros-}"; distro="${distro%%-*}"
    case "$generation:$distro" in
      1:noetic|1:melodic|1:kinetic|1:indigo) printf '%s\n' "$distro"; return 0 ;;
      2:foxy|2:galactic|2:humble|2:iron|2:jazzy|2:kilted|2:lyrical|2:rolling) printf '%s\n' "$distro"; return 0 ;;
    esac
  done <<< "$rows"
  return 1
}

detect_ros1() { LTG_DETECTED_ROS1_DISTRO="$(_detect_ros 1)"; }
detect_ros2() { LTG_DETECTED_ROS2_DISTRO="$(_detect_ros 2)"; }

setup_rosdep() {
  if [[ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]]; then
    run_as_root rosdep init || return 1
  fi
  local user
  local update_args=()
  [[ "${1:-}" != ros1 ]] || update_args+=(--include-eol-distros)
  user="$(invoking_user)"
  if [[ ${EUID:-$(id -u)} == 0 && "$user" != root ]]; then
    runuser -u "$user" -- rosdep update "${update_args[@]}" || return 1
  else
    rosdep update "${update_args[@]}" || return 1
  fi
}

_add_ros_env_line() {
  local distro="$1" home bashrc line user
  home="$(invoking_home)"; user="$(invoking_user)"
  bashrc="$home/.bashrc"
  line="source /opt/ros/$distro/setup.bash"
  add_line_once "$line" "$bashrc" || return 1
  if [[ ${EUID:-$(id -u)} == 0 && "$user" != root ]]; then chown "$user:" "$bashrc" || return 1; fi
}

install_ros_source() {
  local mode="$1" codename name checksum
  case "$mode:$LTG_UBUNTU_VERSION" in
    ros1:20.04) codename=focal; name=ros-apt-source; checksum=33a491f72e4e25491f8511c173526bb20ce84ff9faf596158f178f4900da5df1 ;;
    ros2:22.04) codename=jammy; name=ros2-apt-source; checksum=110b9a462d55252decb8b7c816f61c2ba0d9890ce5fb93ac504e97cae5860d76 ;;
    ros2:24.04) codename=noble; name=ros2-apt-source; checksum=f31d84adf5054c7d60ded0e82c0f776a77ea33af53d08f40b9ad7c94cca55296 ;;
    *) return 1 ;;
  esac
  # Use the official maintained key/source package (including the 2025 key
  # rotation), rather than downloading a possibly retired ASCII key.
  if (
    set -Eeuo pipefail
    tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
    asset="${name}_1.3.0.${codename}_all.deb"
    download_file "https://github.com/ros-infrastructure/ros-apt-source/releases/download/1.3.0/$asset" "$tmp/$asset" || exit 1
    verify_sha256 "$tmp/$asset" "$checksum" || exit 1
    validate_deb_package "$tmp/$asset" "$name" all "1.3.0~${codename}" || exit 1
    apt_install "$tmp/$asset" || exit 1
  ); then :; else return 1; fi
  LTG_APT_UPDATED=0
}

install_ros_distribution() {
  local mode="$1" distro
  validate_ros_request "$mode" || return 1
  distro="$(target_ros_distro "$mode")"
  log_install "${mode^^} $distro"
  apt_install locales software-properties-common || return 1
  run_as_root locale-gen en_US.UTF-8 || return 1
  export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
  run_as_root add-apt-repository -y universe || return 1
  LTG_APT_UPDATED=0
  install_ros_source "$mode" || return 1
  # --no-remove guards early Jammy dependency conflicts instead of silently
  # removing desktop/system packages or upgrading the entire operating system.
  if [[ "$mode" == ros1 ]]; then
    log_warn 'ROS 1 Noetic reached end of life in May 2025; upstream security maintenance has ended.'
    apt_install ros-noetic-desktop-full python3-rosdep python3-rosinstall python3-rosinstall-generator python3-wstool build-essential || return 1
  else
    apt_install "ros-${distro}-desktop" ros-dev-tools python3-rosdep || return 1
  fi
  [[ -f "$(_ros_root)/$distro/setup.bash" ]] || { log_error "ROS setup.bash missing after installation"; return 1; }
  setup_rosdep "$mode" || return 1
  _add_ros_env_line "$distro" || return 1
  log_ok "ROS $distro installed; open a new terminal to use it"
}

install_requested_ros() {
  local mode="$1"
  case "$mode" in
    ros1) if detect_ros1; then log_skip "ROS 1 $LTG_DETECTED_ROS1_DISTRO already installed"; return 0; fi ;;
    ros2) if detect_ros2; then log_skip "ROS 2 $LTG_DETECTED_ROS2_DISTRO already installed"; return 0; fi ;;
    *) log_error "Unknown ROS mode: $mode"; return 1 ;;
  esac
  install_ros_distribution "$mode"
}
