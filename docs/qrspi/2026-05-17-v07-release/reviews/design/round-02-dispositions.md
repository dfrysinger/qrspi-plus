---
round: 02
artifact: design
status: fixing
---

# Round 02 dispositions

## Findings inventory

- quality-claude: 0 findings (clean sentinel)
- scope-claude: 0 findings (clean sentinel)
- quality-codex: 3 findings (high=1, medium=2, low=0)
- scope-codex: 0 findings (clean sentinel)

Total: 3 findings, all from quality-codex. All three are follow-ons from round-1 fixes (fix-introduced defects, not pre-existing issues missed by round 1).

## Verifier skipped this round

`verifier_enabled: true`. All 3 findings cite concrete file:line ranges and describe load-bearing follow-on defects from the round-1 fixes. Recording the skip explicitly.

## Scope-tagger skipped this round

`scope_tagger_enabled: true`. Round 2 still broadens by default. Skipped.

## Per-finding dispositions

All 3 findings classified `accept` and queued for fix-subagent dispatch.

### R2-F01 (high, correctness) — G1 conditional predicate YAML shape invalid

The round-1 fix introduced `condition: <predicate-key>: <value>` as the conditional surface, but that's not valid YAML (it's a 1-level mapping with a placeholder where a key should be). Fix: replace with a concrete parseable shape. Use nested mapping form:

```yaml
condition:
  citation_density_floor: 3
```

State that multiple predicates AND together (a routing entry's predicate map must satisfy all keys). Single-predicate is the typical case.

### R2-F02 (medium, correctness) — G15 promotion-rule bullet drops `type:`

G15 lines 651-654 + 663 say a Formal goal requires all three of `id:` + `type:` + acceptance criteria, but line 658's "Replan's contract" bullet still says "Promotes only Formal goals with an `id:` and acceptance criteria" — omitting `type:`. Fix: update the contract bullet to say "Promotes only Formal goals with all three of `id:`, `type:`, and acceptance criteria from `future-goals.md` to the next phase's `goals.md`."

### R2-F03 (medium, correctness) — Per-goal summary table G7 row stale

Per-goal summary table for G7 reads "Implementer self-check + BATS backstop" but the round-1 narrowing (Decision 4 + cross-cutting test strategy) removed the G7 BATS backstop claim. Fix: update G7's "Primary test surface" cell to "Implementer self-check + reviewer visibility".

## Fix dispatch plan

Single fix subagent. Subagent receives:
- Path to design.md
- Paths to the 3 finding files
- Per-finding fix guidance from this dispositions file

Subagent reports a brief diff summary. Round 3 reviewers fire after fix-subagent confirmation.

## Status

draft → fixing → (post-fix) → re-review round 03.
