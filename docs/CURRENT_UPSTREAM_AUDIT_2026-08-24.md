# lean-effects current-upstream audit — 2026-08-24

This document supersedes the June 2026 CSLib extraction queue **for current upstream decisions**. The older extraction ledger remains a record of the local 4.31 implementation and proof work; its upstream ordering is no longer current because CSLib has since developed substantial `FreeM` infrastructure.

## Audit baseline

Local compatibility audit:

- Lean: `leanprover/lean4:v4.34.0-rc2`
- Mathlib: `dc84fcbe9e049439c1c36d6db290cc0565f77788` (master, 2026-08-24)
- Build status on this baseline: **pending CI** until the audit branch workflow completes successfully.

Upstream comparison:

- CSLib main uses the same Lean `v4.34.0-rc2` toolchain as of 2026-08-24.
- Relevant current modules include:
  - `Cslib/Foundations/Control/Monad/Free.lean`
  - `Cslib/Foundations/Control/Monad/Free/Effects.lean`
  - `Cslib/Foundations/Control/Monad/Free/Fold.lean`

No current-build claim should be inferred from the older 4.31 certification.

## Decision table

| Local stream | June plan | Current finding | Decision |
|---|---|---|---|
| Free monad core | first CSLib PR | CSLib now has a mature `FreeM` core with lawful monad structure, lifting/interpreting operations, and a universal property | Retire as upstream proposal |
| Fold / generic interpretation | second CSLib PR | CSLib now has `FreeM.foldFreeM` and its uniqueness theorem | Retire as upstream proposal |
| State | early example PR | CSLib already has `FreeState` and a canonical `StateM` interpreter | Retire as upstream proposal |
| Reader | example PR | CSLib already has a FreeM reader development | Retire as upstream proposal |
| Writer | example PR | CSLib already has a FreeM writer development | Retire as upstream proposal |
| Continuations | local/later work | CSLib already has a FreeM continuation development | Retire as upstream proposal |
| Exception | example/effect module | No corresponding current CSLib FreeM exception module was found in the 2026-08-24 audit searches | Candidate after native port to CSLib `FreeM` |
| Nondeterminism | example/effect module | No corresponding current CSLib FreeM nondeterminism module was found in the audit searches | Candidate after simplification and native port |
| Sum/product signatures | modular effects | Potentially useful, but must be diffed against current CSLib before proposing an abstraction | Research |
| Lawvere theories | later foundational layer | Too early; not justified by current downstream evidence | Defer |
| DSL/tactics | much later | Local automation; primitive upstream API not validated | Keep local |

## 1. Do not upstream a second Free monad

Current CSLib's `FreeM` is not merely a placeholder. Its present stack already provides the foundational capabilities targeted by the June extraction plan:

- a freer-style indexed operation representation;
- `Functor`, `Monad`, `LawfulFunctor`, and `LawfulMonad` infrastructure;
- operation lifting;
- interpretation through `liftM`;
- an `Interprets` relation and uniqueness/universal-property results;
- a separate `foldFreeM` catamorphism with a uniqueness theorem;
- executable State, Writer, Reader, and Continuation examples/interpreters.

Therefore the local `FreeMonad`, generic handler core, and fold implementation are now research/reference material, not CSLib candidates.

Any new CSLib contribution from this repository must **extend `Cslib.FreeM`**, not compete with it.

## 2. Exception is the strongest near-term effect candidate

The local exception development contains a useful effect semantics, but its present representation should not be copied upstream verbatim.

The current local `Exception.throw` requires `[Inhabited α]` and manufactures an unreachable continuation returning `default`. That is an artifact of the local `FreeMonad` representation.

CSLib's indexed freer-style `FreeM` can represent an exception operation directly without inventing a fake return value. A native port should therefore be smaller and conceptually cleaner than the local implementation.

### Target shape for a CSLib-native experiment

The first experiment should contain only:

- an indexed exception operation signature;
- a `FreeException` abbreviation over `Cslib.FreeM`;
- `throw`;
- an interpreter to `Except ε` (or the current CSLib-preferred exception target);
- computation/simp lemmas;
- an interpreter uniqueness result obtained from existing `FreeM` infrastructure;
- `catch` only if it has a clean compositional formulation on the chosen representation.

It should **not** introduce:

- another `Handler` hierarchy;
- another free monad;
- a DSL;
- tactics;
- generic transformer machinery unless demanded by the basic semantics.

## 3. Nondeterminism is promising but should start smaller

The local nondeterminism implementation is mathematically richer than the likely first upstream slice. It introduces `BindCommute` to justify interpretation over base monads where independent branch binds commute.

That abstraction may eventually be valuable, but it is too much design surface for the first native CSLib port.

### Recommended staging

**Stage N1 — bare nondeterminism**

- indexed `empty` / choice operations;
- `FreeM` representation;
- interpretation into `List`;
- basic computation laws and examples.

**Stage N2 — modular signature composition**

Only after current CSLib overlap is audited and there is a concrete consumer.

**Stage N3 — commutative-base interpretation**

Only if real developments require interpretation of nondeterminism over a base monad and the commutativity law recurs independently. At that point compare `BindCommute` against existing Mathlib/CSLib algebraic abstractions before introducing a new typeclass.

## 4. `mapConst` is not upstreamable evidence

The local extraction ledger records a `mapConst` axiom used to accommodate indexed signatures in the older local architecture.

That axiom must not cross the upstream boundary.

A successful native port onto `Cslib.FreeM` should eliminate the need for it. If a proposed effect still depends on an equivalent axiom after the port, that is evidence that the abstraction has not been reconciled with CSLib's representation.

## 5. Longer-term semantic bridge

Current CSLib already has substantial labelled-transition-system infrastructure, including simulation, bisimulation, trace equivalence, weak bisimulation, execution, and related semantics.

Therefore the longer-term opportunity is not to introduce another LTS hierarchy. It is to connect effectful syntax/interpreters to the existing semantics stack.

A high-value research direction is:

`FreeM program syntax → operational LTS → handler-induced simulation/bisimulation`.

Potential theorem families include:

- a small-step LTS generated by `FreeM` operations;
- an interpreter/handler inducing a simulation between source and target operational semantics;
- sufficient conditions for two handlers to yield bisimilar or trace-equivalent executions;
- modular effects preserving semantic equivalence under signature extension.

These are research objectives, not current PR claims.

## 6. Current upstream candidate ranking

### A. FreeM Exception

Potential value: **medium-high**.
Readiness: **prototype needed**.
Primary requirement: native implementation over current CSLib `FreeM` with no duplicate handler hierarchy.

### B. Basic FreeM nondeterminism

Potential value: **medium-high**.
Readiness: **prototype needed**.
Primary requirement: start with simple `List` semantics; defer `BindCommute`.

### C. Effect-signature composition

Potential value: **medium to high** if concrete consumers demonstrate the need.
Readiness: **research / overlap audit**.

### D. FreeM-to-LTS semantics

Potential value: **high**.
Readiness: **research**.
This is the most promising route to the broader verified-CS vision, but it should not be rushed into an upstream PR.

### Retired as current CSLib proposals

- local Free monad core;
- generic fold/interpretation core;
- State/Reader/Writer examples already represented upstream;
- parallel handler hierarchy;
- DSL/tactics at this stage.

## 7. Acceptance gate for any effects-derived CSLib PR

A candidate may move to `PR_READY` only when:

1. it is implemented natively on current CSLib abstractions;
2. current CSLib and open PRs do not already contain an equivalent capability;
3. the local proof has no `sorry`, `admit`, custom axiom, or experimental-tactic dependency;
4. a real executable or semantic use case demonstrates the API;
5. the contribution is minimal and does not create a parallel hierarchy;
6. current `lake test`, `checkInitImports`, lint/import checks, and relevant minimized-import checks pass in the upstream workspace;
7. AI assistance is disclosed in accordance with CSLib/Mathlib policy and the contributor personally understands every submitted declaration and proof.

## 8. Immediate work queue

1. Obtain CI evidence for this 4.34/current-Mathlib audit branch.
2. Prototype Exception directly against current `Cslib.FreeM`.
3. Prototype minimal List-valued nondeterminism directly against current `Cslib.FreeM`.
4. Audit current CSLib for signature-sum/product abstractions before any composition proposal.
5. Map `FreeM` operational structure into current CSLib LTS definitions as a research experiment.
6. Do not prepare a CSLib PR until one of these native experiments passes the acceptance gate.
