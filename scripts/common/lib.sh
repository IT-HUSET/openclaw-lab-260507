#!/usr/bin/env bash
set -euo pipefail

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
}

ROOT_DIR="$(repo_root)"
ENV_FILE_INPUT="${OPENCLAW_ENV_FILE:-$ROOT_DIR/.env}"
if [[ "$ENV_FILE_INPUT" = /* ]]; then
  ENV_FILE="$ENV_FILE_INPUT"
else
  ENV_FILE="$ROOT_DIR/$ENV_FILE_INPUT"
fi
COMPOSE_FILE="$ROOT_DIR/compose.yaml"
COMPOSE_PROJECT="${OPENCLAW_COMPOSE_PROJECT:-}"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing dependency: $1"
}

ensure_env_file() {
  [[ -f "$ENV_FILE" ]] || die "Missing env file: $ENV_FILE"
}

compose() {
  local args=()
  if [[ -n "$COMPOSE_PROJECT" ]]; then
    args+=(--project-name "$COMPOSE_PROJECT")
  fi
  if [[ ${#args[@]} -gt 0 ]]; then
    docker compose "${args[@]}" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
  else
    docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
  fi
}

env_value_from() {
  local file="$1"
  local key="$2"
  if [[ -f "$file" ]]; then
    awk -F= -v key="$key" '$1 == key { sub(/^[^=]*=/, ""); print; found=1 } END { if (!found) exit 1 }' "$file" || true
  fi
}

env_value() {
  env_value_from "$ENV_FILE" "$1"
}

set_env_value_in() {
  local file="$1"
  local key="$2"
  local value="$3"
  local tmp
  tmp="$(mktemp)"
  awk -v key="$key" -v value="$value" '
    BEGIN { done = 0 }
    $0 ~ "^" key "=" {
      print key "=" value
      done = 1
      next
    }
    { print }
    END {
      if (!done) {
        print key "=" value
      }
    }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

set_env_value() {
  set_env_value_in "$ENV_FILE" "$1" "$2"
}

generate_token() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 32
    return
  fi
  if command -v node >/dev/null 2>&1; then
    node -e "process.stdout.write(require('crypto').randomBytes(32).toString('hex'))"
    return
  fi
  die "Need openssl or node to generate OPENCLAW_GATEWAY_TOKEN"
}
