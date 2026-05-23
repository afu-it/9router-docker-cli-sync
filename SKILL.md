---
name: 9router-docker-cli-sync
description: Repair 9Router Docker CLI tool detection by binding host home into the container and creating real symlinks from /home/node config paths to /home/user config paths. Use when 9Router is run via Docker and /dashboard/cli-tools shows Claude, Codex, OpenCode, Kilo, Cline, OpenClaw, Droid, Hermes, DeepSeek TUI, JCode, Copilot, or Cowork as not installed even though they are installed on the host.
---

# 9Router Docker CLI Sync

## Purpose

Make 9Router Docker read and write the host CLI configs, not copied container-only configs. This prevents fake dashboard state after switching from npm 9Router to Docker.

## Root Cause

9Router CLI tool status routes use `os.homedir()`. In npm mode this is usually `/home/user`; in Docker it is `/home/node`. Detection checks `which <tool>` first, then falls back to specific config files under the container home. Host binaries and config files are invisible unless mounted or linked.

## Workflow

1. Confirm 9Router container exists and Docker access works.
2. Ensure the container was started with host home mounted:
   `-v "$HOME:/home/user"`.
3. If `docker ps` fails with permission denied, use `sudo docker` for Docker checks and run the sync script with `sudo bash`.
4. Run `scripts/sync-9router-cli-symlinks.sh` to create `/home/node` symlinks to `/home/user`.
5. Verify symlinks with `ls -la`.
6. Verify 9Router status with `/api/cli-tools/all-statuses`.

## Script

Use the bundled script instead of hand-pasting long `docker exec` commands:

```bash
bash /home/user/.codex/skills/9router-docker-cli-sync/scripts/sync-9router-cli-symlinks.sh
```

If Docker requires sudo:

```bash
sudo bash /home/user/.codex/skills/9router-docker-cli-sync/scripts/sync-9router-cli-symlinks.sh
```

Optional container name:

```bash
bash /home/user/.codex/skills/9router-docker-cli-sync/scripts/sync-9router-cli-symlinks.sh my-9router-container
```

With sudo and a custom container name:

```bash
sudo bash /home/user/.codex/skills/9router-docker-cli-sync/scripts/sync-9router-cli-symlinks.sh my-9router-container
```

The script is idempotent. It removes only target paths under `/home/node` in the container, then recreates them as symlinks to `/home/user`.

## Supported Paths

The 9Router repo currently checks these paths:

```text
Claude       /home/node/.claude/settings.json
Codex        /home/node/.codex/config.toml
OpenCode     /home/node/.config/opencode/opencode.json
Kilo         /home/node/.local/share/kilo/auth.json
Cline        /home/node/.cline/data/globalState.json
Droid        /home/node/.factory/settings.json
OpenClaw     /home/node/.openclaw/openclaw.json
Hermes       /home/node/.hermes/config.yaml
DeepSeek TUI /home/node/.deepseek/config.toml
JCode        /home/node/.jcode/config.toml
JCode env    /home/node/.config/jcode/provider-9router.env
Copilot      /home/node/.config/Code/User/chatLanguageModels.json
Cowork       /home/node/.config/Claude-3p or /home/node/.config/Claude
```

## Verification Commands

```bash
sudo docker exec 9router sh -lc 'ls -la /home/node/.codex /home/node/.claude /home/node/.config/opencode /home/node/.local/share/kilo'
curl http://127.0.0.1:20128/api/cli-tools/all-statuses
```

Expected symlinks:

```text
/home/node/.codex -> /home/user/.codex
/home/node/.claude -> /home/user/.claude
/home/node/.config/opencode -> /home/user/.config/opencode
/home/node/.local/share/kilo -> /home/user/.local/share/kilo
```

## If Detection Still Fails

Check these in order:

1. Container must be started with `-v "$HOME:/home/user"`; otherwise symlinks point to missing targets.
2. Host config must exist. Broken symlink is allowed, but 9Router marks installed only when expected file/folder exists or binary exists inside container.
3. Dashboard may cache status. Hard refresh browser or restart container.
4. If Docker command fails with permission denied, run the sync script with `sudo bash` or fix Docker socket permissions.

## Security Note

Mounting `$HOME:/home/user` exposes the full host home to the 9Router container. Prefer exact folder mounts for least privilege, but use host-home symlinks when the user explicitly wants real host config behavior across all tools.
