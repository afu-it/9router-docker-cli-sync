#!/usr/bin/env bash
set -euo pipefail

container="${1:-9router}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found" >&2
  exit 1
fi

if ! docker inspect "$container" >/dev/null 2>&1; then
  echo "container not found: $container" >&2
  echo 'Start 9Router with: -v "$HOME:/home/user"' >&2
  exit 1
fi

# Confirm host home mount is visible from inside the container.
if ! docker exec "$container" sh -lc 'test -d /home/user'; then
  echo "/home/user not visible in container." >&2
  echo 'Recreate container with: -v "$HOME:/home/user"' >&2
  exit 1
fi

# Create parent dirs first.
docker exec -u root "$container" sh -lc 'mkdir -p /home/node/.config /home/node/.local/share'

link_path() {
  local target="$1"
  local link="$2"
  docker exec -u root "$container" sh -lc "rm -rf '$link' && ln -s '$target' '$link' && chown -h node:node '$link'"
}

link_path /home/user/.codex /home/node/.codex
link_path /home/user/.claude /home/node/.claude
link_path /home/user/.config/opencode /home/node/.config/opencode
link_path /home/user/.local/share/kilo /home/node/.local/share/kilo
link_path /home/user/.config/kilo /home/node/.config/kilo
link_path /home/user/.cline /home/node/.cline
link_path /home/user/.factory /home/node/.factory
link_path /home/user/.openclaw /home/node/.openclaw
link_path /home/user/.hermes /home/node/.hermes
link_path /home/user/.deepseek /home/node/.deepseek
link_path /home/user/.jcode /home/node/.jcode
link_path /home/user/.config/jcode /home/node/.config/jcode
link_path /home/user/.config/Code /home/node/.config/Code
link_path /home/user/.config/Claude /home/node/.config/Claude
link_path /home/user/.config/Claude-3p /home/node/.config/Claude-3p

cat <<EOF
9Router Docker CLI symlinks created for container: $container

Verify:
  docker exec $container sh -lc 'ls -la /home/node/.codex /home/node/.claude /home/node/.config/opencode /home/node/.local/share/kilo'
  curl http://127.0.0.1:20128/api/cli-tools/all-statuses
EOF
