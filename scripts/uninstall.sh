#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
BINDIR="${BINDIR:-$PREFIX/bin}"
SYSTEMD_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
REMOVE_SYSTEMD_UNIT=0

usage() {
  cat <<USAGE
Usage: $0 [--remove-systemd-unit]

Uninstalls wrapper scripts from user prefix (default: ~/.local/bin).

Environment variables:
  PREFIX   Install prefix (default: ~/.local)
  BINDIR   Binary dir (default: \$PREFIX/bin)

Options:
  --remove-systemd-unit    Also remove ~/.config/systemd/user/docker.service
  -h, --help               Show this help
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --remove-systemd-unit)
      REMOVE_SYSTEMD_UNIT=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[ERROR] unknown argument: $arg" >&2
      usage >&2
      exit 1
      ;;
  esac
done

remove_if_exists() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    rm -f "$path"
    echo "[INFO] removed $path"
  else
    echo "[INFO] already absent: $path"
  fi
}

remove_if_exists "$BINDIR/dockerd-rootless.sh"
remove_if_exists "$BINDIR/dockerd-rootless-setuptool.sh"

if [[ "$REMOVE_SYSTEMD_UNIT" -eq 1 ]]; then
  UNIT_PATH="$SYSTEMD_DIR/docker.service"
  if command -v systemctl >/dev/null 2>&1; then
    systemctl --user stop docker.service >/dev/null 2>&1 || true
    systemctl --user disable docker.service >/dev/null 2>&1 || true
  fi
  remove_if_exists "$UNIT_PATH"
  if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload >/dev/null 2>&1 || true
  fi
fi

echo "[INFO] uninstall complete"
