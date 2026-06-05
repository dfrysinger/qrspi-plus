---
finding_id: F01
reviewer_tag: spec-claude
round: 1
severity: medium
change_type: correctness
referenced_files: [tests/unit/test-config-model-routing.bats, skills/using-qrspi/SKILL.md, docs/qrspi/2026-05-30-v072-release/tasks/task-17.md]
---

# spec-claude round-01 F01 — Missing bats assertion for `#### model_routing: block` paragraph back-pointer (TE-4 partial coverage)

**Severity:** medium · **change_type:** correctness · (persisted by orchestrator; claude-sonnet-4.6 returned chat-only)

**What the spec requires.** tasks/task-17.md:49 (Test expectations): "Bats assertion verifies EACH post-Task-16 fail-loud paragraph points back to `### Fields that affect pipeline behavior (must be validated)` by literal heading text." DoD item (4) names both paragraphs: the none-halt `#### model_routing: block` para and the `#### Missing model_routing: block in config.md` para.

**What the implementation delivers.** Only ONE assertion is provided (test at test-config-model-routing.bats:777-783), covering only the `#### Missing model_routing: block in config.md` paragraph. There is NO assertion for the `#### model_routing: block` (none-halt) paragraph at skills/using-qrspi/SKILL.md:466.

**Why it matters.** The production SKILL.md change IS correct — line 466 contains the required back-pointer sentence. But without a bats pin, a future edit that removes/rephrases that sentence in the none-halt paragraph passes the suite silently, defeating the bidirectional cross-link contract the spec enforces.

**Required fix (additive test-only).** Add one bats test to the TE-4 block:

```
@test "model_routing-block fail-loud paragraph back-links to validation table heading by literal text" {
  out="$(_extract_h4 "$USING" '`model_routing:` block')"
  printf '%s\n' "$out" | grep -qF 'Fields that affect pipeline behavior (must be validated)'
}
```

Gives TE-4 full two-paragraph coverage matching the spec's "each" requirement.

**Disposition:** KEEP — dual-family corroborated (spec-codex F01 identical). Additive test-only fix.
