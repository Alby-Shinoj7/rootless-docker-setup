#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
BINDIR="${BINDIR:-$PREFIX/bin}"
SYSTEMD_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
INSTALL_SYSTEMD_UNIT=0

usage() {
  cat <<USAGE
Usage: $0 [--install-systemd-unit]

Installs wrapper scripts into a user prefix (default: ~/.local/bin).

Environment variables:
  PREFIX   Install prefix (default: ~/.local)
  BINDIR   Binary dir (default: \$PREFIX/bin)

Options:
  --install-systemd-unit   Also install ~/.config/systemd/user/docker.service
  -h, --help               Show this help
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --install-systemd-unit)
      INSTALL_SYSTEMD_UNIT=1
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

mkdir -p "$BINDIR"

install_file() {
  local src="$1"
  local dst="$2"
  install -m 0755 "$src" "$dst"
  echo "[INFO] installed $dst"
}

install_file "dockerd-rootless.sh" "$BINDIR/dockerd-rootless.sh"
install_file "dockerd-rootless-setuptool.sh" "$BINDIR/dockerd-rootless-setuptool.sh"

if [[ "$INSTALL_SYSTEMD_UNIT" -eq 1 ]]; then
  mkdir -p "$SYSTEMD_DIR"
  UNIT_PATH="$SYSTEMD_DIR/docker.service"
  cat > "$UNIT_PATH" <<UNIT
[Unit]
Description=Docker Application Container Engine (Rootless Wrapper)
Documentation=https://docs.docker.com/go/rootless/
After=network.target

[Service]
Type=simple
Environment=PATH=$BINDIR:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=$BINDIR/dockerd-rootless.sh
Restart=on-failure
RestartSec=2
Delegate=yes
KillMode=mixed

[Install]
WantedBy=default.target
UNIT
  echo "[INFO] installed $UNIT_PATH"
  if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload || true
    echo "[INFO] systemd user daemon reloaded (if available)"
  fi
fi

echo "[INFO] install complete"
echo "[INFO] ensure '$BINDIR' is in PATH"
