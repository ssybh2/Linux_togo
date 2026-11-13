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
    run_as_root apt-get update || return 1
    LTG_APT_UPDATED=1
  fi
}

apt_install() {
  apt_update_once || return 1
  run_as_root apt-get install -y --no-install-recommends -o DPkg::Lock::Timeout=120 "$@"
}

download_file() {
  local url="$1" output="$2"
  curl -fL --retry 3 --retry-delay 2 --connect-timeout 20 "$url" -o "$output"
}

validate_deb_package() {
  local package="$1" expected_name="$2" expected_arch="$3" expected_version="${4:-}"
  local name arch version
  name="$(dpkg-deb -f "$package" Package 2>/dev/null)" || { log_error "Not a valid DEB (download may be an HTML page): $package"; return 1; }
  arch="$(dpkg-deb -f "$package" Architecture 2>/dev/null)" || return 1
  version="$(dpkg-deb -f "$package" Version 2>/dev/null)" || return 1
  [[ "$name" == "$expected_name" && "$arch" == "$expected_arch" ]] || {
    log_error "Wrong package: expected $expected_name/$expected_arch, got $name/$arch"; return 1;
  }
  [[ -z "$expected_version" || "$version" == "$expected_version" ]] || {
    log_error "Wrong version: expected $expected_version, got $version"; return 1;
  }
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
  local package
  local packages=(ca-certificates curl) missing=()
  if [[ "${1:-}" != "--apps-only" ]]; then
    packages+=(wget gnupg lsb-release software-properties-common build-essential git)
  fi
  for package in "${packages[@]}"; do
    package_installed "$package" || missing+=("$package")
  done
  if (( ${#missing[@]} )); then apt_install "${missing[@]}" || return 1; fi
  log_ok "Common bootstrap packages ready"
}
