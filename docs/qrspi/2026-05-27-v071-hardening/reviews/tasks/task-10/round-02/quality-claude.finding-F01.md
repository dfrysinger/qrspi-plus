---
finding_id: F01
reviewer_tag: quality-claude
round: 2
artifact: task-10
change_type: clarity
severity: 78
location: skills/using-qrspi/SKILL.md:470-484
---

# `#### trusted_path:` block still describes `model_routing:` as keyed by role names after the R1-fix schema replacement

## Problem

The R2 fix replaced the `#### \`model_routing:\`` schema doc (L448–468) and precedence-chain step 3 (L503) to commit to the host→tier→model shape, and dropped a pin test (`tests/unit/test-using-qrspi-vocab.bats`) to keep it that way. That part is clean.

However, the adjacent `#### \`trusted_path:\`` block (L470–484) was not touched, and the schema swap has left it referencing a schema that no longer exists:

**L472 (block intro):**
> A flat list of agent file paths or **role names** that always win over `model_routing:`. When an agent-file path or role name matches an entry in `trusted_path:`, the dispatcher short-circuits ahead of the normal routing chain and routes to the agent-bundled default for that agent or role.

**L477 (example):**
```yaml
trusted_path:
  - agents/qrspi-implementer.md
  - reviewer
```

**L482 (entry shapes):**
> - A role name string (**matches entries in `model_routing:`**).

After R2, `model_routing:` has no role-name entries at any level — top-level keys are host names (`claude-code`, `copilot-cli`); second-level keys are tier names (`haiku`, `sonnet`, `opus`, `inherit`). The string `reviewer` in the L477 example matches nothing in the new schema, and the L482 parenthetical "matches entries in `model_routing:`" is incoherent (there is no `model_routing:` entry to match).

This is precisely the same class of defect as R1's F01 — two sections under the same `### Dispatch routing blocks` parent giving contradictory accounts of what `model_routing:` is keyed by — except the contradiction has migrated from `#### Model Routing` (which R2 fixed) to `#### trusted_path:` (which R2 left alone). A reader of `trusted_path:` semantics now faces the same ambiguity F01 was filed to remove: "are role names a real thing in this schema, or are they retired?"

## Why this matters

The R2 fix-task spec stated its goal explicitly:

> *"the doc must be self-consistent before merge"* — fixes/task-10-round-01/fix-task-01.md L30

That property does not yet hold. The R2 fix narrowed scope to the two surfaces F01 R1 explicitly cited (L448 schema + L494 step 3), but the schema replacement has propagation consequences for any other section that referenced the old shape. `trusted_path:` is such a section: its block intro, its example, and its bullet-list of entry shapes all rest on the assumption that `model_routing:` contains role names.

For a future implementer building dispatcher trusted-path matching logic, the doc currently says: "trusted_path role-name entries match model_routing role-name entries — example: `reviewer`." That implementer would then look at `model_routing:` (per L482's cross-reference), find no `reviewer` key, and either guess at the intent or escalate. Same load-bearing failure mode as R1 F01.

This was not flagged in R1 because neither quality-claude.F01 nor quality-codex.F01 enumerated the trusted_path surface — both findings cited only the schema doc + step 3. R2's fix to those two surfaces unmasked the third one.

## Severity rationale

Clarity finding. Threshold for KEEP per Hotfix B is ≥80. Scoring 78 because:

- Load-bearing in the same way R1 F01 was (78 = "same class of defect, lower visibility than step 3 of a numbered precedence chain")
- Pre-existing wording — the implementer faithfully executed the fix-task spec; the fix-task spec did not name `trusted_path:` as a target
- Surfaced only by the R2 fix landing — genuinely a follow-on

Verifier should decide whether 78 clears the bar. If not, this is the kind of issue that should land as a fast-follow doc patch rather than a R3 round.

## Suggested fix

Either:

**(a) Update the trusted_path block to drop the model_routing cross-reference.** "Role name" in trusted_path becomes a free-standing identifier (matched against agent metadata, not against model_routing keys). Rewrite L472 + L482 accordingly. Replace L477's `- reviewer` example with something less role-shaped (e.g. an explicit second agent-file path) or document where "role names" live in the v0.7.1 schema if they still exist somewhere.

**(b) Retire the role-name half of trusted_path entirely.** If v0.7.1 has no "role name" surface anywhere (T9 dropped `model:` from all 41 agent files and roles no longer appear in any schema), then trusted_path entries should be just agent file paths. Drop L482 second bullet, drop the L477 `- reviewer` example, and rewrite L472 to mention agent file paths only.

Resolution (b) is the cleaner match for the schema-replacement story v0.7.1 commits to elsewhere (T9 + T10 together), but (a) is safer if any other v0.7.1 surface still uses role names.

Either resolution is a few lines of edit to a single section under the same parent the R2 fix already touched. Could land as a small fast-follow patch or be folded into T11 if it's already opening this region.

## Confidence

High that the contradiction exists and is the same class as R1 F01. Medium on the verifier-threshold question (78 vs. 80 is a judgment call).
