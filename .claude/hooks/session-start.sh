#!/bin/bash
set -euo pipefail

# Claude Code cloud sessions only: a local checkout keeps its own node_modules.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

# npm install rather than npm ci: it reuses the node_modules cached with the container.
# --no-save: an older npm than the one that wrote the lockfile must not rewrite it.
npm install --no-save --no-audit --no-fund
