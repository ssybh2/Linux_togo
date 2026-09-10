#!/usr/bin/env bash

CLASH_VERGE_VERSION="2.5.2"
CLASH_VERGE_BASE_URL="https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v${CLASH_VERGE_VERSION}"

clash_asset_name() {
  case "$1" in
    amd64) printf 'Clash.Verge_%s_amd64.deb\n' "$CLASH_VERGE_VERSION" ;;
    arm64) printf 'Clash.Verge_%s_arm64.deb\n' "$CLASH_VERGE_VERSION" ;;
    *) return 1 ;;
  esac
}

clash_asset_sha256() {
  case "$1" in
    amd64) printf '035c83ed14b16df1dd397e5d710b34bedd5d27beb6678549ceaeeadf9bc167ed\n' ;;
    arm64) printf '598a5a852d7bf9dc40a976780ef2afc9a4e5bfe7b99533e5f956f9e2f9def72f\n' ;;
    *) return 1 ;;
  esac
}

clash_asset_url() {
  local name
  name="$(clash_asset_name "$1")" || return 1
  printf '%s/%s\n' "$CLASH_VERGE_BASE_URL" "$name"
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

  local arch="${LTG_ARCH:?system architecture not detected}"
  local asset url checksum
  asset="$(clash_asset_name "$arch")" || { log_error "No Clash Verge Rev package for $arch"; return 1; }
  url="$(clash_asset_url "$arch")"
  checksum="$(clash_asset_sha256 "$arch")"

  log_install "Clash Verge Rev ${CLASH_VERGE_VERSION} ($arch)"
  (
    set -Eeuo pipefail
    local_tmp="$(mktemp -d)"
    trap 'rm -rf "$local_tmp"' EXIT
    download_file "$url" "$local_tmp/$asset"
    verify_sha256 "$local_tmp/$asset" "$checksum"
    run_as_root apt-get install -y "$local_tmp/$asset"
  )
  log_ok "Clash Verge Rev ${CLASH_VERGE_VERSION} installed"
}
