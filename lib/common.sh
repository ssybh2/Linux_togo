#!/usr/bin/env bash

LTG_APT_UPDATED="${LTG_APT_UPDATED:-0}"

log_info()    { printf '[INFO] %s\n' "$*"; }
log_check()   { printf '[CHECK] %s\n' "$*"; }
log_ok()      { printf '[OK] %s\n' "$*"; }
log_skip()    { printf '[SKIP] %s\n' "$*"; }
log_install() { printf '[INSTALL] %s\n' "$*"; }
log_warn()    { printf '[WARN] %s\n' "$*" >&2; }
log_error()   { printf '[ERROR] %s\n' "$*" >&2; }

die() { log_error "$*"; return 1; }
command_exists() { command -v "$1" >/dev/null 2>&1; }

run_as_root() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    "$@"
  else
    command_exists sudo || { log_error "sudo is required for installation."; return 1; }
    sudo "$@"
  fi
}

package_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'
}

apt_update_once() {
  if [[ "$LTG_APT_UPDATED" != "1" ]]; then
    run_as_root apt-get update
    LTG_APT_UPDATED=1
  fi
}

apt_install() {
  apt_update_once
  run_as_root apt-get install -y "$@"
}

download_file() {
  local url="$1" output="$2"
  curl -fL --retry 3 --retry-delay 2 --connect-timeout 20 "$url" -o "$output"
}

verify_sha256() {
  local file="$1" expected="$2" actual
  actual="$(sha256sum "$file" | awk '{print $1}')"
  [[ "$actual" == "$expected" ]] || {
    log_error "SHA-256 mismatch for $file"
    log_error "Expected: $expected"
    log_error "Actual:   $actual"
    return 1
  }
}

invoking_user() {
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    printf '%s\n' "$SUDO_USER"
  else
    id -un
  fi
}

invoking_home() {
  local user home
  user="$(invoking_user)"
  home="$(getent passwd "$user" 2>/dev/null | cut -d: -f6)"
  [[ -n "$home" ]] || home="${HOME:-}"
  printf '%s\n' "$home"
}

add_line_once() {
  local line="$1" file="$2"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  grep -Fqx "$line" "$file" 2>/dev/null || printf '\n%s\n' "$line" >> "$file"
}

install_common_packages() {
  if [[ "${LTG_TEST_SKIP_COMMON:-0}" == "1" ]]; then
    log_skip "Common bootstrap packages (test override)"
    return 0
  fi
  log_check "Common bootstrap packages"
  apt_install ca-certificates curl wget gnupg lsb-release software-properties-common build-essential git
  log_ok "Common bootstrap packages ready"
}
