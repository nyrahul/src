#!/usr/bin/env bash
set -euo pipefail

# Defaults match the install script (override via env vars if needed)
REC_GROUP="${REC_GROUP:-recorded}"
WRAPPER_PATH="${WRAPPER_PATH:-/usr/local/bin/recorded-shell}"
LOG_ROOT="${LOG_ROOT:-/var/log/ssh-script}"
SSHD_DROPIN_FILE="${SSHD_DROPIN_FILE:-/etc/ssh/sshd_config.d/50-recorded-shell.conf}"
SSH_BANNER_FILE="${SSH_BANNER_FILE:-/etc/ssh/ssh_recorded_banner.txt}"

PURGE_LOGS="false"
if [[ "${1:-}" == "--purge-logs" ]]; then
  PURGE_LOGS="true"
fi

log() { echo "[$(date +%H:%M:%S)] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }
cmd_exists() { command -v "$1" >/dev/null 2>&1; }

need_root() { [[ "${EUID:-$(id -u)}" -eq 0 ]] || die "Run as root (use sudo)."; }

find_sshd_bin() {
  for p in /usr/sbin/sshd /sbin/sshd /usr/local/sbin/sshd; do
    [[ -x "$p" ]] && { echo "$p"; return; }
  done
  cmd_exists sshd && command -v sshd || true
}

reload_sshd() {
  if cmd_exists systemctl; then
    if systemctl list-unit-files 2>/dev/null | grep -qE '^sshd\.service'; then
      log "Reloading sshd (systemd)..."
      systemctl reload sshd || systemctl restart sshd
      return
    fi
    if systemctl list-unit-files 2>/dev/null | grep -qE '^ssh\.service'; then
      log "Reloading ssh (systemd)..."
      systemctl reload ssh || systemctl restart ssh
      return
    fi
  fi
  if cmd_exists service; then
    if service sshd status >/dev/null 2>&1; then
      log "Reloading sshd (service)..."
      service sshd reload || service sshd restart
      return
    fi
    if service ssh status >/dev/null 2>&1; then
      log "Reloading ssh (service)..."
      service ssh reload || service ssh restart
      return
    fi
  fi
  die "Could not reload SSH automatically. Please reload/restart sshd manually."
}

need_root

SSHD_BIN="$(find_sshd_bin)"
[[ -n "${SSHD_BIN:-}" ]] || die "sshd not found. If SSH is managed differently, remove files manually."

log "Uninstalling recorded SSH components..."

# Remove sshd drop-in
if [[ -f "$SSHD_DROPIN_FILE" ]]; then
  log "Removing sshd drop-in: $SSHD_DROPIN_FILE"
  rm -f "$SSHD_DROPIN_FILE"
else
  log "sshd drop-in not found (ok): $SSHD_DROPIN_FILE"
fi

# Remove banner file (only if it looks like ours)
if [[ -f "$SSH_BANNER_FILE" ]]; then
  if grep -q "UNAUTHORIZED ACCESS IS STRICTLY PROHIBITED" "$SSH_BANNER_FILE" 2>/dev/null; then
    log "Removing banner file: $SSH_BANNER_FILE"
    rm -f "$SSH_BANNER_FILE"
  else
    log "Banner file exists but doesn't match expected content; leaving it in place: $SSH_BANNER_FILE"
    log "If you want to remove it anyway, delete it manually."
  fi
else
  log "Banner file not found (ok): $SSH_BANNER_FILE"
fi

# Remove wrapper
if [[ -f "$WRAPPER_PATH" ]]; then
  log "Removing wrapper: $WRAPPER_PATH"
  rm -f "$WRAPPER_PATH"
else
  log "Wrapper not found (ok): $WRAPPER_PATH"
fi

# Optionally purge logs
if [[ "$PURGE_LOGS" == "true" ]]; then
  if [[ -d "$LOG_ROOT" ]]; then
    log "Purging logs: $LOG_ROOT"
    rm -rf "$LOG_ROOT"
  else
    log "Log directory not found (ok): $LOG_ROOT"
  fi
else
  log "Keeping logs at $LOG_ROOT (use --purge-logs to delete)"
fi

# Validate sshd config and reload
log "Validating sshd configuration..."
"$SSHD_BIN" -t || die "sshd config validation failed after uninstall. Check your sshd_config includes."

reload_sshd

# Optionally remove group if empty
if getent group "$REC_GROUP" >/dev/null 2>&1; then
  # Check if any user still has this as a supplementary group
  if getent passwd | awk -F: '{print $1}' | while read -r u; do id -nG "$u" 2>/dev/null | tr ' ' '\n' | grep -qx "$REC_GROUP" && echo "$u"; done | grep -q .; then
    log "Group '$REC_GROUP' is still in use by some users; not removing it."
  else
    log "Removing group '$REC_GROUP' (not in use)..."
    groupdel "$REC_GROUP" || log "Could not remove group '$REC_GROUP' (ok)."
  fi
else
  log "Group '$REC_GROUP' not found (ok)."
fi

log "Uninstall complete."
echo
echo "If you previously modified /etc/ssh/sshd_config manually (e.g., added an Include line), this script does NOT remove that line."
echo "That Include is generally safe to keep."

