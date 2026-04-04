#!/usr/bin/env bash
set -euo pipefail

ENV_FILE=${1:-env.dev.json}

if [[ -f "$ENV_FILE" ]]; then
  echo "[INFO] Using $ENV_FILE"
  flutter run --dart-define-from-file="$ENV_FILE"
else
  echo "[INFO] $ENV_FILE not found. Falling back to bundled app config."
  flutter run
fi
