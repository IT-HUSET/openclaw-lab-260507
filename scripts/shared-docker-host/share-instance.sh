#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  ./scripts/shared-docker-host/share-instance.sh <participant-id> [ssh-user]

Prints connection details for editing a participant's instance directory from
their own laptop. Read-only: this script does not configure SSH users,
File Sharing, or permissions on the host.

Examples:
  ./scripts/shared-docker-host/share-instance.sh 1
  ./scripts/shared-docker-host/share-instance.sh p01
  ./scripts/shared-docker-host/share-instance.sh 1 participant01
EOF
  exit 1
}

[[ $# -ge 1 && $# -le 2 ]] || usage

PARTICIPANT_ID="$1"
SSH_USER="${2:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common/participants.sh"

if is_participant_index "$PARTICIPANT_ID"; then
  PARTICIPANT_ID="$(participant_id_for_index "$PARTICIPANT_ID")"
fi

validate_participant_id "$PARTICIPANT_ID" || usage

INSTANCE_ENV_REL="instances/${PARTICIPANT_ID}.env"
INSTANCE_ENV="$ROOT_DIR/$INSTANCE_ENV_REL"
INSTANCE_DIR_REL="instances/${PARTICIPANT_ID}"
INSTANCE_DIR_ABS="$ROOT_DIR/$INSTANCE_DIR_REL"

[[ -f "$INSTANCE_ENV" ]] || {
  echo "ERROR: Missing $INSTANCE_ENV_REL. Run scripts/shared-docker-host/setup-instance.sh first." >&2
  exit 1
}

export OPENCLAW_ENV_FILE="$INSTANCE_ENV_REL"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common/lib.sh"

PUBLIC_HOST="$(env_value OPENCLAW_PUBLIC_HOST)"
PUBLIC_HOST="${PUBLIC_HOST:-<host-ip-or-dns>}"
SSH_USER="${SSH_USER:-<ssh-user>}"

cat <<EOF
Participant: $PARTICIPANT_ID
Host:        $PUBLIC_HOST
Path:        $INSTANCE_DIR_ABS
Editable:    config/  workspace/  ($INSTANCE_ENV_REL is read by Compose)

Pick one of the following for editing from the participant's own laptop.

VS Code / Cursor Remote-SSH (recommended for developers)
  1. ssh-copy-id ${SSH_USER}@${PUBLIC_HOST}
  2. In VS Code: Remote-SSH: Connect to Host -> ${SSH_USER}@${PUBLIC_HOST}
  3. Open folder: $INSTANCE_DIR_ABS

scp (one-off file copy, no setup beyond SSH)
  Pull:  scp -r ${SSH_USER}@${PUBLIC_HOST}:$INSTANCE_DIR_REL ./
  Push:  scp -r ./${PARTICIPANT_ID}/config ${SSH_USER}@${PUBLIC_HOST}:$INSTANCE_DIR_REL/

SSHFS mount (when SMB is blocked, reuses port 22)
  macOS:  sshfs ${SSH_USER}@${PUBLIC_HOST}:$INSTANCE_DIR_REL ~/openclaw-${PARTICIPANT_ID} -o reconnect
  Linux:  sshfs ${SSH_USER}@${PUBLIC_HOST}:$INSTANCE_DIR_REL ~/openclaw-${PARTICIPANT_ID}

SMB / File Sharing (only if the facilitator enabled it on the host)
  macOS Finder:  Cmd+K -> smb://${PUBLIC_HOST}/${PARTICIPANT_ID}
  Windows:       \\\\${PUBLIC_HOST}\\${PARTICIPANT_ID}

After editing, restart the instance to pick up changes:
  ./scripts/shared-docker-host/instance.sh ${PARTICIPANT_ID} stop
  ./scripts/shared-docker-host/instance.sh ${PARTICIPANT_ID} start
EOF
