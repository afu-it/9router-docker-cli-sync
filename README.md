# 9Router Docker CLI Sync

Codex skill to repair 9Router Docker CLI tool detection by symlinking 9Router's container home (`/home/node`) to real host configs mounted at `/home/user`.

Use when Docker 9Router shows CLI tools as `not installed` even though npm 9Router detected them on the host.

## Quick Use

Start 9Router with host home mounted:

```bash
sudo docker run -d \
  --name 9router \
  -p 20128:20128 \
  -v "$HOME:/home/user" \
  -v "$HOME/.9router:/app/data" \
  -e DATA_DIR=/app/data \
  decolua/9router:latest
```

Run sync:

```bash
bash scripts/sync-9router-cli-symlinks.sh
```

Verify:

```bash
curl http://127.0.0.1:20128/api/cli-tools/all-statuses
```
