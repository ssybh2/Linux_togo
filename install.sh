#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_BIN="/usr/local/bin/linux-to-go"
TARGET_LIB="/usr/local/lib/linux-to-go"

as_root() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    "$@"
  else
    command -v sudo >/dev/null 2>&1 || { printf '[ERROR] sudo is required.\n' >&2; exit 1; }
    sudo "$@"
  fi
}

for required in "$ROOT_DIR/bin/linux-to-go" "$ROOT_DIR/lib/common.sh" "$ROOT_DIR/lib/system.sh" "$ROOT_DIR/lib/clash-verge.sh" "$ROOT_DIR/lib/nomachine.sh" "$ROOT_DIR/lib/ros.sh" "$ROOT_DIR/lib/wizard.sh" "$ROOT_DIR/lib/installer_gui.py" "$ROOT_DIR/lib/sudo_askpass.py"; do
  [[ -f "$required" ]] || { printf '[ERROR] Missing repository file: %s\n' "$required" >&2; exit 1; }
done

printf '[INSTALL] Installing Linux To Go CLI\n'
as_root install -d -m 0755 "$(dirname "$TARGET_BIN")" "$TARGET_LIB"
as_root install -m 0755 "$ROOT_DIR/bin/linux-to-go" "$TARGET_BIN"
as_root install -m 0644 "$ROOT_DIR/lib/common.sh" "$TARGET_LIB/common.sh"
as_root install -m 0644 "$ROOT_DIR/lib/system.sh" "$TARGET_LIB/system.sh"
as_root install -m 0644 "$ROOT_DIR/lib/clash-verge.sh" "$TARGET_LIB/clash-verge.sh"
as_root install -m 0644 "$ROOT_DIR/lib/nomachine.sh" "$TARGET_LIB/nomachine.sh"
as_root install -m 0644 "$ROOT_DIR/lib/ros.sh" "$TARGET_LIB/ros.sh"
as_root install -m 0644 "$ROOT_DIR/lib/wizard.sh" "$TARGET_LIB/wizard.sh"
as_root install -m 0644 "$ROOT_DIR/lib/installer_gui.py" "$TARGET_LIB/installer_gui.py"
as_root install -m 0755 "$ROOT_DIR/lib/sudo_askpass.py" "$TARGET_LIB/sudo_askpass.py"
printf '[OK] Installed %s\n' "$TARGET_BIN"
printf 'Next: ./setup.sh  # graphical installer (from cloned repository)\n'
printf '   or: linux-to-go --apps-only\n'
printf '   or: linux-to-go -ros1   # Ubuntu 20.04\n'
printf '   or: linux-to-go -ros2   # Ubuntu 22.04\n'
