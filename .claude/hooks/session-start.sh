#!/bin/bash
# Cloud sessions start in a fresh container, so install agent-kit (skills,
# workflow guide, gstack) into ~/.claude from this checkout. This is a fallback
# for when the cloud environment's setup script doesn't already do it; local
# machines use the one-time global install described in agent-kit/README.md.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

"$CLAUDE_PROJECT_DIR/agent-kit/install.sh"
