---
finding_id: F02
reviewer_tag: code-quality-claude
severity: medium
change_type: correctness
referenced_files:
  - skills/using-qrspi/SKILL.md:412-418
---

## Stale "Per-host Codex dispatch transport routing" section left adjacent to migrated detection paragraph

The diff adds the new vendor-neutral "**Second-model-reviewer detection:**" paragraph at
`using-qrspi/SKILL.md:406-411`, immediately before the pre-existing "**Per-host Codex
dispatch transport routing.**" section at lines 412-418. That adjacent section was not
updated by this migration and now contains stale API references:

- **Line 412:** Heading still reads "**Per-host Codex dispatch transport routing.**" —
  uses the vendor-specific "Codex" noun while the detection paragraph it now follows is
  vendor-neutral.

- **Line 417 (mismatch policy):** Still references `codex_reviews` (the retired field
  name) in a runtime-behavior description:
  > "…disagrees with the `codex_reviews` config value"

  And still references `check_codex_available` (the retired probe function):
  > "when `check_codex_available` reports Codex is not available…"

After the migration, `codex_reviews` is a hard validation error (not a valid field) and
`check_codex_available` no longer exists. An operator reading this section would follow
documentation that describes a non-existent API.

The mismatch-policy paragraph also references `codex_reviews: true` as a valid run
configuration value ("the user opted out" sentence), which contradicts the explicit
validation-error rule added by this same diff at using-qrspi lines 302-307.

**Suggested fix:** Update the "**Per-host Codex dispatch transport routing.**" section to
replace `codex_reviews` with `second_reviewer`, replace `check_codex_available` with
`bash scripts/second-reviewer-available.sh`, and update the mismatch-policy to describe
the new probe contract. The heading itself should be migrated to vendor-neutral language.
