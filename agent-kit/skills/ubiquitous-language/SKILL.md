---
name: ubiquitous-language
description: Build or refresh the project's shared glossary (CONTEXT.md) so the user, the code, and the agent use the same domain terms. Use when starting work in an unfamiliar codebase, when terminology is fuzzy or inconsistent, or when a new domain term is settled.
argument-hint: "[area of the codebase to focus on]"
---

# Ubiquitous Language

From Domain-Driven Design: conversations, code, and documentation should all use the same words for the same things. A short, precise glossary lets you think and write with fewer words and keeps the implementation aligned with the plan.

The glossary lives in `CONTEXT.md` at the repo root. In a monorepo with several distinct domains, use one `CONTEXT.md` per domain and a root `CONTEXT-MAP.md` pointing to each one.

## Build or refresh the glossary

1. **Scan for terms.** Look at type and class names, database tables and columns, route and endpoint names, UI copy, test names, README and docs, and issue titles. Focus on $ARGUMENTS if given.
2. **Group synonyms.** Where several names mean one thing (`client`, `customer`, `buyer`), pick one canonical term and list the others as aliases to avoid.
3. **Flag conflicts.** Where one name means several things, or the code disagrees with the docs, list it under **Ambiguities** and ask the user to settle it. Don't guess.
4. **Write `CONTEXT.md`** in the format below. Keep it a glossary: no implementation details, file paths, or plans.
5. **Show the user** the new or changed terms and ask them to correct anything wrong.

## Format

```markdown
# <Project> context

<One or two sentences on what the product does and for whom.>

## Terms

| Term | Meaning | Avoid saying |
| --- | --- | --- |
| Invoice | A request for payment sent to a Customer for one or more Line Items. | bill, receipt |
| Customer | The business or person an Invoice is addressed to. | client, buyer |

## Relationships

- An **Invoice** belongs to exactly one **Customer** and has one or more **Line Items**.

## States and lifecycles

- **Invoice**: Draft → Sent → Paid, or Sent → Overdue → Paid.

## Ambiguities

- "Account": the signed-in User, or the Customer's billing account? (to settle)
```

## Using it every session

- Read `CONTEXT.md` before planning or coding, and use its terms in code names, commit messages, tests, and replies.
- When the user uses a term that conflicts with the glossary, say so straight away and ask which is meant.
- When a new term is settled during `/grill-me` or planning, add it to `CONTEXT.md` right away rather than at the end.
