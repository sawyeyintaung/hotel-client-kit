#!/usr/bin/env bash
# Build both hotel images for Windows/Intel PCs and push them to GHCR.
# Usage:  ./release.sh 1.0.0
# (Or skip this: GitHub Actions in each repo builds and pushes on every push to main.)
set -euo pipefail

VERSION="${1:?Usage: ./release.sh <version>   e.g. ./release.sh 1.0.0}"

# ---- EDIT THESE ----
OWNER="sawyeyintaung"                 # must be lowercase
FRONTEND_DIR="${FRONTEND_DIR:-$HOME/Documents/Github/Personal/hotel-frontend-next}"
BACKEND_DIR="${BACKEND_DIR:-$HOME/Documents/Github/Personal/hotel-backend}"
# --------------------

REG="ghcr.io/${OWNER}"

echo "==> Building frontend ${VERSION}"
docker buildx build --platform linux/amd64 \
  -t "${REG}/hotel-frontend:${VERSION}" \
  -t "${REG}/hotel-frontend:latest" \
  --push "${FRONTEND_DIR}"

echo "==> Building backend ${VERSION}"
docker buildx build --platform linux/amd64 \
  -t "${REG}/hotel-backend:${VERSION}" \
  -t "${REG}/hotel-backend:latest" \
  --push "${BACKEND_DIR}"

echo "==> Done. Pushed ${VERSION} and latest. Client can now run update.bat"
