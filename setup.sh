#!/usr/bin/env bash
# Run from a terminal as your normal desktop user; system changes happen only
# after pressing Start in the UI. GTK/Qt/ROS are not prerequisites for this UI.
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Reject unsupported machines before bootstrapping GUI dependencies.
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/system.sh"
detect_system
validate_supported_system
if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then exec "$ROOT_DIR/bin/linux-to-go" --help; fi
if [[ "${1:-}" == --check || "${1:-}" == --status || "${1:-}" == --auto || "${1:-}" == --ros1 || "${1:-}" == --ros2 || "${1:-}" == --apps-only ]]; then
  exec "$ROOT_DIR/bin/linux-to-go" "$@"
fi
if [[ "${1:-}" == --gui ]]; then shift; fi
if [[ ! -e /etc/os-release ]] || ! command -v apt-get >/dev/null; then
  echo '[ERROR] 此程序需要 Ubuntu 和 APT。' >&2; exit 1
fi
if ! /usr/bin/python3 -c 'import tkinter' >/dev/null 2>&1; then
  if [[ ! -t 0 ]]; then echo '[ERROR] 请从终端运行 ./setup.sh，首次需安装 python3-tk。' >&2; exit 1; fi
  echo '[INFO] 首次运行需要安装图形界面依赖 python3-tk（约数 MB）。'
  if [[ "$*" == *--dry-run* ]]; then echo '[ERROR] 预览模式不会安装依赖；可改用 --apps-only --dry-run。' >&2; exit 1; fi
  if [[ "$EUID" == 0 ]]; then apt-get update; apt-get install --no-remove -y python3 python3-tk;
  else sudo apt-get update; sudo apt-get install --no-remove -y python3 python3-tk; fi
fi
exec "$ROOT_DIR/bin/linux-to-go" --gui "$@"
