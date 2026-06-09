# Modernization and extraction sprint

This document records the first modernization and extraction plan for `lean-effects` as part of the broader category-theory contribution program targeting Mathlib and CSLib.

## Current repository position

`lean-effects` formalizes algebraic effects through Lawvere-theory-style descriptions, free monads, handlers, fusion, standard effects, effect composition, DSL support, and tactics.

This repository is strategically important for CSLib because it connects category-theoretic semantics to executable programming-language infrastructure. It should not be upstreamed as one large effects framework. The first extraction should be a minimal, well-lawed core that CSLib contributors can use and review.

Current constraints:

- Current toolchain in `lean-toolchain`: `leanprover/lean4:v4.16.0`.
- `Lakefile.lean` pins Mathlib at `v4.16.0`.
- The top-level module imports DSL elaboration, free monad, handlers, fusion, five standard effects, composition, and tactics.
- The README positions the repository around Lawvere theories, free monads, handlers, fusion, tactics, and standard effects.

## Sprint objective

The objective is to port the repository to the Lean 4.31 / current-Mathlib line and extract a small CSLib-facing core around free monads, handlers, and standard semantic examples.

The first upstream outputs should be definitions, law statements, and executable examples. DSL elaboration, tactics, and effect-fusion automation should remain local until the core is stable.

## Modernization gates

### Gate 1: port to the current Lean and Mathlib line

Required commands:

```bash
lake update
lake build Effects
lake build Tests
lake exe lean-effects --help
lake exe test-suite
```

Expected first failures to check:

- moved Mathlib imports;
- monad and bind notation changes;
- elaborator API drift in the DSL;
- tactic elaboration drift for `effect_fuse!`, `handler_laws!`, and `local_simp!`;
- executable scripts depending on old IO or Lake APIs.

### Gate 2: split stable core from DSL and automation

Recommended target layout:

```text
src/Effects/Core/Free.lean
src/Effects/Core/Handler.lean
src/Effects/Core/Fusion.lean
src/Effects/Std/State.lean
src/Effects/Std/Reader.lean
src/Effects/Std/Writer.lean
src/Effects/Std/Exception.lean
src/Effects/Std/Nondet.lean
src/Effects/Compose/Sum.lean
src/Effects/Compose/Product.lean
src/Effects/DSL.lean              -- syntax and elaboration only
src/Effects/Automation.lean       -- tactics only
src/Effects.lean                  -- stable public import, without experimental scripts
```

The public import should expose the stable core and standard effects. It should not require DSL elaboration or tactics unless explicitly requested.

### Gate 3: define the CSLib extraction slice

The first CSLib candidate should be one of the following:

1. a minimal `Free` monad API with bind, pure, fold/interpret, and simp lemmas;
2. a minimal handler API with correctness lemmas;
3. standard state and exception examples demonstrating executable semantics.

Do not include the DSL in the first CSLib contribution.

## Extraction targets

### Target A: free monad core

Candidate upstreamable surface:

- `Free` type;
- `pure`, `bind`, `map`;
- monad instance and laws;
- fold or interpretation principle;
- simp lemmas for interpretation of pure and bind.

### Target B: handlers

Candidate upstreamable surface:

- handler structure;
- interpretation function;
- correctness lemmas for pure and bind;
- examples over State and Exception.

### Target C: Lawvere theory layer

The Lawvere-theory layer is mathematically important, but it should come after the free-monad and handler core. The first Lawvere-theory PR should be a design note or minimal structure, not the full DSL.

### Target D: standard effects

Standard effects are useful for CSLib examples, especially:

- State;
- Reader;
- Writer;
- Exception;
- Nondeterminism.

Use them to validate the API and provide examples, not as a reason to upstream all supporting infrastructure at once.

## Non-upstream material for now

The following should remain repository-local during this sprint:

- DSL syntax and elaboration;
- `derive_effect` machinery;
- `effect_fuse!` tactic;
- `handler_laws!` tactic;
- performance monitor;
- coverage report;
- release builder;
- documentation generator scripts;
- broad fusion automation.

## First PR candidates generated from this repo

1. Local modernization PR: port to Lean 4.31 and current Mathlib.
2. Local architecture PR: separate stable core from DSL, automation, and scripts.
3. Local API PR: isolate a minimal free-monad and handler API.
4. CSLib candidate PR: minimal free monad with interpretation lemmas.
5. CSLib candidate PR: state and exception examples over the minimal API.
6. Mathlib discussion candidate: Lawvere-theory design notes only after the free-monad core is stable.

## Build certification status

This document is a planning and extraction artifact. It does not certify that the repository has been built on Lean 4.31 yet. Certification requires a successful local or CI run of the commands in Gate 1.
