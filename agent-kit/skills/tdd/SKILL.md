---
name: tdd
description: Test-driven development in small red-green-refactor steps. Use when building a feature or fixing a bug, when the user mentions TDD, tests first, or red-green-refactor, or when working an issue from /prd-to-issues.
argument-hint: "[feature, bug, or issue]"
---

# Test-Driven Development

The rate of feedback is your speed limit. Never write a large batch of code and check it afterwards: take one small, verified step at a time.

## Before the first test

1. **Find the feedback loops.** Read `package.json` scripts (or `pyproject.toml`, `Makefile`, CI config) and note the exact commands for running a single test file, the whole suite, the typechecker, and the linter. If the project has no test runner, propose the conventional one for the stack (Vitest for TypeScript and JavaScript, pytest for Python) and ask before adding it.
2. **Agree the seams.** A seam is the public interface you test through. Write down which seams you will test and confirm them with the user before writing any test. Prefer the highest seam that is still fast and reliable, ideally one per feature. See the `deep-modules` skill.
3. **Use the domain language.** Read `CONTEXT.md` so test names match the project's terms.

## The loop

Repeat for each behaviour, one at a time:

1. **Red.** Write one test for the next behaviour. Run it and watch it fail for the right reason (an assertion, not a typo or a missing import).
2. **Green.** Write the least code that makes it pass. No speculative features and no code for tests that don't exist yet.
3. **Check.** Run that test file, then the typechecker. Run the full suite at the end of each slice.
4. **Refactor.** With the tests green, improve the design: remove duplication, deepen the module, sharpen names. Re-run the tests after every refactor.

For a bug, the first red test reproduces the bug. Only then fix it.

## What makes a good test

- It checks behaviour through the public interface, never private functions or internal state. It survives a full rewrite of the implementation.
- It reads like a specification: `"marks an invoice overdue after its due date"`, not `"test updateStatus"`.
- Expected values come from an independent source (a literal, a worked example, the spec), never recomputed the way the code computes them.
- Mock only true external boundaries: network, clock, randomness, payment and email providers. Don't mock your own modules. If a test needs many mocks, the interface is the wrong shape.

## Anti-patterns

- **Horizontal slicing:** writing every test first and then all the code. Go one test, one implementation, repeat.
- **Implementation-coupled tests** that break on a refactor while behaviour stays the same.
- **Outrunning the headlights:** changing several files before running anything.
- **Weakening a test** (or skipping it) to get green. Fix the code, or tell the user the test is wrong and why.

## Browser-facing work

For UI behaviour, finish each slice with a real-browser check: gstack's `/browse` or `/qa` if installed, otherwise the `browser-check` skill. For lasting coverage, add a Playwright test (`@playwright/test`) at the page level.
