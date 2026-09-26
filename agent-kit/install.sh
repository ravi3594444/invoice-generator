#!/usr/bin/env bash
# agent-kit installer.
#
# Installs the engineering-workflow skills (/grill-me, /write-a-prd,
# /prd-to-issues, /tdd, ...) into ~/.claude/skills, adds the workflow guide to
# ~/.claude/CLAUDE.md, and installs gstack (/gstack, /browse, /qa, /review,
# /ship, ...). Anything in ~/.claude applies to every Claude Code session on
# the machine, in every repo.
#
#   Local machine (once, re-run to update):
#     curl -fsSL https://raw.githubusercontent.com/ravi3594444/invoice-generator/main/agent-kit/install.sh | bash
#
#   Claude Code cloud: paste the same line into the environment's Setup script.
#
# Options (environment variables):
#   AGENT_KIT_REPO          git URL to install from (default: this repo)
#   AGENT_KIT_REF           branch or tag to install (default: main)
#   AGENT_KIT_SKIP_GSTACK=1 don't install gstack
#   AGENT_KIT_SKIP_BROWSER=1 don't install Playwright on a local machine
#   CLAUDE_CONFIG_DIR       Claude config dir (default: ~/.claude)
#
# Safe to run repeatedly. Progress goes to stderr, so it can also run as a
# SessionStart hook without adding noise to the session.

set -uo pipefail

REPO="${AGENT_KIT_REPO:-https://github.com/ravi3594444/invoice-generator.git}"
REF="${AGENT_KIT_REF:-main}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILLS_DIR="$CLAUDE_DIR/skills"
GSTACK_DIR="$SKILLS_DIR/gstack"
LOG="$CLAUDE_DIR/agent-kit-install.log"
OWNED_MARKER=".agent-kit-owned"
BLOCK_START="<!-- agent-kit:start -->"
BLOCK_END="<!-- agent-kit:end -->"

log() { printf '[agent-kit] %s\n' "$*" >&2; }

mkdir -p "$SKILLS_DIR"
: > "$LOG"

# Claude Code cloud containers ship Chromium under /opt/pw-browsers and must
# not download browsers.
PW_DIR="${PLAYWRIGHT_BROWSERS_PATH:-}"
if [ -z "$PW_DIR" ] && [ -d /opt/pw-browsers ]; then PW_DIR=/opt/pw-browsers; fi
PREINSTALLED_BROWSERS=0
if [ -n "$PW_DIR" ] && ls -d "$PW_DIR"/chromium_headless_shell-* >/dev/null 2>&1; then PREINSTALLED_BROWSERS=1; fi

# ── 1. Locate the kit ──────────────────────────────────────────
# Use the checkout this script lives in; when piped from curl, clone it.
KIT=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  [ -d "$SCRIPT_DIR/skills" ] && KIT="$SCRIPT_DIR"
fi
if [ -z "$KIT" ]; then
  SRC="$CLAUDE_DIR/agent-kit-src"
  if [ -d "$SRC/.git" ] && git -C "$SRC" fetch -q --depth 1 origin "$REF" >>"$LOG" 2>&1; then
    git -C "$SRC" reset -q --hard FETCH_HEAD
  else
    rm -rf "$SRC"
    if ! git clone -q --depth 1 --branch "$REF" "$REPO" "$SRC" >>"$LOG" 2>&1; then
      log "could not clone $REPO ($REF); see $LOG"
      exit 1
    fi
  fi
  KIT="$SRC/agent-kit"
fi
if [ ! -d "$KIT/skills" ]; then
  log "no skills folder found at $KIT"
  exit 1
fi
VERSION="$(cat "$KIT/VERSION" 2>/dev/null || echo dev)"

# ── 2. Skills ──────────────────────────────────────────────────
# Only replace folders this installer created, so a skill you wrote yourself
# with the same name is never overwritten.
installed=()
for src in "$KIT"/skills/*/; do
  name="$(basename "$src")"
  dest="$SKILLS_DIR/$name"
  if [ -e "$dest" ] && [ ! -f "$dest/$OWNED_MARKER" ]; then
    log "skipped $name: $dest already exists and was not installed by agent-kit"
    continue
  fi
  rm -rf "$dest"
  cp -R "$src" "$dest"
  printf '%s\n' "$VERSION" > "$dest/$OWNED_MARKER"
  installed+=("$name")
done

# Remove skills that were dropped from the kit.
for dest in "$SKILLS_DIR"/*/; do
  name="$(basename "$dest")"
  if [ -f "$dest/$OWNED_MARKER" ] && [ ! -d "$KIT/skills/$name" ]; then
    rm -rf "$dest"
    log "removed $name (no longer in the kit)"
  fi
done

# ── 3. Global workflow guide in ~/.claude/CLAUDE.md ─────────────
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
touch "$CLAUDE_MD"
tmp="$(mktemp)"
# Drop any previous agent-kit block and trailing blank lines, then append the current one.
awk -v s="$BLOCK_START" -v e="$BLOCK_END" '
  $0 == s { skip = 1; next }
  $0 == e { skip = 0; next }
  skip { next }
  NF == 0 { blank++; next }
  { for (i = 0; i < blank; i++) print ""; blank = 0; print }
' "$CLAUDE_MD" > "$tmp"
{
  [ -s "$tmp" ] && printf '\n'
  printf '%s\n' "$BLOCK_START"
  cat "$KIT/CLAUDE.global.md"
  printf '%s\n' "$BLOCK_END"
} >> "$tmp"
cat "$tmp" > "$CLAUDE_MD"
rm -f "$tmp"

# ── 4. gstack ──────────────────────────────────────────────────
gstack_status="skipped"

# Newer Playwright releases pin a newer headless Chromium than the one the
# cloud image ships. Point the pinned build at the preinstalled one instead of
# downloading.
link_preinstalled_chromium() {
  [ "$PREINSTALLED_BROWSERS" = 1 ] || return 0
  [ "$(uname -m)" = x86_64 ] || return 0
  local browsers_json="$GSTACK_DIR/node_modules/playwright-core/browsers.json"
  [ -f "$browsers_json" ] || return 0
  local rev
  rev="$(node -e 'const b = require(process.argv[1]).browsers.find((x) => x.name === "chromium-headless-shell"); process.stdout.write(b ? String(b.revision) : "")' "$browsers_json" 2>/dev/null)"
  [ -n "$rev" ] || return 0
  [ -e "$PW_DIR/chromium_headless_shell-$rev" ] && return 0
  local existing
  existing="$(ls -d "$PW_DIR"/chromium_headless_shell-* 2>/dev/null | awk -F- '{ print $NF " " $0 }' | sort -n | tail -1 | cut -d' ' -f2-)"
  local bin=""
  for candidate in "$existing/chrome-linux/headless_shell" "$existing/chrome-headless-shell-linux64/chrome-headless-shell"; do
    [ -x "$candidate" ] && bin="$candidate" && break
  done
  [ -n "$bin" ] || return 0
  local target="$PW_DIR/chromium_headless_shell-$rev/chrome-headless-shell-linux64"
  if mkdir -p "$target" 2>/dev/null && ln -sf "$bin" "$target/chrome-headless-shell" && touch "$PW_DIR/chromium_headless_shell-$rev/INSTALLATION_COMPLETE"; then
    log "linked headless Chromium $rev to the preinstalled $(basename "$existing")"
  else
    log "could not link headless Chromium $rev into $PW_DIR (not writable?)"
  fi
}

install_gstack() {
  if [ "${AGENT_KIT_SKIP_GSTACK:-0}" = 1 ]; then return 0; fi
  if ! command -v bun >/dev/null 2>&1; then
    gstack_status="skipped: needs Bun (https://bun.sh), then re-run this installer"
    return 0
  fi
  if [ ! -d "$GSTACK_DIR" ]; then
    log "cloning gstack..."
    if ! git clone -q --single-branch --depth 1 https://github.com/garrytan/gstack.git "$GSTACK_DIR" >>"$LOG" 2>&1; then
      gstack_status="failed to clone; see $LOG"
      return 0
    fi
  fi
  if [ ! -x "$GSTACK_DIR/browse/dist/browse" ]; then
    log "running gstack setup (first run takes a minute or two)..."
    local skip_pw=0
    [ "$PREINSTALLED_BROWSERS" = 1 ] && skip_pw=1
    if ! (cd "$GSTACK_DIR" && GSTACK_SKIP_PLAYWRIGHT="$skip_pw" ./setup --no-prefix -q </dev/null) >>"$LOG" 2>&1; then
      gstack_status="setup failed; see $LOG"
      return 0
    fi
  fi
  link_preinstalled_chromium
  gstack_status="installed ($(cat "$GSTACK_DIR/VERSION" 2>/dev/null || echo unknown version); updates itself, or run /gstack-upgrade)"
}
install_gstack

# ── 5. Playwright for /browser-check on a local machine ─────────
browser_status="ready"
playwright_found() {
  node -e '
    const { createRequire } = require("module");
    const path = require("path");
    const { execSync } = require("child_process");
    const bases = [process.cwd(), path.join(require("os").homedir(), ".claude", "skills", "gstack")];
    try { bases.push(execSync("npm root -g", { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim()); } catch {}
    for (const b of bases) { try { createRequire(path.join(b, "noop.js")).resolve("playwright"); process.exit(0); } catch {} }
    process.exit(1);
  ' >/dev/null 2>&1
}
if ! command -v node >/dev/null 2>&1; then
  browser_status="needs Node.js"
elif playwright_found; then
  :
elif [ "$PREINSTALLED_BROWSERS" = 1 ] || [ "${AGENT_KIT_SKIP_BROWSER:-0}" = 1 ]; then
  browser_status="Playwright not found (skipped)"
elif command -v npm >/dev/null 2>&1; then
  log "installing Playwright and Chromium..."
  if npm install -g playwright >>"$LOG" 2>&1 && npx -y playwright install chromium >>"$LOG" 2>&1; then
    browser_status="installed Playwright + Chromium"
  else
    browser_status="Playwright install failed (try: npm install -g playwright && npx playwright install chromium); see $LOG"
  fi
else
  browser_status="needs npm to install Playwright"
fi

# ── Summary ────────────────────────────────────────────────────
log "agent-kit $VERSION installed into $CLAUDE_DIR"
log "  skills:  ${installed[*]:-none}"
log "  guide:   $CLAUDE_MD"
log "  gstack:  $gstack_status"
log "  browser: $browser_status"
exit 0
