#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  ./scripts/native-multi-gateway/share-profile.sh <profile> [host-ip-or-dns] [ssh-user]

Prints connection details for editing a participant's OpenClaw profile
directory from their own laptop. Read-only: this script does not configure
SSH users, File Sharing, or POSIX ACLs on the host.

Examples:
  ./scripts/native-multi-gateway/share-profile.sh 1
  ./scripts/native-multi-gateway/share-profile.sh p01
  ./scripts/native-multi-gateway/share-profile.sh 1 172.24.110.136
  ./scripts/native-multi-gateway/share-profile.sh p01 172.24.110.136 multi-claw
EOF
  exit 1
}

[[ $# -ge 1 && $# -le 3 ]] || usage

PROFILE="$1"
HOST_NAME="${2:-}"
SSH_USER="${3:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common/participants.sh"

if is_participant_index "$PROFILE"; then
  PROFILE="$(participant_id_for_index "$PROFILE")"
fi

validate_participant_id "$PROFILE" || usage

HOST_NAME="${HOST_NAME:-$(hostname 2>/dev/null || echo '<host-ip-or-dns>')}"
SSH_USER="${SSH_USER:-${USER:-<ssh-user>}}"

CANDIDATES=(
  "$HOME/.openclaw/profiles/$PROFILE"
  "$HOME/Library/Application Support/openclaw/profiles/$PROFILE"
  "$HOME/.config/openclaw/profiles/$PROFILE"
)

FOUND=()
for path in "${CANDIDATES[@]}"; do
  if [[ -d "$path" ]]; then
    FOUND+=("$path")
  fi
done

echo "Profile:     $PROFILE"
echo "Host:        $HOST_NAME"
echo "SSH user:    $SSH_USER"
echo

if [[ ${#FOUND[@]} -eq 0 ]]; then
  echo "WARNING: No profile directory found in known locations. Probed:"
  for path in "${CANDIDATES[@]}"; do
    echo "  - $path"
  done
  echo
  echo "Run setup-profile.sh first, or check the OpenClaw docs for your version's path."
  echo "Once you know the actual path, substitute it for <profile-dir> below."
  echo
  PROFILE_DIR="<profile-dir>"
else
  echo "Profile directory:"
  for path in "${FOUND[@]}"; do
    echo "  $path"
  done
  PROFILE_DIR="${FOUND[0]}"
  echo
fi

cat <<EOF
Pick one of the following for editing from the participant's own laptop.

VS Code / Cursor Remote-SSH (recommended for developers)
  1. ssh-copy-id ${SSH_USER}@${HOST_NAME}
  2. In VS Code: Remote-SSH: Connect to Host -> ${SSH_USER}@${HOST_NAME}
  3. Open folder: $PROFILE_DIR

scp (one-off file copy, no setup beyond SSH)
  Pull:  scp -r ${SSH_USER}@${HOST_NAME}:'${PROFILE_DIR}' ./
  Push:  scp -r ./${PROFILE} ${SSH_USER}@${HOST_NAME}:'$(dirname "$PROFILE_DIR")/'

SSHFS mount (when SMB is blocked, reuses port 22)
  macOS:  sshfs ${SSH_USER}@${HOST_NAME}:'${PROFILE_DIR}' ~/openclaw-${PROFILE} -o reconnect
  Linux:  sshfs ${SSH_USER}@${HOST_NAME}:'${PROFILE_DIR}' ~/openclaw-${PROFILE}

SMB / File Sharing (only if the facilitator enabled it on the host)
  macOS Finder:  Cmd+K -> smb://${HOST_NAME}/${PROFILE}
  Windows:       \\\\${HOST_NAME}\\${PROFILE}

Native mode caveat: every participant typically logs in as the same macOS
account, so all profile directories are visible to everyone with shell
access. Use POSIX ACLs or per-participant macOS users for real isolation.

After editing, restart the gateway to pick up changes:
  openclaw --profile ${PROFILE} gateway restart
EOF
