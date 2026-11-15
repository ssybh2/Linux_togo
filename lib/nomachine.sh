#!/usr/bin/env bash

nomachine_version() {
  case "$1" in amd64) printf '9.7.3\n' ;; arm64) printf '9.8.3\n' ;; *) return 1 ;; esac
}
NOMACHINE_BUILD="1"
NOMACHINE_RELEASE_BASE_URL="https://github.com/ssybh2/Linux_togo/releases/download/nomachine"

nomachine_asset_name() {
  case "$1" in
    amd64) printf 'nomachine_%s_%s_amd64.deb\n' "$(nomachine_version amd64)" "$NOMACHINE_BUILD" ;;
    arm64) printf 'nomachine_%s_%s_arm64.deb\n' "$(nomachine_version arm64)" "$NOMACHINE_BUILD" ;;
    *) return 1 ;;
  esac
}

nomachine_asset_url() {
  local arch="$1" name
  name="$(nomachine_asset_name "$arch")" || return 1
  case "$arch" in
    amd64) printf 'https://github.com/ssybh2/Linux_togo/releases/download/amd64/%s\n' "$name" ;;
    arm64) printf '%s/%s\n' "$NOMACHINE_RELEASE_BASE_URL" "$name" ;;
    *) return 1 ;;
  esac
}

nomachine_fallback_url() {
  # The former 9.x vendor links redirect to HTML. Do not replace them with
  # Personal Edition 10.x, which has different activation requirements.
  return 1
}

nomachine_asset_sha256() {
  case "$1" in
    # Verified from the ARM64 package stored in the Linux_togo GitHub Release.
    arm64) printf 'be874820b9539e836d44fdfb2311a588253bd192e0e43393d819251e42a057ad\n' ;;
    amd64) printf '81e0f8b48c7a4d3c16dac0401b9d188353e4a237498284d267a05c5176fd95fc\n' ;;
    *) return 1 ;;
  esac
}

nomachine_is_installed() {
  if [[ -n "${LTG_TEST_NOMACHINE_PRESENT:-}" ]]; then
    [[ "$LTG_TEST_NOMACHINE_PRESENT" == "1" ]]
    return
  fi
  package_installed nomachine || [[ -x /usr/NX/bin/nxserver ]]
}

find_nomachine_local_package() {
  local arch="$1" candidate dir expected
  expected="$(nomachine_asset_name "$arch")" || return 1

  if [[ -n "${LINUX_TO_GO_NOMACHINE_DEB:-}" ]]; then
    [[ -f "$LINUX_TO_GO_NOMACHINE_DEB" ]] || return 1
    realpath -- "$LINUX_TO_GO_NOMACHINE_DEB"
    return 0
  fi

  dir="${LTG_NOMACHINE_PACKAGE_DIR:-}"
  if [[ -n "$dir" && -f "$dir/$expected" ]]; then
    realpath -- "$dir/$expected"
    return 0
  fi

  if [[ -n "$dir" ]]; then
    candidate="$(find "$dir" -maxdepth 1 -type f -name "nomachine_*_${arch}.deb" -print -quit 2>/dev/null || true)"
    [[ -n "$candidate" ]] && { realpath -- "$candidate"; return 0; }
  fi
  return 1
}

validate_deb_architecture() {
  validate_deb_package "$1" nomachine "$2"
}

_download_nomachine() {
  local arch="$1" output="$2" primary
  primary="$(nomachine_asset_url "$arch")" || return 1
  download_file "$primary" "$output" || {
    log_error 'NoMachine download failed. Supply a trusted package using LINUX_TO_GO_NOMACHINE_DEB.'; return 1;
  }
  validate_deb_package "$output" nomachine "$arch" "$(nomachine_version "$arch")-${NOMACHINE_BUILD}"
}

preflight_nomachine() {
  nomachine_is_installed && return 0
  local package
  if [[ -n "${LINUX_TO_GO_NOMACHINE_DEB:-}" && ! -f "$LINUX_TO_GO_NOMACHINE_DEB" ]]; then
    log_error "Specified NoMachine package does not exist: $LINUX_TO_GO_NOMACHINE_DEB"
    return 1
  fi
  if package="$(find_nomachine_local_package "$LTG_ARCH")"; then
    validate_deb_architecture "$package" "$LTG_ARCH" || return 1
  else
    nomachine_asset_url "$LTG_ARCH" >/dev/null || return 1
  fi
  return 0
}

install_nomachine() {
  log_check "NoMachine"
  if nomachine_is_installed; then
    log_ok "NoMachine already installed"
    log_skip "NoMachine installation"
    return 0
  fi

  local arch="${LTG_ARCH:?system architecture not detected}" local_pkg="" checksum=""
  if [[ -n "${LINUX_TO_GO_NOMACHINE_DEB:-}" && ! -f "$LINUX_TO_GO_NOMACHINE_DEB" ]]; then
    log_error "Specified NoMachine package does not exist: $LINUX_TO_GO_NOMACHINE_DEB"
    return 1
  fi
  if local_pkg="$(find_nomachine_local_package "$arch" 2>/dev/null)"; then
    log_install "NoMachine from local package: $local_pkg"
    validate_deb_architecture "$local_pkg" "$arch" || return 1
    checksum="$(nomachine_asset_sha256 "$arch")"
    if [[ -n "$checksum" && "$(basename "$local_pkg")" == "$(nomachine_asset_name "$arch")" ]]; then
      verify_sha256 "$local_pkg" "$checksum" || return 1
    fi
    apt_install "$local_pkg" || return 1
    log_ok "NoMachine installed"
    return 0
  fi

  local asset source_label
  asset="$(nomachine_asset_name "$arch")" || { log_error "No NoMachine package for $arch"; return 1; }
  source_label="Linux_togo GitHub Release"
  log_install "NoMachine $(nomachine_version "$arch") ($arch) from ${source_label}"
  if (
    set -Eeuo pipefail
    local_tmp="$(mktemp -d)" || exit 1
    trap 'rm -rf "$local_tmp"' EXIT
    _download_nomachine "$arch" "$local_tmp/$asset" || exit 1
    checksum="$(nomachine_asset_sha256 "$arch")"
    [[ -z "$checksum" ]] || verify_sha256 "$local_tmp/$asset" "$checksum" || exit 1
    apt_install "$local_tmp/$asset" || exit 1
  ); then
    :
  else
    return 1
  fi
  log_ok "NoMachine $(nomachine_version "$arch") installed"
}
