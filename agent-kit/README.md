# agent-kit

A set of Claude Code skills that load in **every session, in every repo, on your own computer and in Claude Code cloud**. Based on Matt Pocock's talk *"Software fundamentals matter more than ever"*, plus Garry Tan's [gstack](https://github.com/garrytan/gstack).

The idea: code is not cheap. A codebase that is hard to change wastes what AI can do, so the agent should align with you first, speak your domain language, work in small test-first steps, check its work in a real browser, and keep modules deep.

## What you get

| Command | What it does |
| --- | --- |
| `reuse-first` | Before writing code, finds premade parts: UI component libraries (shadcn/ui, Magic UI, daisyUI, ...), starter templates and open-source repos (e-commerce, portfolio, SaaS), and packages. Reads their latest docs, then builds on them instead of from scratch. |
| `plan-sessions` | For anything you ask it to build, says how big the job is and splits it into separate sessions: what goes first, what can run in parallel, and a ready-to-paste prompt for each. |
| `/grill-me <idea>` | Interviews you round by round until you and the agent share one design. No code before that. |
| `/write-a-prd` | Turns the agreed design into a PRD in `docs/prd/`, including module changes and interfaces. |
| `/prd-to-issues` | Splits a PRD into small vertical-slice GitHub issues with "blocked by" links. |
| `/improve-codebase-architecture` | Finds clusters of shallow modules and proposes deep-module refactors. |
| `tdd` | Red, green, refactor in small steps. The agent uses it on its own when building or fixing. |
| `ubiquitous-language` | Builds and maintains `CONTEXT.md`, the shared glossary of domain terms. |
| `deep-modules` | The design vocabulary: design the interface, delegate the implementation, test at the seam. |
| `browser-check` | Opens a page in headless Chromium (Playwright), runs clicks and fills, reports console errors and failed requests, and takes a screenshot. |
| `/gstack` and friends | gstack's suite: `/browse`, `/qa`, `/review`, `/ship`, `/investigate`, `/office-hours`, `/plan-eng-review`, `/retro`, and more. |

The installer also adds a short workflow guide to `~/.claude/CLAUDE.md`, so every new session knows the rules: reuse premade parts first, size the job and split it into sessions, then grill, PRD, issues, TDD, browser check.

Skills without a slash in the table are picked up by the agent on its own when they fit. You can still type them (`/tdd`, `/browser-check`, ...).

## Install on your computer (once)

Needs `git` and `node`. For gstack, also [Bun](https://bun.sh) (`curl -fsSL https://bun.sh/install | bash`).

```bash
curl -fsSL https://raw.githubusercontent.com/ravi3594444/invoice-generator/main/agent-kit/install.sh | bash
```

Everything goes into `~/.claude/`, which Claude Code reads in every project. Restart Claude Code afterwards. Run the same line again any time to update.

On Windows, run it from Git Bash or WSL.

## Turn it on for every Claude Code cloud session

Cloud sessions start in a fresh container each time, so the install has to run at the start of each one. Add it to your cloud environment's setup script once:

1. Open [claude.ai/code](https://claude.ai/code), open the environment menu, and choose **Edit** on the environment you use.
2. In **Setup script**, add:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/ravi3594444/invoice-generator/main/agent-kit/install.sh | bash
   ```

3. Save. Every new session in that environment gets the skills, whatever repo it opens.

If you use several environments, add the line to each one. The environment's network access must allow `github.com` and `raw.githubusercontent.com`. If setup fails with a blocked host, add those hosts to the environment's allowed domains or choose a broader access level.

This repo also has a SessionStart hook (`.claude/hooks/session-start.sh`) that runs the installer in cloud sessions, so sessions for this repo get the kit even without the setup script.

## Optional: up-to-date library docs with Context7

`reuse-first` already reads official docs, `llms.txt` files, and GitHub READMEs. On your own computer you can also add the [Context7](https://github.com/upstash/context7) MCP server, which serves version-specific docs for thousands of libraries:

```bash
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp
```

`--scope user` makes it available in every project. The installer doesn't do this for you because it changes your MCP configuration.

## Options

Set these before `bash`, for example `curl -fsSL ... | AGENT_KIT_SKIP_GSTACK=1 bash`.

| Variable | Effect |
| --- | --- |
| `AGENT_KIT_REF` | Branch or tag to install from (default `main`). |
| `AGENT_KIT_REPO` | Install from a fork instead. |
| `AGENT_KIT_SKIP_GSTACK=1` | Don't install gstack. |
| `AGENT_KIT_SKIP_BROWSER=1` | Don't install Playwright on a local machine. |

The install log is at `~/.claude/agent-kit-install.log`.

## How it works

- Skills are copied into `~/.claude/skills/<name>/`, each marked with an `.agent-kit-owned` file. The installer only replaces folders it created, so a skill of your own with the same name is never overwritten. Skills removed from the kit are removed on the next install.
- The workflow guide sits in `~/.claude/CLAUDE.md` between `<!-- agent-kit:start -->` and `<!-- agent-kit:end -->`. The rest of that file is left alone.
- gstack is cloned to `~/.claude/skills/gstack` and set up with its own `./setup`. After that it updates itself.
- In Claude Code cloud, Chromium is preinstalled and browsers must not be downloaded. gstack pins a newer headless Chromium build, so the installer points that build at the preinstalled one instead.

## Change the skills

Edit the files in `agent-kit/skills/`, push to `main`, and re-run the installer. Each skill is a folder with a `SKILL.md`: YAML front matter (`name`, `description`, and `disable-model-invocation: true` for slash-only commands) followed by the instructions.

## Uninstall

```bash
for d in ~/.claude/skills/*/; do [ -f "$d/.agent-kit-owned" ] && rm -rf "$d"; done
~/.claude/skills/gstack/bin/gstack-uninstall   # removes gstack
```

Then delete the `agent-kit` block from `~/.claude/CLAUDE.md`, and remove the setup-script line from your cloud environments.

## Credits

- Matt Pocock, [mattpocock/skills](https://github.com/mattpocock/skills) (MIT), the source of `grill-me`, the PRD and issue flow, `tdd`, ubiquitous language, and deep-module architecture. The skills here are rewritten for this kit.
- Garry Tan, [gstack](https://github.com/garrytan/gstack) (MIT), installed as is.
- The books behind them: *A Philosophy of Software Design* (Ousterhout), *The Pragmatic Programmer* (Thomas and Hunt), *The Design of Design* (Brooks), *Domain-Driven Design* (Evans), and Kent Beck on TDD.
