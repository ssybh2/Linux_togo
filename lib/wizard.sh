#!/usr/bin/env bash

print_status() {
  printf 'os\t%s\nversion\t%s\narch\t%s\n' "$LTG_OS_ID" "$LTG_UBUNTU_VERSION" "$LTG_ARCH"
  if detect_ros1; then printf 'ros1\t%s\n' "$LTG_DETECTED_ROS1_DISTRO"; else printf 'ros1\t\n'; fi
  if detect_ros2; then printf 'ros2\t%s\n' "$LTG_DETECTED_ROS2_DISTRO"; else printf 'ros2\t\n'; fi
  if clash_is_installed; then printf 'clash\tinstalled\n'; else printf 'clash\tmissing\n'; fi
  if nomachine_is_installed; then printf 'nomachine\tinstalled\n'; else printf 'nomachine\tmissing\n'; fi
}

print_plan() {
  local mode="$1" skip_clash="$2" skip_nm="$3"
  log_info "Ubuntu $LTG_UBUNTU_VERSION / $LTG_ARCH; mode=$mode"
  if [[ "$skip_clash" == 1 ]]; then log_skip 'Clash Verge';
  elif clash_is_installed; then log_skip 'Clash Verge already installed';
  else
    [[ "$LTG_UBUNTU_VERSION" != 20.04 ]] || { log_error 'Release Clash Verge 2.5.10 needs Ubuntu 22.04+; select --skip-clash on 20.04'; return 1; }
    log_info "Clash Verge $CLASH_VERGE_VERSION: $(clash_asset_url "$LTG_ARCH")"
  fi
  if [[ "$skip_nm" == 1 ]]; then log_skip 'NoMachine';
  elif nomachine_is_installed; then log_skip 'NoMachine already installed';
  else log_info "NoMachine $(nomachine_version "$LTG_ARCH"): $(nomachine_asset_url "$LTG_ARCH")"; fi
  if [[ "$mode" != --apps-only ]]; then
    log_info "Install missing $mode: $(target_ros_distro "$mode") desktop + development tools"
  fi
}

terminal_wizard() {
  local answer
  if detect_ros1 || detect_ros2; then
    log_info 'ROS already detected; keeping the existing environment.' >&2
    printf '%s\n' --apps-only
    return
  fi
  [[ -t 0 ]] || { log_error 'No desktop/terminal available. Use --ros1, --ros2 or --apps-only explicitly.'; return 1; }
  printf '未检测到 ROS。选择 1=ROS1 Noetic (20.04), 2=ROS2 (22.04 Humble / 24.04 Jazzy), 3=仅应用, q=退出: ' >&2
  read -r answer
  case "$answer" in 1) echo ros1 ;; 2) echo ros2 ;; 3) echo --apps-only ;; *) return 1 ;; esac
}
