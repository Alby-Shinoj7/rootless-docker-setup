# rootless-docker-setup

`rootless-docker-setup` is a **wrapper-only** project for setting up Docker in rootless mode using upstream helper scripts.

It provides:
- `dockerd-rootless-setuptool.sh` (prerequisite checks + install/uninstall workflow)
- `dockerd-rootless.sh` (launcher wrapper for `dockerd` via `rootlesskit`)
- user-level install/uninstall helpers for this repo (`scripts/install.sh`, `scripts/uninstall.sh`)
- CI and smoke tests for baseline quality

It **does not** ship Docker engine binaries.

## Why wrapper-only (and not a binary bundle)

This repository intentionally depends on system-installed Docker/rootless components. Shipping `docker`/`dockerd` binaries in this repo would require a secure release pipeline (version pinning, checksums, provenance/SLSA-style attestation, multi-arch distribution), which is outside the current scope.

Wrapper-only keeps the project safer and easier to maintain while still solving setup ergonomics.

## Assumptions

- Default shell: Bash (`/usr/bin/env bash` for project scripts)
- Default install prefix: `~/.local`
- Default binary directory: `~/.local/bin`
- Optional systemd user unit location: `~/.config/systemd/user/docker.service`
- Target systems: mainstream Linux distros with rootless Docker prerequisites available from distro packages

## Prerequisites

You need Docker rootless prerequisites installed on the host. The setup tool validates many of these and prints remediation commands.

Typical requirements:
- `newuidmap` + `newgidmap` (usually from `uidmap` or `shadow-utils` package)
- `/etc/subuid` and `/etc/subgid` entries for your user
- `rootlesskit`
- one supported user-mode networking backend:
  - `slirp4netns` (preferred if modern enough)
  - or `vpnkit`
  - (optional/advanced) `pasta`, `lxc-user-nic`
- `iptables` support (unless intentionally skipped)
- kernel settings enabling unprivileged namespaces on some distros

> The setup tool can print distro-specific commands when requirements are missing.

## Install (user-level, no root)

From repository root:

```bash
make install
```

Equivalent manual form:

```bash
./scripts/install.sh
```

Install with custom prefix:

```bash
PREFIX="$HOME/.local" ./scripts/install.sh
```

Install helper scripts + optional user systemd unit template:

```bash
./scripts/install.sh --install-systemd-unit
```

## Run checks

From repository root:

```bash
./dockerd-rootless-setuptool.sh check
```

If installed into `~/.local/bin`:

```bash
dockerd-rootless-setuptool.sh check
```

## Setup rootless Docker

### 1) Validate prerequisites

```bash
./dockerd-rootless-setuptool.sh check
```

### 2) Install rootless Docker user service/context

```bash
./dockerd-rootless-setuptool.sh install
```

### 3) If systemd user session is available, manage service

```bash
systemctl --user start docker
systemctl --user status docker
```

### 4) Use rootless Docker CLI context

```bash
docker context use rootless
docker info
```

### 5) Switch back to default (rootful/other) context

```bash
docker context use default
```

## Uninstall

Uninstall repo-provided wrappers from your user prefix:

```bash
make uninstall
# or
./scripts/uninstall.sh
```

Uninstall wrapper scripts + optional user unit file:

```bash
./scripts/uninstall.sh --remove-systemd-unit
```

If you also want to remove rootless Docker setup created by upstream setuptool:

```bash
dockerd-rootless-setuptool.sh uninstall
```

## Make targets

```bash
make help
make check
make lint
make smoke-test
make install
make uninstall
```

## Troubleshooting

### `Refusing to install rootless Docker as the root user`
Run as a non-root user. Rootless mode is designed for unprivileged users.

### `newuidmap binary not found`
Install `uidmap` (Debian/Ubuntu) or `shadow-utils` (RHEL/Fedora family).

### Missing `/etc/subuid` or `/etc/subgid` entry
Add ranges for your user (requires root), e.g.:

```text
<user>:100000:65536
```

### `iptables binary not found`
Install iptables via distro package manager, or run with `--skip-iptables` if you intentionally accept reduced networking behavior.

### `XDG_RUNTIME_DIR ... not set/writable`
Usually means you switched users via `sudo`/`su` without proper user session env. Log in directly as target user or set up lingering with `loginctl enable-linger <user>`.

### `rootlesskit needs to be installed`
Install rootlesskit package and ensure it is on `PATH`.

### `Either slirp4netns (>= v0.4.0) or vpnkit needs to be installed`
Install one of those networking backends. `slirp4netns` is the usual choice.

## Limitations

- No Docker binaries are distributed by this repo.
- Host configuration for `/etc/subuid`, `/etc/subgid`, and some sysctls may require root/admin changes.
- Actual Docker daemon startup depends on system packages and host kernel/userns capabilities.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
