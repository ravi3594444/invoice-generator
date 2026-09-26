## Engineering workflow (agent-kit)

Code is not cheap: a codebase that is hard to change wastes everything an agent can do. Keep the design healthy on every change. Installed from `ravi3594444/invoice-generator/agent-kit`; re-run its `install.sh` to update.

**For any non-trivial change, follow this flow:**

1. `/grill-me <idea>`: interview until we share one design concept. No plan or code before that.
2. `/write-a-prd`: write the agreed design to `docs/prd/`, with module changes and interfaces.
3. `/prd-to-issues`: split it into vertical-slice issues with blocking edges.
4. Build each issue test-first with the `tdd` skill: red, green, refactor, in small steps.
5. Verify UI changes in a real browser: gstack `/browse` or `/qa`, or the `browser-check` skill.
6. `/improve-codebase-architecture` now and then to turn clusters of shallow modules into deep ones.

**Every session:**

- Read `CONTEXT.md` (the domain glossary) if it exists and use its terms; keep it current with the `ubiquitous-language` skill.
- Design interfaces with care and delegate implementations; test through the interface (`deep-modules` skill).
- The rate of feedback is your speed limit: after each small step, run the relevant tests and the typechecker.
- gstack is installed as well: `/gstack` lists its commands (`/office-hours`, `/plan-eng-review`, `/review`, `/investigate`, `/qa`, `/ship`, `/retro`, and more).
