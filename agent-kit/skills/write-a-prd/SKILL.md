---
name: write-a-prd
description: Turn the current conversation (ideally a finished /grill-me session) into a product requirements document saved in the repo, with module changes and interfaces spelled out.
disable-model-invocation: true
argument-hint: "[feature name]"
---

# Write a PRD

Synthesize what we have already discussed into a PRD. Do not start a new interview. If a decision the PRD needs was never made, list it under **Open questions** rather than inventing an answer. If almost nothing has been discussed yet, tell me to run `/grill-me` first.

Feature: $ARGUMENTS

## Process

1. **Explore the codebase** if you have not already. Read `CONTEXT.md` and use its terms everywhere in the PRD. Respect any ADRs in `docs/adr/`.

2. **Check for premade parts.** If we haven't yet, run the `reuse-first` process so the PRD builds on existing templates, libraries, and components wherever they fit.

3. **Map the modules.** Work out which modules the feature creates or changes and how their interfaces change. Prefer deep modules: a small interface in front of a lot of behaviour (see the `deep-modules` skill). Pick the test seams: the highest-level interfaces we can test the feature through. Fewer seams is better.

4. **Check the module map and seams with me** before writing the whole document. This is the part I care about most.

5. **Write the PRD** to `docs/prd/<feature-slug>.md` using the template below. Create the folder if needed.

6. **Offer to publish it** as a GitHub issue, labelled `prd` (use `gh` if it is installed and logged in, otherwise the GitHub MCP tools). Then suggest `/prd-to-issues docs/prd/<feature-slug>.md`.

## Template

```markdown
# PRD: <Feature name>

Status: draft · Date: <YYYY-MM-DD>

## Problem
The problem from the user's point of view.

## Solution
The solution from the user's point of view.

## User stories
A long, numbered list covering every behaviour, in the form:
1. As a <actor>, I want <capability>, so that <benefit>.

## Reused building blocks
Templates, libraries, and components we build on instead of writing from scratch (see the `reuse-first` skill):
| Building block | Using | License | Notes |
| --- | --- | --- | --- |

## Module changes
For each module that is created or changed:
- **<Module name>** (new | changed): its purpose in one sentence.
  - Interface: what callers must know (operations, inputs and outputs, errors, invariants).
  - What it hides behind that interface.

## Implementation decisions
Architecture, schema changes, API contracts, and other decisions we made, with the reason for each.

## Testing decisions
- Seams under test and the behaviours checked at each one.
- What gets mocked (only true external boundaries: network, clock, payment provider, and so on).
- Prior art: similar tests that already exist in the codebase.

## Out of scope
What this PRD deliberately does not cover.

## Open questions
Decisions still to make, and who makes them.
```

Keep file paths and code snippets out of the PRD: they go stale fast. The one exception is a small type, schema, or state machine that states a decision more precisely than prose can.
