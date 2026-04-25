#!/usr/bin/env bash
#
# install_dev_tools.sh — install Docker, Docker Compose, Python (>=3.9),
# and Django on Ubuntu / Debian. Idempotent: re-running is a no-op when
# tools are already present.
#
# Usage:  sudo ./install_dev_tools.sh
#

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

readonly REQUIRED_PYTHON_MAJOR=3
readonly REQUIRED_PYTHON_MINOR=9

log()  { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
ok()   { printf '\033[1;32m[ OK ]\033[0m  %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*" >&2; }
err()  { printf '\033[1;31m[FAIL]\033[0m  %s\n' "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

# Re-exec under sudo if not root. Anything that touches apt / systemd needs it.
require_root() {
  if [[ $EUID -ne 0 ]]; then
    if have sudo; then
      log "Re-running with sudo..."
      exec sudo --preserve-env=DEBIAN_FRONTEND bash "$0" "$@"
    else
      err "This script must be run as root (or install sudo)."
      exit 1
    fi
  fi
}

# Sanity-check the OS. The script targets Debian-family distros only.
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

# Refresh apt metadata at most once per run.
APT_UPDATED=0
apt_update_once() {
  if (( APT_UPDATED == 0 )); then
    log "apt-get update..."
    DEBIAN_FRONTEND=noninteractive apt-get update -qq
    APT_UPDATED=1
  fi
}

apt_install() {
  apt_update_once
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

# ---------------------------------------------------------------------------
# Docker
# ---------------------------------------------------------------------------

install_docker() {
  if have docker; then
    ok "Docker already installed: $(docker --version)"
    return
  fi

  log "Installing Docker Engine from the official Docker apt repository..."

  # Prerequisites for adding a third-party apt repo over HTTPS.
  apt_install ca-certificates curl gnupg

  # Add Docker's GPG key (idempotent — install -m overwrites cleanly).
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/"$ID"/gpg \
    | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  # Add the Docker apt source. VERSION_CODENAME comes from /etc/os-release.
  local arch
  arch="$(dpkg --print-architecture)"
  echo \
    "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list

  APT_UPDATED=0  # force re-update so the new repo is picked up
  apt_install docker-ce docker-ce-cli containerd.io

  systemctl enable --now docker
  ok "Docker installed: $(docker --version)"

  # Convenience: let the invoking user run docker without sudo.
  local target_user="${SUDO_USER:-}"
  if [[ -n "$target_user" && "$target_user" != "root" ]]; then
    if ! id -nG "$target_user" | tr ' ' '\n' | grep -qx docker; then
      usermod -aG docker "$target_user"
      warn "Added '$target_user' to the 'docker' group. Log out / log in for it to take effect."
    fi
  fi
}

# ---------------------------------------------------------------------------
# Docker Compose
#
# We install the standalone v2 binary (`docker-compose`) for backward-compatible
# CLI use. The modern way is `docker compose` (plugin) — already provided by
# docker-ce-cli's compose plugin if available, but this script targets the
# legacy command name to match the assignment.
# ---------------------------------------------------------------------------

install_docker_compose() {
  if have docker-compose; then
    ok "Docker Compose already installed: $(docker-compose version --short 2>/dev/null || docker-compose --version)"
    return
  fi

  log "Installing Docker Compose (standalone)..."

  local version dest
  # Pin a known-good v2 release. Override with COMPOSE_VERSION=v2.x.y if needed.
  version="${COMPOSE_VERSION:-v2.27.0}"
  dest="/usr/local/bin/docker-compose"

  curl -fsSL \
    "https://github.com/docker/compose/releases/download/${version}/docker-compose-$(uname -s)-$(uname -m)" \
    -o "$dest"
  chmod +x "$dest"

  ok "Docker Compose installed: $(docker-compose version --short 2>/dev/null || docker-compose --version)"
}

# ---------------------------------------------------------------------------
# Python (>= 3.9)
# ---------------------------------------------------------------------------

python_version_ok() {
  local bin="$1"
  have "$bin" || return 1
  "$bin" - <<PY
import sys
sys.exit(0 if sys.version_info >= (${REQUIRED_PYTHON_MAJOR}, ${REQUIRED_PYTHON_MINOR}) else 1)
PY
}

install_python() {
  if python_version_ok python3; then
    ok "Python already installed: $(python3 --version)"
  else
    log "Installing Python 3 (>= ${REQUIRED_PYTHON_MAJOR}.${REQUIRED_PYTHON_MINOR})..."
    apt_install python3 python3-venv
    if ! python_version_ok python3; then
      err "Installed python3 is older than ${REQUIRED_PYTHON_MAJOR}.${REQUIRED_PYTHON_MINOR}. Consider the deadsnakes PPA."
      exit 1
    fi
    ok "Python installed: $(python3 --version)"
  fi

  # pip is a separate package on Debian/Ubuntu and is needed for Django.
  if ! have pip3; then
    log "Installing pip..."
    apt_install python3-pip
  fi
  ok "pip available: $(pip3 --version)"
}

# ---------------------------------------------------------------------------
# Django
# ---------------------------------------------------------------------------

install_django() {
  # Resolve the user we should pip-install for. System-wide pip on modern
  # Debian/Ubuntu is blocked by PEP 668; install for the invoking user instead.
  local target_user="${SUDO_USER:-root}"

  local check
  check="$(sudo -u "$target_user" python3 -c 'import django; print(django.get_version())' 2>/dev/null || true)"
  if [[ -n "$check" ]]; then
    ok "Django already installed for '$target_user': $check"
    return
  fi

  log "Installing Django via pip for user '$target_user'..."
  # --break-system-packages is required on Ubuntu 23.04+ / Debian 12+ where
  # PEP 668 marks the system Python as "externally managed".
  sudo -u "$target_user" pip3 install --user --break-system-packages django

  check="$(sudo -u "$target_user" python3 -c 'import django; print(django.get_version())' 2>/dev/null || true)"
  if [[ -z "$check" ]]; then
    err "Django installation reported success but 'import django' fails."
    exit 1
  fi
  ok "Django installed: $check"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  require_root "$@"
  check_os
  install_docker
  install_docker_compose
  install_python
  install_django
  echo
  ok "All dev tools are installed and ready."
}

main "$@"
