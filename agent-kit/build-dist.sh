#!/usr/bin/env bash
# Build downloadable ZIPs of the kit (default output: agent-kit/dist/):
#
#   agent-kit-skills.zip      every skill as its own folder, for Claude Code
#                             (unzip into ~/.claude/skills)
#   engineering-workflow.zip  all skills combined into one skill, for uploading
#                             to the Claude app (Settings > Capabilities > Skills)
#
# Usage: ./build-dist.sh [output-dir]
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$(mkdir -p "${1:-$KIT/dist}" && cd "${1:-$KIT/dist}" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
rm -f "$OUT/agent-kit-skills.zip" "$OUT/engineering-workflow.zip"

(cd "$KIT/skills" && zip -qr "$OUT/agent-kit-skills.zip" . -x '*/.agent-kit-owned')

# The combined skill: a router SKILL.md plus one reference file per skill.
COMBINED="$WORK/engineering-workflow"
mkdir -p "$COMBINED/reference" "$COMBINED/scripts"
cp "$KIT/claude-ai/SKILL.md" "$COMBINED/SKILL.md"
for dir in "$KIT"/skills/*/; do
  name="$(basename "$dir")"
  # Drop the YAML front matter and Claude Code's $ARGUMENTS placeholders, and
  # point file links at their new names inside the combined skill.
  awk 'NR == 1 && $0 == "---" { fm = 1; next } fm && $0 == "---" { fm = 0; next } fm { next } { print }' "$dir/SKILL.md" \
    | sed -E \
        -e '/^(Topic|Feature|Focus|Project): \$ARGUMENTS$/d' \
        -e 's/^Source: \$ARGUMENTS \(if empty, use/Source: what the user named (if nothing, use/' \
        -e 's/ Focus on \$ARGUMENTS if given\./ Focus on the area the user named, if any./' \
        -e 's#\[CATALOG\.md\]\(CATALOG\.md\)#[reuse-catalog.md](reuse-catalog.md)#' \
        -e 's#^The script is `scripts/browser-check\.mjs`, next to this file\.#The script is `scripts/browser-check.mjs` in this skill'"'"'s folder.#' \
        -e 's# \(usually `~/\.claude/skills/browser-check/`\)##' \
    > "$COMBINED/reference/$name.md"
  if grep -q '\$ARGUMENTS' "$COMBINED/reference/$name.md"; then
    echo "build-dist: unhandled \$ARGUMENTS left in $name; update the sed rules" >&2
    exit 1
  fi
done
cp "$KIT/skills/reuse-first/CATALOG.md" "$COMBINED/reference/reuse-catalog.md"
cp "$KIT/skills/browser-check/scripts/browser-check.mjs" "$COMBINED/scripts/"
(cd "$WORK" && zip -qr "$OUT/engineering-workflow.zip" engineering-workflow)

echo "$OUT/agent-kit-skills.zip"
echo "$OUT/engineering-workflow.zip"
