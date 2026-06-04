---
finding_id: R3-F01
severity: high
change_type: correctness
referenced_files:
  - skills/reviewer-protocol/first-party-emission.md:29
  - skills/reviewer-protocol/third-party-emission.md:38
  - skills/reviewer-protocol/SKILL.md:53-62
  - tests/unit/test-per-finding-file-emission.bats:188-208
artifact: task-03
round: 3
reviewer: silent-failure-claude
---

# F01 — Schema cross-reference defers audit-fields and finding_id uniqueness rules to a SKILL.md section that does not contain them (high · correctness)

R3's Fix 2 replaced verbatim duplicated schema prose in both emission siblings with a single cross-reference sentence:

> **Schema fields, audit fields, and `finding_id` uniqueness rules are as defined in `skills/reviewer-protocol/SKILL.md ## Finding Schema` — that file is authoritative.**

(see `first-party-emission.md:29` and `third-party-emission.md:38`).

The pre-dedupe sibling prose authoritatively specified three distinct rule sets:

1. **Schema fields** — the 5-field canonical schema with `severity` ∈ `low|medium|high` and `change_type` ∈ `style|clarity|correctness|scope|intent` enums.
2. **Audit fields** — `artifact`, `round`, `reviewer` (the last "must equal `<reviewer_tag>` and the filename prefix").
3. **`finding_id` uniqueness** — unique per `(round, reviewer_tag)`; canonical form `R{NN}-F{NN}`; schema-guard regex `^R\d+-F\d+$`.

Of these three, **only (1) is present** in `SKILL.md ## Finding Schema` (lines 53–62). I read the full 220-line SKILL.md and confirmed:

- The string `audit field` / `audit fields` appears **nowhere** in SKILL.md.
- The uniqueness scoping `(round, reviewer_tag)` appears **nowhere** in SKILL.md.
- The canonical form `R{NN}-F{NN}` appears **nowhere** in SKILL.md (only an example `R3-F02` inside the `finding_id` field description, which is illustrative, not normative).
- The schema-guard regex `^R\d+-F\d+$` appears **nowhere** in SKILL.md.
- The requirement that the YAML `reviewer:` audit-field value must equal `<reviewer_tag>` appears **nowhere** in SKILL.md (it survives only in `first-party-emission.md:72` for first-party, but that's now orphaned from the "authoritative" target it cross-references).

**This is a silent-failure surface.** A future reader, validator, or apply-fix step-2 guard following the cross-reference to find:

- The `finding_id` schema-guard regex `^R\d+-F\d+$` (load-bearing for any structural validation tool)
- The audit-field requirement that `reviewer:` must equal `<reviewer_tag>` (load-bearing for the splitter and for the dispatcher's tag-match contract)
- The `(round, reviewer_tag)` uniqueness scope (load-bearing for cross-round threading — finding_id `R3-F01` from `quality-claude` must not collide with `R3-F01` from `scope-claude` only because the tag scopes the namespace)

…will find none of those rules anywhere. The cross-reference appears authoritative but resolves to incomplete content. The dedupe consolidated the *reference* but did not migrate the *content*.

**Why this is silent rather than loud:** the new bats test "emission sibling files do not reproduce verbatim schema paragraphs from SKILL.md" (test-per-finding-file-emission.bats:188-208) verifies two things:

1. Siblings do **not** contain the string `'canonical 5-field finding schema'` (i.e. the verbatim removed paragraph is gone).
2. Siblings contain a cross-reference to `'skills/reviewer-protocol/SKILL.md'`.

It does **not** verify that `SKILL.md ## Finding Schema` actually contains the deferred audit-fields paragraph or the `finding_id` uniqueness / canonical-form / schema-guard-regex specification. The test will continue to pass indefinitely even though the spec content the cross-reference promises is missing. This is the classic "the test pins the citation but not the citation's target" failure mode.

**DoD impact:** Task-03's DoD includes "SKILL.md contains no emission-contract prose" and "the canonical 5-field finding schema lives in SKILL.md as the authoritative source" (implied by Fix 2's dedupe rationale). The first half is satisfied; the second half is now *partially false* — only the schema-fields half of the rule set survived the move.

**In-scope T03 R3 fix.** Two paths, either suffices:

1. **(Recommended) Extend `SKILL.md ## Finding Schema`** with the two missing paragraphs (audit fields; finding_id uniqueness with canonical form `R{NN}-F{NN}` and schema-guard regex `^R\d+-F\d+$`). After this, the cross-reference is honest and the dedupe is complete. Add a corresponding bats assertion that grep-pins those strings in SKILL.md so the cross-reference target is structurally guarded:

   ```bash
   @test "SKILL.md ## Finding Schema contains the deferred audit-fields and finding_id uniqueness rules" {
     local f="skills/reviewer-protocol/SKILL.md"
     grep -qF 'audit field' "$f" || { echo "audit fields paragraph missing"; return 1; }
     grep -qF '(round, reviewer_tag)' "$f" || { echo "finding_id uniqueness scope missing"; return 1; }
     grep -qF '^R\d+-F\d+$' "$f" || { echo "finding_id schema-guard regex missing"; return 1; }
   }
   ```

2. **(Alternative) Revert Fix 2's dedupe** and keep the three paragraphs in each sibling. This restores the spec content but trades duplication-prevention for completeness — generally the worse choice once the cross-reference idiom is established.

Path 1 closes the silent failure surface and makes the test suite enforce the cross-reference's promise. Without it, the dedupe ships a spec gap that no test catches.
