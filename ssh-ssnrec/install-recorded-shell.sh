#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Install "recorded SSH shell" using util-linux script(1) + sshd ForceCommand
# Shows legal banner only for interactive sessions (not scp/sftp).
#
# Usage:
#   sudo S3_ENDPOINT=https://s3.example.com S3_BUCKET=recordings S3_ACCESS_KEY=xxx S3_SECRET_KEY=yyy bash install-recorded-ssh.sh
#
# Required environment variables:
#   S3_ENDPOINT    - S3-compatible endpoint URL (e.g., https://s3.example.com)
#   S3_BUCKET      - S3 bucket name (e.g., recordings)
#   S3_ACCESS_KEY  - S3 access key
#   S3_SECRET_KEY  - S3 secret key
#
# Optional:
#   S3_PREFIX      - Prefix/folder in bucket (default: SSNREC/)
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
USER_EMAIL="${USER_EMAIL:-anonymous@localhost}"
SSHD_DROPIN_DIR="${SSHD_DROPIN_DIR:-/etc/ssh/sshd_config.d}"
SSHD_DROPIN_FILE="${SSHD_DROPIN_FILE:-${SSHD_DROPIN_DIR}/50-recorded-shell.conf}"
SSH_BANNER_FILE="${SSH_BANNER_FILE:-/etc/ssh/ssh_recorded_banner.txt}"

DISABLE_PORT_FWD="${DISABLE_PORT_FWD:-true}"
DISABLE_X11="${DISABLE_X11:-true}"

# Detect the invoking user and their shell
SUDO_USER="${SUDO_USER:-}"
if [[ -n "$SUDO_USER" ]]; then
  INVOKING_USER="$SUDO_USER"
  # Get the user's login shell from /etc/passwd
  USER_SHELL="$(getent passwd "$SUDO_USER" | cut -d: -f7)"
else
  INVOKING_USER="${USER:-$(id -un)}"
  USER_SHELL="${SHELL:-/bin/bash}"
fi
# Fallback to /bin/bash if detection failed
USER_SHELL="${USER_SHELL:-/bin/bash}"

# S3 bucket config (required)
S3_ENDPOINT="${S3_ENDPOINT:-}"
S3_BUCKET="${S3_BUCKET:-}"
S3_ACCESS_KEY="${S3_ACCESS_KEY:-}"
S3_SECRET_KEY="${S3_SECRET_KEY:-}"
S3_PREFIX="${S3_PREFIX:-SSNREC}"

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

# Validate required S3 config
if [[ -z "$S3_ENDPOINT" ]]; then
  die "S3_ENDPOINT is required. Example: S3_ENDPOINT=https://s3.example.com"
fi
if [[ -z "$S3_BUCKET" ]]; then
  die "S3_BUCKET is required. Example: S3_BUCKET=recordings"
fi
if [[ -z "$S3_ACCESS_KEY" ]]; then
  die "S3_ACCESS_KEY is required."
fi
if [[ -z "$S3_SECRET_KEY" ]]; then
  die "S3_SECRET_KEY is required."
fi

log "S3 endpoint: ${S3_ENDPOINT}/${S3_BUCKET}/${S3_PREFIX}"
log "Detected invoking user: ${INVOKING_USER} (shell: ${USER_SHELL})"

log "Pre-requisite checks..."

SSHD_BIN="$(find_sshd_bin)"
[[ -n "${SSHD_BIN:-}" && -x "$SSHD_BIN" ]] || die "sshd not found. Install OpenSSH server first."

if ! cmd_exists script; then
  log "'script' not found; attempting to install util-linux..."
  install_pkg util-linux
fi
cmd_exists script || die "Missing 'script'. Install util-linux manually."

if ! cmd_exists curl; then
  log "'curl' not found; attempting to install curl..."
  install_pkg curl
fi
cmd_exists curl || die "Missing 'curl'. Install curl manually."

if ! cmd_exists openssl; then
  log "'openssl' not found; attempting to install openssl..."
  install_pkg openssl
fi
cmd_exists openssl || die "Missing 'openssl'. Install openssl manually."

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
USER_EMAIL="${USER_EMAIL}"
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
RDIR="\${USER_NAME}@\${host}_\${ts}"
SDIR="\${LOG_ROOT}/\${RDIR}"
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

# S3 configuration for uploading session recordings
S3_ENDPOINT="${S3_ENDPOINT}"
S3_BUCKET="${S3_BUCKET}"
S3_ACCESS_KEY="${S3_ACCESS_KEY}"
S3_SECRET_KEY="${S3_SECRET_KEY}"
S3_PREFIX="${S3_PREFIX}"

# Function to upload a file to S3
upload_to_s3() {
  local file="\$1"
  local s3_key="\$2"
  local content_type="\${3:-application/octet-stream}"
  local date_value="\$(date -R)"
  local resource="/\${S3_BUCKET}/\${s3_key}"
  local string_to_sign="PUT\n\n\${content_type}\n\${date_value}\n\${resource}"
  local signature="\$(printf '%b' "\${string_to_sign}" | openssl sha1 -hmac "\${S3_SECRET_KEY}" -binary | base64)"

  curl -s -X PUT "\${S3_ENDPOINT}/\${S3_BUCKET}/\${s3_key}" \\
    -H "Host: \$(echo "\${S3_ENDPOINT}" | sed 's|https\\?://||')" \\
    -H "Date: \${date_value}" \\
    -H "Content-Type: \${content_type}" \\
    -H "Authorization: AWS \${S3_ACCESS_KEY}:\${signature}" \\
    --data-binary "@\${file}" 2>/dev/null
}

"\${SCRIPT_BIN}" \\
  --flush \\
  --quiet \\
  --timing="\${timing}" \\
  "\${types}" \\
  --command "${USER_SHELL} -l"

# After script command finishes, upload the session files to S3
if [[ -d "\${SDIR}" ]]; then
  for f in "\${SDIR}"/*; do
    [[ -f "\${f}" ]] || continue
    fname="\$(basename "\${f}")"
    upload_to_s3 "\${f}" "\${S3_PREFIX}/\${USER_EMAIL}/\${RDIR}/\${fname}" "text/plain" || true
  done
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

# Add the invoking user to the recorded group
if [[ -n "$INVOKING_USER" && "$INVOKING_USER" != "root" ]]; then
  if ! id -nG "$INVOKING_USER" 2>/dev/null | grep -qw "$REC_GROUP"; then
    log "Adding user '$INVOKING_USER' to group '$REC_GROUP'..."
    usermod -aG "$REC_GROUP" "$INVOKING_USER"
  else
    log "User '$INVOKING_USER' is already a member of group '$REC_GROUP'."
  fi
fi

log "Installed successfully."

cat <<EOF

Installation complete.
- User '$INVOKING_USER' has been added to the '$REC_GROUP' group.
- Recorded shell configured to use: $USER_SHELL

To add additional users to session recording:
   sudo usermod -aG $REC_GROUP <username>

EOF

