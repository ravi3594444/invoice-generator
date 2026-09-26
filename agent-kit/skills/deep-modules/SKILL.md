---
name: deep-modules
description: Shared vocabulary and rules for designing deep modules (small interface, lots of hidden behaviour, testable at the seam). Use when designing or changing a module's interface, deciding where tests go, or when another skill asks for the deep-module vocabulary.
---

# Deep Modules

From John Ousterhout, *A Philosophy of Software Design*: complexity is anything about a system's structure that makes it hard to understand and change. Deep modules fight it. They hide a lot of behaviour behind a small, simple interface. Shallow modules expose an interface nearly as complex as what they do.

A codebase of a few deep modules is easier for both humans and agents to navigate, easier to test, and cheaper to change. A codebase of many tiny shallow modules forces every reader to walk through them all.

## Vocabulary

Use these terms exactly.

- **Module:** anything with an interface and an implementation. A function, a class, a package, or a slice through several layers.
- **Interface:** everything a caller must know to use the module correctly: operations, inputs and outputs, errors, invariants, ordering rules, performance.
- **Implementation:** the code inside the module.
- **Depth:** how much behaviour a caller gets per unit of interface they have to learn.
- **Seam:** the place where a module's interface sits and where tests observe it.
- **Adapter:** a concrete thing plugged in at a seam (a Postgres store, an in-memory fake, a Stripe client).

## Rules

1. **Design the interface, delegate the implementation.** The human (or you, carefully) owns the interface: its name, operations, types, and error behaviour. The implementation behind a well-tested interface can be treated as a grey box.
2. **The interface is the test surface.** Tests call the module through the same interface its callers use. If you need to test past the interface, the module is the wrong shape.
3. **Deletion test.** Imagine deleting the module and inlining it into its callers. If complexity spreads across many callers, the module earns its keep. If nothing changes, it was a pass-through; merge it.
4. **One adapter is a hypothetical seam, two is a real one.** Don't add an abstraction layer until something actually varies across it (real and fake count as two).
5. **Accept dependencies, don't create them.** Pass in the clock, the HTTP client, and the payment gateway, so tests can supply fakes.
6. **Return results instead of producing side effects** where you can. A pure core with a thin shell of I/O is easy to test.
7. **Pull complexity down.** When a caller must do extra work to use a module correctly, move that work inside the module.

## Checklist when designing an interface

- Can the number of operations shrink?
- Can the parameters be simpler, or have sensible defaults?
- Can more of the complexity (retries, validation, formatting, caching) live inside?
- Does its name come from `CONTEXT.md`?
- Could a test exercise most of the behaviour through this interface alone?

For hard interfaces, design it twice: sketch two or three very different interfaces (sub-agents work well for this), compare them on depth and ease of testing, then pick one.
