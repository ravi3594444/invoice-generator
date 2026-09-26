---
name: improve-codebase-architecture
description: Find clusters of shallow modules in the codebase and propose deepening refactors that make it easier to test and for agents to navigate, then grill through the one the user picks.
disable-model-invocation: true
argument-hint: "[area or pain point to focus on]"
---

# Improve Codebase Architecture

Find places where related code is spread across many shallow modules, and propose wrapping each cluster in one **deep module** with a small, testable interface. Use the vocabulary in the `deep-modules` skill (module, interface, depth, seam, adapter) exactly. Use `CONTEXT.md` terms for the domain.

Focus: $ARGUMENTS

## 1. Explore

- If the user named an area, start there. Otherwise, find hot spots: run `git log --since=3.months --name-only --pretty=format: | sort | uniq -c | sort -rn | head -30` and give the most-changed areas priority. Refactoring code nobody touches pays nothing back.
- Read `CONTEXT.md` and any ADRs in `docs/adr/`. Don't re-propose something an ADR rejected unless the friction is now serious; if you do, say so.
- Walk the code (a sub-agent is good for this) and note friction:
  - Understanding one concept means jumping between many small files.
  - An interface is nearly as complex as its implementation.
  - Callers repeat the same setup, validation, or error handling.
  - Code can't be tested without reaching into its internals or mocking many collaborators.
  - Changes keep touching the same group of files together.
- Apply the deletion test to each suspected shallow module.

## 2. Present candidates

For each candidate, give:

- **Name:** the deep module you'd create, named with a `CONTEXT.md` term.
- **Modules involved:** what gets absorbed.
- **Problem:** the friction today, concretely.
- **Proposed interface (sketch):** the few operations callers would use.
- **Benefits:** what gets simpler for callers, what gets easier to test, which tests could be deleted or replaced.
- **Before and after:** a small diagram (Mermaid or ASCII) of the call structure.
- **Strength:** Strong, Worth exploring, or Speculative.

End with your top recommendation and why, then ask: "Which of these do you want to explore?"

## 3. Grill the chosen candidate

Run the `/grill-me` process on the chosen refactor: constraints, what moves behind the seam, the exact interface, error behaviour, migration steps, and which tests survive. Design the interface with care; the implementation can be delegated.

As decisions settle:

- Add new module or concept names to `CONTEXT.md`.
- If the user rejects a candidate for a lasting reason, offer to record it as an ADR in `docs/adr/NNNN-<slug>.md` so future reviews don't suggest it again.
- When agreed, suggest `/write-a-prd` or `/prd-to-issues` so the refactor lands as small, test-first steps (`/tdd`), with the new interface's tests written first.
