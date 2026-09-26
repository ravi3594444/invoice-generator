---
name: plan-sessions
description: Estimate how much agent work a build request needs and split it into separate Claude Code sessions - what runs first, what can run in parallel, and a ready-to-paste prompt for each. Use at the start of any request to build an app, site, or feature bigger than a small fix, or when the user asks how many sessions or agents a job needs.
argument-hint: "[what to build]"
---

# Plan Sessions

One agent session does its best work on one focused slice that fits comfortably in its context window and ends in something verifiable. A big job crammed into one session drifts, forgets earlier decisions, and produces worse code. So before building anything bigger than a small fix, tell the user how big the job is and how to split it into sessions they can run separately.

## 1. Check for premade parts first

Run the `reuse-first` process, at least briefly. Templates, component libraries, and packages change the size a lot: a store built on a maintained starter might take a handful of sessions, and the same store from scratch dozens.

If the request is too vague to size, ask the two or three questions that change the size most (for example: which pages, is there a backend, payments or not, which stack), or suggest `/grill-me` first.

## 2. Size it

A session is about one vertical slice: one feature end to end, touching up to roughly 10 to 15 files, finished with passing tests or a browser check.

| Size | Sessions | Typical example |
| --- | --- | --- |
| XS | This session, minutes | Fix a bug, restyle a section, add a form field |
| S | 1 | One page or one feature, with tests |
| M | 2 to 4 | A portfolio site from a template, with a blog and a contact form |
| L | 5 to 10 | An online store from a starter: catalog, cart, checkout, accounts |
| XL | More than 10 | A new product from scratch: split into milestones and plan the first in detail |

For **XS**, say "This fits in this session" in one line and do it. No plan needed.

## 3. Split it into sessions

- **Session 1 is the foundation.** Scaffold from the chosen template, install the libraries, and fix the shared contracts the other sessions build on: data types, API shapes, routes, design tokens, the `CONTEXT.md` glossary. Parallel sessions start only after it is merged.
- **Sessions that touch the same files run one after another.** Sessions that touch separate areas can run at the same time, each on its own branch.
- **Put unknowns first.** A risky integration (a payment provider, an unfamiliar API) gets a short spike session before the sessions that depend on it.
- **Every session ends verifiable**, with passing tests, a browser check where there is UI, and a commit or pull request.
- **Finish with an integration session** when parallel work has to come together: merge, run the full test suite, and do a browser QA pass (`/qa` or `browser-check`).

## 4. Present the plan

Start with a summary like this:

```
## Size: L, about 6 sessions (up to 3 at once)

Reuse: Medusa Next.js starter + shadcn/ui. From scratch this would be about 15 sessions.

| # | Session | Delivers | Needs | Can run alongside |
| --- | --- | --- | --- | --- |
| 1 | Foundation | Starter running, brand theme, shared types | - | - |
| 2 | Catalog | Product list, filters, product page | 1 | 3, 4 |
| 3 | Cart and checkout | Cart, Stripe test checkout | 1 | 2, 4 |
| 4 | Accounts | Sign-up, login, order history | 1 | 2, 3 |
| 5 | Content and SEO | Home, about, metadata, sitemap | 2 | - |
| 6 | Integration and QA | Everything merged, full browser QA | 2-5 | - |

Order: 1 → (2, 3, 4 at the same time) → 5 → 6
```

Then give one copy-paste prompt per session:

```
Session 3 of 6: Cart and checkout
Repo: <owner/repo>. Branch: feat/cart-checkout, from main after session 1 is merged.
Goal: <one or two sentences>
Read first: CONTEXT.md, docs/prd/<slug>.md, and the shared types from session 1.
Reuse: <libraries and components to use>
Done when:
- [ ] <observable behaviour>
- [ ] Tests pass (build it with the tdd skill); browser-check PASS on /cart and /checkout
Don't touch: catalog pages, auth.
When finished, open a pull request and summarise what changed.
```

Mark estimates as rough: they are for splitting the work, not for deadlines.

## 5. Next steps

- Ask which session to run here (usually session 1).
- Offer to save the plan to `docs/plan/<slug>.md`, or to turn the sessions into GitHub issues with `/prd-to-issues`.
- For parallel work on a local machine, suggest one git worktree per session (`git worktree add ../<repo>-cart -b feat/cart-checkout`) so they don't collide. In Claude Code cloud, each new session gets its own container and branch.
- If a tool for starting new sessions is available (for example Claude Code Remote's `create_session`), offer to launch the parallel sessions with their prompts. Launch them only after the user says yes.
- If a session turns out bigger than planned, stop at a clean point, commit, and give an updated plan with the prompt for the next session.
