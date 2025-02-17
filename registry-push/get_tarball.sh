#!/usr/bin/env bash

DEST="${1:-/var/lib/rancher/rke2/agent/images/}"

urls=(
    "https://accuknox-images.s3.amazonaws.com/956994857092.dkr.ecr.us-east-2.amazonaws.com_divy-backend:v2.12.152-dev-to-stage-sync-17-patch-14-onprem.tar"
)

if [[ -z "$(command -v wget)" ]]; then
    echo "wget is not installed on this system"
    exit 1
fi

mkdir -p "$DEST"

echo "Fetching all the tarball files and saving it to $DEST..."

for url in "${urls[@]}"; do
    wget -P "$DEST" "$url"
done
