#!/usr/bin/env bash
#
# install_dev_tools.sh — install Docker, Docker Compose, Python (>=3.9),
# and Django on Ubuntu / Debian. Idempotent: re-running is a no-op when
# tools are already present.
#
# Usage:  sudo ./install_dev_tools.sh
#

set -euo pipefail

if [[ -t 1 ]]; then
  C_BLUE=$'\033[1;34m'; C_GREEN=$'\033[1;32m'; C_YELLOW=$'\033[1;33m'; C_RED=$'\033[1;31m'; C_OFF=$'\033[0m'
else
  C_BLUE=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_OFF=''
fi

log()  { printf '%s[INFO]%s  %s\n' "$C_BLUE"   "$C_OFF" "$*"; }
ok()   { printf '%s[ OK ]%s  %s\n' "$C_GREEN"  "$C_OFF" "$*"; }
warn() { printf '%s[WARN]%s  %s\n' "$C_YELLOW" "$C_OFF" "$*" >&2; }
err()  { printf '%s[FAIL]%s  %s\n' "$C_RED"    "$C_OFF" "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

require_root() {
  [[ $EUID -eq 0 ]] && return
  if have sudo; then
    log "Re-running with sudo..."
    exec sudo --preserve-env=DEBIAN_FRONTEND bash "$0" "$@"
  fi
  err "This script must be run as root (or install sudo)."
  exit 1
}

check_os() {
  if [[ ! -r /etc/os-release ]]; then
    err "/etc/os-release not found — cannot detect distribution."
    exit 1
  fi
  # shellcheck disable=SC1091
  . /etc/os-release
  case "${ID:-}${ID_LIKE:-}" in
    *debian*|*ubuntu*) ok "Detected ${PRETTY_NAME:-$ID}." ;;
    *) err "Unsupported distribution: ${PRETTY_NAME:-$ID}. Ubuntu/Debian only."; exit 1 ;;
  esac
}

apt_install() {
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

python_meets_min() {
  python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3,9) else 1)' 2>/dev/null
}

django_version_for() {
  sudo -u "$1" python3 -c 'import django; print(django.get_version())' 2>/dev/null || true
}

install_docker() {
  if have docker; then
    ok "Docker already installed: $(docker --version)"
    return
  fi

  log "Installing Docker Engine + Compose plugin from the official Docker apt repository..."
  apt_install ca-certificates curl gnupg

  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL "https://download.docker.com/linux/${ID}/gpg" \
    | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  local arch
  arch="$(dpkg --print-architecture)"
  echo \
    "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list

  apt-get update -qq
  apt_install docker-ce docker-ce-cli containerd.io docker-compose-plugin

  systemctl enable --now docker
  ok "Docker installed: $(docker --version)"

  local target_user="${SUDO_USER:-}"
  [[ -z "$target_user" || "$target_user" == "root" ]] && return
  id -nG "$target_user" | tr ' ' '\n' | grep -qx docker && return
  usermod -aG docker "$target_user"
  warn "Added '$target_user' to the 'docker' group. Log out / log in for it to take effect."
}

# Provides the legacy `docker-compose` command name as a thin shim over the
# `docker compose` plugin (apt-installed alongside docker-ce). The standalone
# v2 binary is unmaintained upstream; the plugin is the supported path.
install_docker_compose() {
  if have docker-compose; then
    ok "Docker Compose already installed: $(docker-compose version --short)"
    return
  fi
  if ! docker compose version >/dev/null 2>&1; then
    log "Installing docker-compose-plugin..."
    apt_install docker-compose-plugin
  fi
  log "Creating /usr/local/bin/docker-compose shim..."
  cat > /usr/local/bin/docker-compose <<'SHIM'
#!/bin/sh
exec docker compose "$@"
SHIM
  chmod +x /usr/local/bin/docker-compose
  ok "Docker Compose available: $(docker-compose version --short)"
}

install_python() {
  if have python3 && python_meets_min; then
    ok "Python already installed: $(python3 --version)"
  else
    log "Installing Python 3 (>= 3.9)..."
    apt_install python3 python3-venv
    if ! python_meets_min; then
      err "Installed python3 is older than 3.9. Consider the deadsnakes PPA."
      exit 1
    fi
    ok "Python installed: $(python3 --version)"
  fi

  if ! have pip3; then
    log "Installing pip..."
    apt_install python3-pip
  fi
  ok "pip available: $(pip3 --version)"
}

install_django() {
  local target_user="${SUDO_USER:-root}"

  local v
  v="$(django_version_for "$target_user")"
  if [[ -n "$v" ]]; then
    ok "Django already installed for '$target_user': $v"
    return
  fi

  log "Installing Django via pip for user '$target_user'..."
  # PEP 668 marks the system Python as "externally managed" on Ubuntu 23.04+ /
  # Debian 12+, so a global-feeling `pip install` needs --break-system-packages
  # there. Older releases (e.g. Jammy 22.04) ship pip < 23.0.1, which doesn't
  # know the flag — and don't enforce PEP 668 anyway. Probe pip rather than
  # branching on distro version.
  local pip_args=(--user)
  if sudo -u "$target_user" pip3 install --help 2>/dev/null | grep -q -- '--break-system-packages'; then
    pip_args+=(--break-system-packages)
  fi
  sudo -u "$target_user" pip3 install "${pip_args[@]}" django

  v="$(django_version_for "$target_user")"
  if [[ -z "$v" ]]; then
    err "Django installation reported success but 'import django' fails."
    exit 1
  fi
  ok "Django installed: $v"
}

main() {
  require_root "$@"
  check_os
  log "Refreshing apt metadata..."
  apt-get update -qq
  install_docker
  install_docker_compose
  install_python
  install_django
  echo
  ok "All dev tools are installed and ready."
}

main "$@"
