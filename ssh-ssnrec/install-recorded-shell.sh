#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Install "recorded SSH shell" using util-linux script(1) + sshd ForceCommand
# Shows legal banner only for interactive sessions (not scp/sftp).
#
# Usage:
#   sudo bash install-recorded-ssh.sh
#
# After install:
#   sudo usermod -aG recorded <username>
#   (new SSH logins by that user will be forced into recorded shell)
# ==============================================================================

# -----------------------------
# Config (override via env vars)
# -----------------------------
REC_GROUP="${REC_GROUP:-recorded}"
WRAPPER_PATH="${WRAPPER_PATH:-/usr/local/bin/recorded-shell}"
LOG_ROOT="${LOG_ROOT:-/var/log/ssh-script}"
SSHD_DROPIN_DIR="${SSHD_DROPIN_DIR:-/etc/ssh/sshd_config.d}"
SSHD_DROPIN_FILE="${SSHD_DROPIN_FILE:-${SSHD_DROPIN_DIR}/50-recorded-shell.conf}"
SSH_BANNER_FILE="${SSH_BANNER_FILE:-/etc/ssh/ssh_recorded_banner.txt}"

DISABLE_PORT_FWD="${DISABLE_PORT_FWD:-true}"
DISABLE_X11="${DISABLE_X11:-true}"

# -----------------------------
# Helpers
# -----------------------------
log() { echo "[$(date +%H:%M:%S)] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }
cmd_exists() { command -v "$1" >/dev/null 2>&1; }

need_root() {
  [[ "${EUID:-$(id -u)}" -eq 0 ]] || die "Run as root (use sudo)."
}

detect_pkg_mgr() {
  if cmd_exists apt-get; then echo "apt"
  elif cmd_exists dnf; then echo "dnf"
  elif cmd_exists yum; then echo "yum"
  elif cmd_exists zypper; then echo "zypper"
  elif cmd_exists pacman; then echo "pacman"
  else echo "none"
  fi
}

install_pkg() {
  local pkg="$1" mgr
  mgr="$(detect_pkg_mgr)"
  case "$mgr" in
    apt)
      log "Installing $pkg via apt..."
      apt-get update -y
      DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg"
      ;;
    dnf)
      log "Installing $pkg via dnf..."
      dnf install -y "$pkg"
      ;;
    yum)
      log "Installing $pkg via yum..."
      yum install -y "$pkg"
      ;;
    zypper)
      log "Installing $pkg via zypper..."
      zypper --non-interactive install "$pkg"
      ;;
    pacman)
      log "Installing $pkg via pacman..."
      pacman -Sy --noconfirm "$pkg"
      ;;
    none)
      die "No supported package manager found. Please install '$pkg' manually."
      ;;
  esac
}

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

# -----------------------------
# Main
# -----------------------------
need_root

log "Pre-requisite checks..."

SSHD_BIN="$(find_sshd_bin)"
[[ -n "${SSHD_BIN:-}" && -x "$SSHD_BIN" ]] || die "sshd not found. Install OpenSSH server first."

if ! cmd_exists script; then
  log "'script' not found; attempting to install util-linux..."
  install_pkg util-linux
fi
cmd_exists script || die "Missing 'script'. Install util-linux manually."

# Ensure sshd drop-in dir exists
mkdir -p "$SSHD_DROPIN_DIR"
[[ -d "$SSHD_DROPIN_DIR" ]] || die "Cannot create $SSHD_DROPIN_DIR"

# Create group if missing
if ! getent group "$REC_GROUP" >/dev/null; then
  log "Creating group '$REC_GROUP'..."
  groupadd --system "$REC_GROUP" 2>/dev/null || groupadd "$REC_GROUP"
else
  log "Group '$REC_GROUP' already exists."
fi

# Create banner file (used by sshd Banner directive)
log "Installing SSH banner: $SSH_BANNER_FILE..."
cat > "$SSH_BANNER_FILE" <<'EOF'
************************************************************
* WARNING: UNAUTHORIZED ACCESS IS STRICTLY PROHIBITED      *
*                                                          *
* This system is monitored and all access is logged and    *
* recorded. By continuing, you consent to monitoring.      *
*                                                          *
* Disconnect immediately if you are not authorized.        *
************************************************************
EOF
chmod 0644 "$SSH_BANNER_FILE"
chown root:root "$SSH_BANNER_FILE"

# Create log root securely
log "Creating log directory: $LOG_ROOT..."
mkdir -p "$LOG_ROOT"
chown root:recorded "$LOG_ROOT"
chmod 2770 "$LOG_ROOT"

# 1730: sticky bit + rwx for owner, wx for group; adjust if you want different sharing semantics
chmod 1730 "$LOG_ROOT" 2>/dev/null || chmod 0750 "$LOG_ROOT"

# Install recorded-shell wrapper
log "Installing wrapper: $WRAPPER_PATH..."
cat > "$WRAPPER_PATH" <<EOF
#!/usr/bin/env bash
set -euo pipefail

LOG_ROOT="${LOG_ROOT}"
BANNER_FILE="${SSH_BANNER_FILE}"

# Pass through scp/sftp commands without recording
if [[ -n "\${SSH_ORIGINAL_COMMAND:-}" ]]; then
  case "\${SSH_ORIGINAL_COMMAND}" in
    scp\ *|/usr/bin/scp\ *|sftp-server*|/usr/lib/openssh/sftp-server*)
      exec /bin/bash -c "\${SSH_ORIGINAL_COMMAND}"
      ;;
  esac
fi

umask 077

ts="\$(date +%s)"
host="\$(hostname -s 2>/dev/null || hostname)"
USER_NAME="\${USER:-\$(id -un)}"
SDIR="\${LOG_ROOT}/\${USER_NAME}_\${host}_\${ts}"
mkdir -p "\${SDIR}"

types="\${SDIR}/typescript"
timing="\${SDIR}/timing"
meta="\${SDIR}/meta"

{
  echo "user=\${USER_NAME}"
  echo "uid=\$(id -u)"
  echo "gid=\$(id -g)"
  echo "groups=\$(id -Gn 2>/dev/null || true)"
  echo "host=\$(hostname -f 2>/dev/null || hostname)"
  echo "remote=\${SSH_CONNECTION:-unknown}"
  echo "client=\${SSH_CLIENT:-unknown}"
  echo "tty=\$(tty 2>/dev/null || echo unknown)"
} > "\${meta}"

SCRIPT_BIN="\$(command -v script)"

# Print banner for interactive sessions only, then start recorded shell
if [[ -t 0 && -r "\${BANNER_FILE}" ]]; then
  cat "\${BANNER_FILE}"
  echo
fi

# Remote server configuration for uploading session recordings
REMOTE_SERVER="rahul@192.168.1.234"
REMOTE_PATH="SSNREC/"

"\${SCRIPT_BIN}" \\
  --flush \\
  --quiet \\
  --timing="\${timing}" \\
  "\${types}" \\
  --command "/bin/bash -l"

# After script command finishes, upload the session folder to remote server
if [[ -d "\${SDIR}" ]]; then
  scp -qr -o StrictHostKeyChecking=no -o BatchMode=yes "\${SDIR}" "\${REMOTE_SERVER}:\${REMOTE_PATH}" 2>/dev/null || true
fi
EOF

chmod 0755 "$WRAPPER_PATH"
chown root:root "$WRAPPER_PATH"

# Write sshd drop-in: Match Group ForceCommand
log "Writing sshd drop-in: $SSHD_DROPIN_FILE..."
{
  echo "# Managed by install-recorded-ssh.sh"
  echo ""
  echo "# Force terminal recording for members of group: $REC_GROUP"
  echo "Match Group $REC_GROUP"
  echo "    ForceCommand $WRAPPER_PATH"
  echo "    PermitTTY yes"
  [[ "$DISABLE_PORT_FWD" == "true" ]] && echo "    AllowTcpForwarding no"
  [[ "$DISABLE_X11" == "true" ]] && echo "    X11Forwarding no"
  echo ""
} > "$SSHD_DROPIN_FILE"
chmod 0644 "$SSHD_DROPIN_FILE"
chown root:root "$SSHD_DROPIN_FILE"

# Validate sshd config
log "Validating sshd configuration..."
"$SSHD_BIN" -t || die "sshd config validation failed. Check: $SSHD_DROPIN_FILE"

# Reload sshd
reload_sshd

log "Installed successfully."

cat <<EOF

Next steps:
1) Add users to the '$REC_GROUP' group:
   sudo usermod -aG $REC_GROUP <username>

2) New SSH logins for those users will be recorded under:
   $LOG_ROOT/<username>/*.typescript and *.timing

3) Replay a session:
   scriptreplay --timing <file.timing> <file.typescript>

Notes:
- Banner is shown only for interactive sessions (not scp/sftp).
- ForceCommand applies even if the client runs: ssh user@host 'cmd'
- scp/sftp are passed through without recording.

EOF

