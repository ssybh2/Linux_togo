#!/usr/bin/env bash

CLASH_VERGE_VERSION="2.5.10"
CLASH_VERGE_BASE_URL="https://github.com/ssybh2/Linux_togo/releases/download"

clash_asset_name() {
  case "$1" in
    amd64) printf 'Clash.Verge_%s_amd64.deb\n' "$CLASH_VERGE_VERSION" ;;
    arm64) printf 'Clash.Verge_%s_arm64.deb\n' "$CLASH_VERGE_VERSION" ;;
    *) return 1 ;;
  esac
}

clash_asset_sha256() {
  case "$1" in
    amd64) printf 'add8564811ba4d2305da443288d23a26c5ed19674b676a0bb58b99ec4f7d13cf\n' ;;
    arm64) printf '729c3bdc84207984fd894cc0ff14e6451fc9335060b5c7efbe378a9f4dbdf8fd\n' ;;
    *) return 1 ;;
  esac
}

clash_asset_url() {
  local name tag
  case "$1" in amd64) tag=x64clash ;; arm64) tag=arm64clash ;; *) return 1 ;; esac
  name="$(clash_asset_name "$1")" || return 1
  printf '%s/%s/%s\n' "$CLASH_VERGE_BASE_URL" "$tag" "$name"
}

clash_is_installed() {
  if [[ -n "${LTG_TEST_CLASH_PRESENT:-}" ]]; then
    [[ "$LTG_TEST_CLASH_PRESENT" == "1" ]]
    return
  fi
  package_installed clash-verge || package_installed clash-verge-rev || command_exists clash-verge || [[ -x /usr/bin/clash-verge ]]
}

install_clash_verge() {
  log_check "Clash Verge Rev"
  if clash_is_installed; then
    log_ok "Clash Verge Rev already installed"
    log_skip "Clash Verge Rev installation"
    return 0
  fi

  if [[ "${LTG_UBUNTU_VERSION:-}" == "20.04" ]]; then
    log_error "Release Clash Verge 2.5.10 requires libwebkit2gtk-4.1-0 (Ubuntu 22.04+). Use --skip-clash on 20.04."
    return 1
  fi
  local arch="${LTG_ARCH:?system architecture not detected}"
  local asset url checksum
  asset="$(clash_asset_name "$arch")" || { log_error "No Clash Verge Rev package for $arch"; return 1; }
  url="$(clash_asset_url "$arch")"
  checksum="$(clash_asset_sha256 "$arch")"

  log_install "Clash Verge Rev ${CLASH_VERGE_VERSION} ($arch)"
  if (
    set -Eeuo pipefail
    local_tmp="$(mktemp -d)" || exit 1
    trap 'rm -rf "$local_tmp"' EXIT
    download_file "$url" "$local_tmp/$asset" || exit 1
    verify_sha256 "$local_tmp/$asset" "$checksum" || exit 1
    validate_deb_package "$local_tmp/$asset" clash-verge "$arch" "$CLASH_VERGE_VERSION" || exit 1
    apt_install "$local_tmp/$asset" || exit 1
  ); then
    :
  else
    return 1
  fi
  log_ok "Clash Verge Rev ${CLASH_VERGE_VERSION} installed"
}
