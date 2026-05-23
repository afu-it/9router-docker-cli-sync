# 9Router Docker CLI Sync

Fix 9Router Docker `/dashboard/cli-tools` detection when tools installed on the host show as `not installed` inside the dashboard.

## What This Fixes

This repo handles two Docker migration issues:

1. `/dashboard/providers` does not show old npm/host setup.
   Fix: start Docker with the 9Router data directory mounted:

   ```bash
   -v "$HOME/.9router:/app/data"
   -e DATA_DIR=/app/data
   ```

2. `/dashboard/cli-tools` does not detect host CLI tools or connected setup.
   Fix: start Docker with host home mounted, then run the sync script to create `/home/node` symlinks to host config folders:

   ```bash
   -v "$HOME:/home/user"
   bash scripts/sync-9router-cli-symlinks.sh 9router
   ```

## Problem

9Router works differently depending on how it is started:

- `npm install -g 9router && 9router` runs on the host machine.
- `docker run decolua/9router` runs inside a container.

When 9Router runs from npm, it can see host CLI binaries and host config files like:

```text
/home/user/.codex/config.toml
/home/user/.claude/settings.json
/home/user/.config/opencode/opencode.json
/home/user/.local/share/kilo/auth.json
```

When 9Router runs in Docker, its app home is usually:

```text
/home/node
```

So the dashboard checks paths like:

```text
/home/node/.codex/config.toml
/home/node/.claude/settings.json
/home/node/.config/opencode/opencode.json
/home/node/.local/share/kilo/auth.json
```

Those paths do not exist unless you mount or link host config into the container. Result: `/dashboard/cli-tools` shows `not installed`, even though the CLI tools work on the host.

## Issue

9Router CLI detection is path-based. It does not scan the host machine from inside Docker.

From the 9Router source, `/api/cli-tools/all-statuses` checks these tools:

```text
claude, codex, opencode, droid, openclaw, hermes, cowork, copilot, cline, kilo, deepseek-tui, jcode
```

Each tool route usually checks `which <tool>` first, then falls back to a config file under `os.homedir()`. In Docker, `os.homedir()` resolves to `/home/node`, not `/home/user`.

Important paths:

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

## Fix We Made

We mounted the real host home into the 9Router container:

```bash
-v "$HOME:/home/user"
```

Then we created symlinks from `/home/node` paths to the real `/home/user` config folders.

Example:

```text
/home/node/.codex              -> /home/user/.codex
/home/node/.claude             -> /home/user/.claude
/home/node/.config/opencode    -> /home/user/.config/opencode
/home/node/.local/share/kilo   -> /home/user/.local/share/kilo
```

This makes the dashboard real, not fake. When 9Router writes:

```text
/home/node/.codex/config.toml
```

it actually changes:

```text
/home/user/.codex/config.toml
```

## Quick Use

Prerequisites:

- Check Docker works first:

```bash
docker --version
docker ps
```

- If `docker ps` fails with a permission error, use `sudo docker` for the Docker commands below.

Clone this repo and enter it:

```bash
git clone https://github.com/afu-it/9router-docker-cli-sync.git
cd 9router-docker-cli-sync
```

Start 9Router with host home mounted. This mount is required; without it, the symlinks point to missing files:

```bash
sudo docker stop 9router 2>/dev/null || true
sudo docker rm 9router 2>/dev/null || true
sudo docker run -d \
  --name 9router \
  -p 20128:20128 \
  -v "$HOME:/home/user" \
  -v "$HOME/.9router:/app/data" \
  -e DATA_DIR=/app/data \
  decolua/9router:latest
```

Confirm the required mount exists:

```bash
sudo docker inspect 9router --format '{{range .Mounts}}{{println .Source "->" .Destination}}{{end}}'
```

Expected output must include:

```text
/home/your-user -> /home/user
```

Run sync. Use `sudo bash` if Docker requires sudo on your system:

```bash
bash scripts/sync-9router-cli-symlinks.sh 9router
```

Or:

```bash
sudo bash scripts/sync-9router-cli-symlinks.sh 9router
```

Verify symlinks:

```bash
sudo docker exec 9router sh -lc 'ls -la /home/node/.codex /home/node/.claude /home/node/.config/opencode /home/node/.local/share/kilo'
```

Expected output should show symlinks like:

```text
/home/node/.codex -> /home/user/.codex
/home/node/.claude -> /home/user/.claude
/home/node/.config/opencode -> /home/user/.config/opencode
/home/node/.local/share/kilo -> /home/user/.local/share/kilo
```

Verify dashboard API:

```bash
curl http://127.0.0.1:20128/api/cli-tools/all-statuses
```

Open dashboard:

```text
http://127.0.0.1:20128/dashboard/cli-tools
```

If the dashboard still shows old status, hard refresh the browser or restart the container:

```bash
sudo docker restart 9router
```

Tools only show as installed when their expected host config exists or the binary exists inside the container. For example, `jcode`, `openclaw`, and `deepseek-tui` will still show `not installed` if they are not installed on the host.

## Pass This Skill To Agents.ai / Codex Agents

Give the agent this repo and this prompt:

```text
Use the 9Router Docker CLI Sync skill from:
https://github.com/afu-it/9router-docker-cli-sync

Problem: 9Router runs in Docker, and /dashboard/cli-tools shows CLI tools as not installed even though they are installed on the host. Fix it by making the Docker container read and write the real host CLI config files, not copied container-only files.

Requirements:
1. Confirm the 9Router container name, default is 9router.
2. Confirm the container was started with host home mounted as /home/user.
3. If not mounted, tell me the exact docker run command to recreate it safely.
4. Run scripts/sync-9router-cli-symlinks.sh against the container.
5. Verify symlinks under /home/node point to /home/user.
6. Verify http://127.0.0.1:20128/api/cli-tools/all-statuses shows installed/has9Router for available host tools.
7. Do not copy configs into the container. Use real symlinks only.
```

If the agent supports skills directly, use:

```text
Use $9router-docker-cli-sync to make 9Router Docker detect and edit host CLI tool configs.
```

## Security Note

Mounting `$HOME:/home/user` exposes the full host home to the 9Router container. This is intentional for the full symlink approach. If you prefer least privilege, mount only the needed config folders instead of the whole home directory.
