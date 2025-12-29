#!/bin/bash

cat << EOF
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║                  WARNING: Authorized access only!                 ║
║     Unauthorized access is prohibited and subject to prosecution. ║
║            By continuing, you consent to monitoring               ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
EOF

# S3 configuration (set via environment variables)
S3_ENDPOINT="${S3_ENDPOINT:-}"
S3_BUCKET="${S3_BUCKET:-}"
S3_ACCESS_KEY="${S3_ACCESS_KEY:-}"
S3_SECRET_KEY="${S3_SECRET_KEY:-}"
S3_PREFIX="${S3_PREFIX:-SSNREC}"
USER_EMAIL="${USER_EMAIL:-anonymous@localhost}"

# Function to upload a file to S3
upload_to_s3() {
  local file="$1"
  local s3_key="$2"
  local content_type="${3:-application/octet-stream}"
  local date_value="$(date -R)"
  local resource="/${S3_BUCKET}/${s3_key}"
  local content_length="$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)"
  local string_to_sign="PUT\n\n${content_type}\n${date_value}\n${resource}"
  local signature="$(printf '%b' "${string_to_sign}" | openssl sha1 -hmac "${S3_SECRET_KEY}" -binary | base64)"
  local s3_host="${S3_ENDPOINT#http://}"
  s3_host="${s3_host#https://}"

  curl -s -f -X PUT "${S3_ENDPOINT}/${S3_BUCKET}/${s3_key}" \
    -H "Host: ${s3_host}" \
    -H "Date: ${date_value}" \
    -H "Content-Type: ${content_type}" \
    -H "Content-Length: ${content_length}" \
    -H "Authorization: AWS ${S3_ACCESS_KEY}:${signature}" \
    --data-binary "@${file}"
}

SDIR="/$(hostname)_$(date +%s)"
mkdir -p $SDIR
script -q --timing=$SDIR/timing $SDIR/typescript -c "bash"

# Upload session files to S3
if [[ -n "$S3_ENDPOINT" && -n "$S3_BUCKET" && -n "$S3_ACCESS_KEY" && -n "$S3_SECRET_KEY" ]]; then
  RDIR="$(basename "$SDIR")"
  for f in "$SDIR"/*; do
    [[ -f "$f" ]] || continue
    fname="$(basename "$f")"
    upload_to_s3 "$f" "${S3_PREFIX}/${USER_EMAIL}/${RDIR}/${fname}" "text/plain" >/dev/null 2>&1 || true
  done
fi

exit
