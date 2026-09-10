#!/usr/bin/env bash

NOMACHINE_VERSION="9.8.3"
NOMACHINE_BUILD="1"
NOMACHINE_RELEASE_BASE_URL="https://github.com/ssybh2/Linux_togo/releases/download/nomachine"

nomachine_asset_name() {
  case "$1" in
    amd64) printf 'nomachine_%s_%s_amd64.deb\n' "$NOMACHINE_VERSION" "$NOMACHINE_BUILD" ;;
    arm64) printf 'nomachine_%s_%s_arm64.deb\n' "$NOMACHINE_VERSION" "$NOMACHINE_BUILD" ;;
    *) return 1 ;;
  esac
}

nomachine_asset_url() {
  local arch="$1" name
  name="$(nomachine_asset_name "$arch")" || return 1
  case "$arch" in
    amd64) printf 'https://download.nomachine.com/download/9.8/Linux/%s\n' "$name" ;;
    arm64) printf '%s/%s\n' "$NOMACHINE_RELEASE_BASE_URL" "$name" ;;
    *) return 1 ;;
  esac
}

nomachine_fallback_url() {
  local arch="$1" name
  name="$(nomachine_asset_name "$arch")" || return 1
  case "$arch" in
    amd64) printf 'https://web9001.nomachine.com/download/9.8/Linux/%s\n' "$name" ;;
    arm64) printf 'https://web9001.nomachine.com/download/9.8/Arm/%s\n' "$name" ;;
    *) return 1 ;;
  esac
}

nomachine_asset_sha256() {
  case "$1" in
    # Verified from the ARM64 package stored in the Linux_togo GitHub Release.
    arm64) printf 'be874820b9539e836d44fdfb2311a588253bd192e0e43393d819251e42a057ad\n' ;;
    # No independently verified SHA-256 is encoded for amd64.
    amd64) printf '\n' ;;
    *) return 1 ;;
  esac
}

nomachine_is_installed() {
  if [[ -n "${LTG_TEST_NOMACHINE_PRESENT:-}" ]]; then
    [[ "$LTG_TEST_NOMACHINE_PRESENT" == "1" ]]
    return
  fi
  package_installed nomachine || [[ -x /usr/NX/bin/nxserver ]] || [[ -x /usr/NX/bin/nxplayer ]]
}

find_nomachine_local_package() {
  local arch="$1" candidate dir expected
  expected="$(nomachine_asset_name "$arch")" || return 1

  if [[ -n "${LINUX_TO_GO_NOMACHINE_DEB:-}" ]]; then
    [[ -f "$LINUX_TO_GO_NOMACHINE_DEB" ]] || return 1
    printf '%s\n' "$LINUX_TO_GO_NOMACHINE_DEB"
    return 0
  fi

  dir="${LTG_NOMACHINE_PACKAGE_DIR:-}"
  if [[ -n "$dir" && -f "$dir/$expected" ]]; then
    printf '%s\n' "$dir/$expected"
    return 0
  fi

  if [[ -n "$dir" ]]; then
    candidate="$(find "$dir" -maxdepth 1 -type f -name 'nomachine_*_*.deb' -print -quit 2>/dev/null || true)"
    [[ -n "$candidate" ]] && { printf '%s\n' "$candidate"; return 0; }
  fi
  return 1
}

validate_deb_architecture() {
  local package="$1" expected_arch="$2" actual_arch
  actual_arch="$(dpkg-deb -f "$package" Architecture 2>/dev/null)" || {
    log_error "Unable to read Debian package metadata: $package"
    return 1
  }
  [[ "$actual_arch" == "$expected_arch" ]] || {
    log_error "NoMachine package architecture mismatch: package=$actual_arch host=$expected_arch"
    return 1
  }
}

_download_nomachine() {
  local arch="$1" output="$2" primary fallback
  primary="$(nomachine_asset_url "$arch")"
  fallback="$(nomachine_fallback_url "$arch")"
  if download_file "$primary" "$output"; then
    return 0
  fi
  log_warn "Primary NoMachine endpoint failed; trying the official fallback endpoint."
  download_file "$fallback" "$output"
}

install_nomachine() {
  log_check "NoMachine"
  if nomachine_is_installed; then
    log_ok "NoMachine already installed"
    log_skip "NoMachine installation"
    return 0
  fi

  local arch="${LTG_ARCH:?system architecture not detected}" local_pkg="" checksum=""
  if local_pkg="$(find_nomachine_local_package "$arch" 2>/dev/null)"; then
    log_install "NoMachine from local package: $local_pkg"
    validate_deb_architecture "$local_pkg" "$arch"
    checksum="$(nomachine_asset_sha256 "$arch")"
    if [[ -n "$checksum" && "$(basename "$local_pkg")" == "$(nomachine_asset_name "$arch")" ]]; then
      verify_sha256 "$local_pkg" "$checksum"
    fi
    run_as_root apt-get install -y "$local_pkg"
    log_ok "NoMachine installed"
    return 0
  fi

  local asset source_label
  asset="$(nomachine_asset_name "$arch")" || { log_error "No NoMachine package for $arch"; return 1; }
  source_label="official NoMachine download service"
  [[ "$arch" == "arm64" ]] && source_label="Linux_togo GitHub Release"
  log_install "NoMachine ${NOMACHINE_VERSION} ($arch) from ${source_label}"
  (
    set -Eeuo pipefail
    local_tmp="$(mktemp -d)"
    trap 'rm -rf "$local_tmp"' EXIT
    _download_nomachine "$arch" "$local_tmp/$asset"
    validate_deb_architecture "$local_tmp/$asset" "$arch"
    checksum="$(nomachine_asset_sha256 "$arch")"
    [[ -z "$checksum" ]] || verify_sha256 "$local_tmp/$asset" "$checksum"
    run_as_root apt-get install -y "$local_tmp/$asset"
  )
  log_ok "NoMachine ${NOMACHINE_VERSION} installed"
}
