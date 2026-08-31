#!/usr/bin/env bash

LAB_SECRETS_FILE_INPUT="${OPENCLAW_LAB_SECRETS_FILE:-$ROOT_DIR/resources/lab-secrets.env}"
if [[ "$LAB_SECRETS_FILE_INPUT" = /* ]]; then
  LAB_SECRETS_FILE="$LAB_SECRETS_FILE_INPUT"
else
  LAB_SECRETS_FILE="$ROOT_DIR/$LAB_SECRETS_FILE_INPUT"
fi

lab_secret_keys() {
  cat <<'EOF'
ANTHROPIC_API_KEY
OPENAI_API_KEY
OPENROUTER_API_KEY
GEMINI_API_KEY
GOOGLE_API_KEY
MISTRAL_API_KEY
MOONSHOT_API_KEY
ZAI_API_KEY
AI_GATEWAY_API_KEY
CUSTOM_API_KEY
CUSTOM_BASE_URL
CUSTOM_MODEL_ID
CUSTOM_PROVIDER_ID
CUSTOM_COMPATIBILITY
EOF
}

participant_secret_prefix() {
  printf '%s' "$1" | tr '[:lower:]-' '[:upper:]_'
}

lab_value() {
  local participant_id="$1"
  local key="$2"
  local prefix participant_key value

  prefix="$(participant_secret_prefix "$participant_id")"
  participant_key="${prefix}_${key}"

  if [[ -n "${!participant_key-}" ]]; then
    printf '%s\n' "${!participant_key}"
    return
  fi

  value="$(env_value_from "$LAB_SECRETS_FILE" "$participant_key")"
  if [[ -n "$value" ]]; then
    printf '%s\n' "$value"
    return
  fi

  if [[ -n "${!key-}" ]]; then
    printf '%s\n' "${!key}"
    return
  fi

  env_value_from "$LAB_SECRETS_FILE" "$key"
}

lab_preconfigure_enabled() {
  local participant_id="$1"
  local enabled

  [[ -f "$LAB_SECRETS_FILE" ]] || return 1
  enabled="$(lab_value "$participant_id" OPENCLAW_LAB_PRECONFIGURE)"
  [[ "${enabled:-1}" != "0" ]]
}

lab_unrestricted_enabled() {
  local participant_id="$1"
  local enabled

  enabled="$(lab_value "$participant_id" OPENCLAW_LAB_UNRESTRICTED)"
  [[ "${enabled:-1}" != "0" ]]
}

lab_tls_enabled() {
  local participant_id="$1"
  local enabled

  enabled="$(lab_value "$participant_id" OPENCLAW_LAB_TLS)"
  [[ "${enabled:-0}" == "1" ]]
}

lab_auth_choice() {
  local participant_id="$1"
  local configured

  configured="$(lab_value "$participant_id" OPENCLAW_LAB_AUTH_CHOICE)"
  if [[ -n "$configured" ]]; then
    printf '%s\n' "$configured"
    return
  fi

  if [[ -n "$(lab_value "$participant_id" ANTHROPIC_API_KEY)" ]]; then
    printf 'apiKey\n'
  elif [[ -n "$(lab_value "$participant_id" OPENAI_API_KEY)" ]]; then
    printf 'openai-api-key\n'
  elif [[ -n "$(lab_value "$participant_id" OPENROUTER_API_KEY)" ]]; then
    printf 'openrouter-api-key\n'
  elif [[ -n "$(lab_value "$participant_id" GEMINI_API_KEY)$(lab_value "$participant_id" GOOGLE_API_KEY)" ]]; then
    printf 'gemini-api-key\n'
  elif [[ -n "$(lab_value "$participant_id" MISTRAL_API_KEY)" ]]; then
    printf 'mistral-api-key\n'
  elif [[ -n "$(lab_value "$participant_id" MOONSHOT_API_KEY)" ]]; then
    printf 'moonshot-api-key\n'
  elif [[ -n "$(lab_value "$participant_id" ZAI_API_KEY)" ]]; then
    printf 'zai-api-key\n'
  elif [[ -n "$(lab_value "$participant_id" AI_GATEWAY_API_KEY)" ]]; then
    printf 'ai-gateway-api-key\n'
  elif [[ -n "$(lab_value "$participant_id" CUSTOM_API_KEY)" ]]; then
    printf 'custom-api-key\n'
  else
    printf 'skip\n'
  fi
}

apply_lab_secrets_to_env_file() {
  local participant_id="$1"
  local target_env="$2"
  local key value auth_choice unrestricted tls_enabled gemini_value google_value default_model

  lab_preconfigure_enabled "$participant_id" || return 0

  touch "$target_env"
  chmod 600 "$target_env" || true

  while IFS= read -r key; do
    value="$(lab_value "$participant_id" "$key")"
    if [[ -n "$value" ]]; then
      set_env_value_in "$target_env" "$key" "$value"
    fi
  done < <(lab_secret_keys)

  gemini_value="$(lab_value "$participant_id" GEMINI_API_KEY)"
  google_value="$(lab_value "$participant_id" GOOGLE_API_KEY)"
  if [[ -z "$gemini_value" && -n "$google_value" ]]; then
    set_env_value_in "$target_env" GEMINI_API_KEY "$google_value"
  fi

  auth_choice="$(lab_auth_choice "$participant_id")"
  set_env_value_in "$target_env" OPENCLAW_AUTH_CHOICE "$auth_choice"
  set_env_value_in "$target_env" OPENCLAW_NONINTERACTIVE_ONBOARDING 1

  unrestricted=0
  if lab_unrestricted_enabled "$participant_id"; then
    unrestricted=1
  fi
  set_env_value_in "$target_env" OPENCLAW_LAB_UNRESTRICTED "$unrestricted"

  tls_enabled=0
  if lab_tls_enabled "$participant_id"; then
    tls_enabled=1
  fi
  set_env_value_in "$target_env" OPENCLAW_LAB_TLS "$tls_enabled"

  default_model="$(lab_value "$participant_id" OPENCLAW_LAB_DEFAULT_MODEL)"
  if [[ -n "$default_model" ]]; then
    set_env_value_in "$target_env" OPENCLAW_DEFAULT_MODEL "$default_model"
  fi
}

native_profile_env_file() {
  local profile="$1"
  printf '%s/.openclaw-%s/.env\n' "$HOME" "$profile"
}

apply_lab_secrets_to_native_profile_env() {
  local profile="$1"
  local profile_env token

  lab_preconfigure_enabled "$profile" || return 0

  profile_env="$(native_profile_env_file "$profile")"
  mkdir -p "$(dirname "$profile_env")"
  touch "$profile_env"
  chmod 600 "$profile_env" || true

  apply_lab_secrets_to_env_file "$profile" "$profile_env"

  token="$(env_value_from "$profile_env" OPENCLAW_GATEWAY_TOKEN)"
  if [[ -z "$token" ]]; then
    token="$(generate_token)"
    set_env_value_in "$profile_env" OPENCLAW_GATEWAY_TOKEN "$token"
  fi
}

load_env_file_for_process() {
  local env_file="$1"
  local line key value

  [[ -f "$env_file" ]] || return 0

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    [[ "$line" == *=* ]] || continue
    key="${line%%=*}"
    value="${line#*=}"
    export "$key=$value"
  done < "$env_file"
}

openclaw_onboard_args() {
  local auth_choice="$1"
  local gateway_port="$2"
  local gateway_bind="$3"
  local custom_base_url custom_model_id custom_provider_id custom_compatibility

  printf '%s\0' \
    onboard \
    --non-interactive \
    --mode local \
    --auth-choice "${auth_choice:-skip}" \
    --secret-input-mode ref \
    --gateway-auth token \
    --gateway-token-ref-env OPENCLAW_GATEWAY_TOKEN \
    --gateway-port "$gateway_port" \
    --gateway-bind "$gateway_bind" \
    --skip-health \
    --accept-risk

  if [[ "${auth_choice:-}" == "custom-api-key" ]]; then
    custom_base_url="${CUSTOM_BASE_URL:-}"
    custom_model_id="${CUSTOM_MODEL_ID:-}"
    custom_provider_id="${CUSTOM_PROVIDER_ID:-}"
    custom_compatibility="${CUSTOM_COMPATIBILITY:-}"

    [[ -n "$custom_base_url" ]] && printf '%s\0' --custom-base-url "$custom_base_url"
    [[ -n "$custom_model_id" ]] && printf '%s\0' --custom-model-id "$custom_model_id"
    [[ -n "$custom_provider_id" ]] && printf '%s\0' --custom-provider-id "$custom_provider_id"
    [[ -n "$custom_compatibility" ]] && printf '%s\0' --custom-compatibility "$custom_compatibility"
  fi
}

permissive_openclaw_config_json() {
  cat <<'EOF'
[
  {"path":"agents.defaults.sandbox.mode","value":"off"},
  {"path":"tools.profile","value":"full"},
  {"path":"tools.exec.host","value":"gateway"},
  {"path":"tools.exec.security","value":"full"},
  {"path":"tools.exec.ask","value":"off"},
  {"path":"tools.exec.applyPatch.workspaceOnly","value":false},
  {"path":"tools.fs.workspaceOnly","value":false},
  {"path":"browser.ssrfPolicy.dangerouslyAllowPrivateNetwork","value":true},
  {"path":"gateway.controlUi.dangerouslyDisableDeviceAuth","value":true}
]
EOF
}
