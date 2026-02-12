#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS_ENV="/root/.openclaw/workspace/secrets/cloudflare.env"

if [[ ! -f "$SECRETS_ENV" ]]; then
  echo "Missing $SECRETS_ENV" >&2
  exit 1
fi

set -a
source "$SECRETS_ENV"
set +a

cd "$ROOT_DIR"

# Ensure wrangler is available
if [[ ! -d node_modules/wrangler ]]; then
  npm i -D wrangler@4 >/dev/null
fi

# 1) Deploy to Cloudflare Pages
npx wrangler pages deploy . --project-name devcrx-landing --commit-dirty=true

# 2) Backup to GitHub (commit+push)
# Avoid committing secrets by accident
if git status --porcelain | grep -qE '^\?\? secrets/|^\?\? .*\.env$|^\?\? /root/.openclaw/'; then
  echo "Refusing to commit: potential secrets detected in repo." >&2
  git status --porcelain | head -n 50 >&2
  exit 2
fi

if [[ -n "$(git status --porcelain)" ]]; then
  git add -A
  git commit -m "chore: backup deploy $(date -u +'%Y-%m-%dT%H:%M:%SZ')" || true
fi

git push
