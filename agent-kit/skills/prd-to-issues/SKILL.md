---
name: prd-to-issues
description: Break a PRD, plan, or the current conversation into small vertical-slice issues with blocking edges, then publish them to GitHub Issues (or local markdown files) so an agent can pick them up.
disable-model-invocation: true
argument-hint: "[PRD path, issue number, or URL]"
---

# PRD to Issues

Break the work into **tracer-bullet issues**: thin vertical slices that each cut through every layer the feature touches (data, logic, API, UI, tests) and are demoable on their own.

Source: $ARGUMENTS (if empty, use the most recent PRD in `docs/prd/` or the current conversation).

## Process

1. **Gather context.** Read the source in full. For a GitHub issue, read its body and comments too. Read `CONTEXT.md` and use its terms in every title and description.

2. **Explore the code.** Look for prefactoring that makes the feature easy to add ("make the change easy, then make the easy change"). Prefactoring becomes the first issues.

3. **Draft the slices.**
   - Each slice is a narrow but complete path through every layer, never "all the database work" as one issue.
   - Each slice fits in one fresh agent session and ends in something verifiable: a passing test, a working screen, a working endpoint. Size and order them with the rules in the `plan-sessions` skill, and mark which issues can run in parallel sessions.
   - Each slice names the premade parts it should use (from the PRD's reused building blocks), so the agent doesn't write them from scratch.
   - Each slice lists the issues that **block** it. A slice with no blockers can start now.
   - A wide mechanical refactor (a rename or retype across the codebase) is the exception. Sequence it as expand, then migrate in batches, then contract, so every step stays green.

4. **Quiz me.** Show a numbered list with, for each issue: title, blocked by, can run alongside, and what it delivers. Ask whether the granularity is right, whether the blocking edges are right, and whether anything should be merged or split. Iterate until I approve.

5. **Publish** in dependency order (blockers first) so later issues can reference real numbers:
   - **GitHub via `gh`** when `gh auth status` succeeds: `gh issue create --title ... --body-file ... --label ready-for-agent`. Create the label first if it is missing.
   - **GitHub via MCP tools** (for example `mcp__github__issue_write`) when `gh` is not available, as in Claude Code cloud sessions.
   - **Local files** when there is no GitHub remote or I ask for it: one file per issue at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered in dependency order.
   - If the source was a GitHub issue, link each new issue to it as the parent. Never close or edit the parent.

6. **Report** the created issues as a list of links, and name the ones that can start right away.

## Issue template

```markdown
## Parent
<link to the PRD file or parent issue>

## What to build
The end-to-end behaviour this slice makes work, from the user's point of view.

## Reuse
Libraries, components, or template parts to build on.

## Acceptance criteria
- [ ] <observable behaviour, checked through a public interface>
- [ ] Tests written test-first (`/tdd`) and passing

## Blocked by
- <#issue> or "None, can start immediately"
```

Keep file paths and code snippets out of issues unless a snippet states a decision more precisely than prose can.
