---
name: grill-me
description: Interview the user relentlessly about a plan or design until you both share the same design concept. Run it before planning or building anything non-trivial.
disable-model-invocation: true
argument-hint: "[the feature, change or idea to grill]"
---

# Grill Me

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one by one.

The goal is a shared **design concept** (Brooks, *The Design of Design*): the idea of the thing we are building that lives in both our heads. It is not a document. Do not write a plan, a spec, or any code until I confirm we share it.

Topic: $ARGUMENTS

## How to run the session

1. **Read before asking.** Skim the code, `CONTEXT.md` (the project glossary, if present), `docs/prd/`, and `docs/adr/` so your questions use the project's words and skip what the code already answers. Facts are your job: never ask me something you can look up (file layout, current behaviour, installed tools). If a lookup is slow, hand it to a sub-agent and keep asking the questions that don't depend on it.

2. **Map the design tree.** Every decision branches into the decisions that hang off it. The **frontier** is every open decision whose prerequisites are already settled.

3. **Ask in rounds.** Each round asks the whole frontier, numbered, each with your recommended answer so I can accept it in one word:

   ```
   ❓ Q1: <short title>
   <the question, with the options if there are any>
   ➡️ Recommended: <your answer and a one-line reason>

   ❓ Q2: ...
   ```

   Then stop and wait for my answers. A question that depends on another open question in the same round belongs in a later round.

4. **Recompute after every answer.** Settled decisions unlock new ones. Push back when an answer contradicts an earlier one, the code, or the glossary: "Earlier you said X, this implies not-X. Which one?" Invent concrete edge-case scenarios to test fuzzy answers.

5. **Keep the language sharp.** When I use a vague or overloaded term, propose one precise name. When a term is settled, add it to `CONTEXT.md` (see the `ubiquitous-language` skill).

6. **Cover the whole tree:** users and goals, scope and non-goals, data and state, module changes and their interfaces, error cases, security and permissions, migration or rollout, and how we will test it (which seams).

## Finishing

The session is done when the frontier is empty: every branch visited, nothing silently assumed. Then:

- Summarise the shared design concept as a short list of settled decisions, and list anything we explicitly deferred.
- Ask me to confirm the summary.
- Suggest the next step: `/write-a-prd` for a feature, or `/prd-to-issues` directly for a small change.
