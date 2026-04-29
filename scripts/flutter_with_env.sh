#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="${repo_root}/.env"
flutter_bin="${OVAL_FLUTTER_BIN:-flutter}"

if [[ ! -f "${env_file}" ]]; then
  echo "Missing ${env_file}. Copy .env.example to .env first." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${env_file}"
set +a

required_vars=(SUPABASE_URL SUPABASE_ANON_KEY GOOGLE_MAPS_API_KEY)
for key in "${required_vars[@]}"; do
  if [[ -z "${!key:-}" ]]; then
    echo "Missing required value: ${key}" >&2
    exit 1
  fi
done

command_name="${1:-}"
if [[ -z "${command_name}" ]]; then
  echo "Usage: ./scripts/flutter_with_env.sh <flutter-subcommand> [args...]" >&2
  exit 1
fi

if [[ "${command_name}" == "pub" || "${command_name}" == "config" ]]; then
  exec "${flutter_bin}" "$@"
fi

exec "${flutter_bin}" "$@" \
  --dart-define=APP_ENV="${APP_ENV:-development}" \
  --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
  --dart-define=GOOGLE_MAPS_API_KEY="${GOOGLE_MAPS_API_KEY}" \
  --dart-define=GOOGLE_PLACES_API_KEY="${GOOGLE_PLACES_API_KEY:-${GOOGLE_MAPS_API_KEY}}"
