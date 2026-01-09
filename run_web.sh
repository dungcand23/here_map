#!/usr/bin/env bash
set -euo pipefail

ENV_FILE=${1:-env.dev.json}

if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ Missing $ENV_FILE"
  echo "Copy env.example.json -> env.dev.json and fill HERE_API_KEY"
  exit 1
fi

flutter run -d chrome --dart-define-from-file="$ENV_FILE"
