---
finding_id: R1-F04
severity: medium
change_type: correctness
referenced_files: [agents/qrspi-test-writer.md, skills/implementer-protocol/SKILL.md]
artifact: integration
round: 1
reviewer: integration-claude
---

## qrspi-test-writer.md performs commit cycle but does not load implementer-protocol skill

**Surface:** `agents/qrspi-test-writer.md:1-6` (frontmatter), `:28` (prose reference) ↔ `skills/implementer-protocol/SKILL.md:162-181` (Commit hygiene invariants)

T2 added commit ownership to the test-writer at line 28 and behavior step 75. Line 28 prose
explicitly names "the implementer-protocol scratch-file pattern" as the contract being applied.

But the agent file's frontmatter has NO `skills:` field. Contrast with
`agents/qrspi-implementer.md:1-5` which declares `skills: [implementer-protocol]` and (per
`implementer-protocol/SKILL.md:10`) gets the protocol body preloaded at agent activation.

The test-writer thus performs a commit cycle named after a contract whose three-invariant
declaration (staging-before-scratch / cleanup-after-commit / worktree-local-exclude) and
pre-DONE hygiene self-check (lines 148-160) are NOT in its prompt context.

**Cross-task impact:** Pre-existing `implementer-protocol` skill (contract surface) and T2's
new "test-writer also commits" mandate (new consumer) converge without integrating. Test-writer
can violate Invariant 1 (staging-before-scratch) or skip the hygiene scan and still report
DONE — none of those constraints are in its prompt.

**Suggested fix:** add `skills: [implementer-protocol]` to test-writer frontmatter so the
invariant prose and hygiene self-check are preloaded. Composes cleanly with existing T2 tool
grant (protocol's self-check needs the Bash + Read grant the test-writer now has).
