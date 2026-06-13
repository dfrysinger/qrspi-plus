---
severity: high
change_type: correctness
location: plan.md § T11 (lines 348–366, specifically the `dependent_tests:` block at 358–359)
---

# F02 — T11 `dependent_tests: none` carries a malformed search-proof shape and a self-contradicting claim

## What

T11 ("Sweep [Tnn] and forbidden-finding-ID tokens from @test descriptions across tests/**/*.bats") is sweep-shaped (>>5 `.bats` files, `Sweep` in the title) and declares the `none` form:

```
- **dependent_tests:** none
  - **search_proof:** `grep -rE '^@test "[^"]*\[T[0-9]+' tests/` returns hits only inside `@test` descriptions (the sweep's own subject); no test file under `tests/` consumes the swept tokens as its own behavioural-claim subject, so the sweep has no consuming-tests dependency to declare.
```

Two distinct defects against `skills/plan/SKILL.md` § Sweep Task Contract:

**Defect A — wrong command shape.** The contract requires the proof command to match the exact shape `grep -rn -- '<quoted-pattern>' tests/` (flags `-rn`, mandatory `--` argument separator, single quoted pattern argument, no additional tokens after `tests/`). The provided command uses `-rE` (no line numbers, ERE-regex extension) and has no `--` separator. Per the reviewer rubric, this shape-validation failure is a malformed-grep-proof finding, emitted in preference to re-running the unvalidated command. Independent of contradiction with the `none` claim (see Defect B), the shape alone is non-conforming.

**Defect B — the proof contradicts the claim it supposedly proves.** The contract's `none` shape exists to demonstrate via zero matches that no consuming test files exist. The T11 prose literally states `returns hits only inside @test descriptions` — i.e., the grep is expected to return non-zero hits. The author then re-interprets those hits as "the sweep's own subject" rather than "consuming tests." Even setting the shape issue aside, a search proof for `dependent_tests: none` whose author concedes the grep returns hits cannot satisfy the contract's well-formedness rule (`zero matches`). The reviewer cannot mechanically re-verify the claim — it requires reading the author's narrative re-classification of every hit, which is exactly what the structural form was designed to remove from the reviewer.

If T11 truly has no consuming tests, the proof should be a grep over a *different* pattern (e.g., a pattern that would match a consuming test's reference to the swept token), constructed so zero hits is the load-bearing assertion. If consuming tests do exist (a possibility worth checking — sweeping `@test` description tokens may break any bats test that asserts a specific description string, e.g., id-hygiene self-tests), they should be listed by path with disposition.

## Why it matters

The Sweep Task Contract's `none` shape is the reviewer's only path to verifying a sweep's safety mechanically. A malformed-shape and self-contradictory-claim variant turns that mechanical check into a narrative review — which both defeats the contract and lets future drift (a new consuming test added between Plan and Implement) slip through silently.

T11 modifies `tests/**/*.bats` — the highest-risk sweep surface in the release, since it touches the very files that test the corpus. Any consuming test (id-hygiene self-tests, test-name fixtures, lint regression-guard fixtures) that the sweep breaks should be enumerated in the plan body so the Implement-phase author knows the paired edits, and so the Phase-1 acceptance criterion's `grep -rE '@test "[^"]*\[T[0-9]+' tests/**/*.bats` zero-match assertion is verifiable as scope-complete.

## Suggested change

Either:

1. List the consuming bats paths with per-file dispositions (one sentence each), if the sweep does touch any test that asserts a now-stripped description string; OR
2. Re-shape the proof to a properly-formed `grep -rn -- '<pattern>' tests/` command whose pattern is the *consumer* shape (e.g., a literal string that a consuming test would search the corpus for), so a zero-hit result is the load-bearing evidence the `none` claim rests on.
