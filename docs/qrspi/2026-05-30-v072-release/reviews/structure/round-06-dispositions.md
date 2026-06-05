---
artifact: structure
round: 6
---

# Structure Round 06 — Dispositions

## KEEP (5 findings — apply fix)

### qc-F01 — Rename-inventory drift (4 Create → Rename)
**Action:** In Slice 1.4 File Map, change `Action: Create` to `Action: Rename → …` for the four rows:
- `scripts/dispatch-agent.sh` (renamed from `run-codex-review.sh`; gains universal-entry-point responsibility — note the rename + extension)
- `scripts/dispatch-companion.sh` (renamed from `run-third-party-llm.sh`)
- `scripts/third-party-finding-splitter.sh` (renamed from `codex-finding-splitter.sh`)
- `skills/reviewer-protocol/third-party-emission.md` (renamed from `skills/reviewer-protocol/codex-emission-override.md`)

Pattern: mirror the existing `Rename → skills/_shared/third-party/launch-await-pattern.md` row already present in the slice. Format suggestion: `Rename → <new-path> (from <old-path>)`.

### qc-F03 — CD-2 acceptance #5 using-qrspi pointer unmapped
**Action:** Add `CD-2` to the Goal IDs of the Slice 1.4 `skills/using-qrspi/SKILL.md` row and extend its Responsibility cell with: "Add one-line by-reference pointer to `_shared/evergreen-output-rule.md` from the artifact-quality section per CD-2 acceptance #5 (pointer-only, not `!cat`-included)."

### qcdx-F01 — §10 dispatch_spec missing host/vendor fields
**Action:** Extend §10's `dispatch_spec` block in BOTH the first-party and background examples with `host` and `vendor` fields:
```json
"dispatch_spec": {
  "subagent_type": "qrspi-plan-reviewer",
  "host": "copilot-cli",
  "vendor": "anthropic",
  "model": "claude-sonnet-4.6",
  "prompt_file": "/abs/path/..."
}
```
Field names match the responsibility text at line 37: "host/vendor/model metadata persistence."

### sa-F01 — G31 integration footprint incomplete
**Action (Gap 1 — design/SKILL.md):** Add `G31` to the Slice 1.5 `skills/design/SKILL.md` row's Goal IDs and extend its Responsibility with: "apply prompt-prose-aware authoring step (`!cat skills/_shared/prompt-prose-detection.md` + `!cat skills/_shared/prompt-prose-writer-addition.md` per G31 Consumer #3)."

**Action (Gap 2 — three agent preloads):** Add three Modify rows to Slice 1.5 File Map (or extend existing rows if natural homes exist):
| File | Action | Responsibility | Goal IDs |
|---|---|---|---|
| `agents/qrspi-implementer-lightweight.md` | Modify | Add `prompt-prose-writer` to `skills:` frontmatter preload. | G31 |
| `agents/qrspi-code-quality-reviewer.md` | Modify | Add `prompt-prose-reviewer` to `skills:` frontmatter preload. | G31 |
| `agents/qrspi-plan-spec-reviewer.md` | Modify | Add `prompt-prose-reviewer` to `skills:` frontmatter preload. | G31 |

(Note: `qrspi-code-quality-reviewer.md` already has a Slice 1.4 row — extend it rather than creating a duplicate.)

### sa-F02 — Hook-Point G31 `!cat` sites unlocked
**Action:** Add a new "### G31 prompt-prose-writer `!cat` include sites" subsection to § Hook-Point Locations, modeled after the G34/G35 subsections:

```markdown
### G31 prompt-prose-writer `!cat` include sites

`skills/_shared/prompt-prose-detection.md` + `skills/_shared/prompt-prose-writer-addition.md`
are `!cat`-included directly into SKILL.md consumer files (per design.md G31 Consumers #2–#3).
This is distinct from the `skills:` frontmatter preload used in agent files.

| Consumer file | Section / location |
|---|---|
| `skills/plan/SKILL.md` | writer-subagent dispatch payloads (2 sites): each site carries `!cat skills/_shared/prompt-prose-detection.md` + `!cat skills/_shared/prompt-prose-writer-addition.md` + Addition B verbatim (per design.md G31 Consumer #2) |
| `skills/design/SKILL.md` | authoring step: `!cat skills/_shared/prompt-prose-detection.md` + `!cat skills/_shared/prompt-prose-writer-addition.md` (per design.md G31 Consumer #3) |
```

## DROP (1 finding — no action)

### qc-F02 — CD-2 acceptance #4 reviewer enforcement unmapped (68 → below 70)
Real gap acknowledged by verifier but design.md's "sizing TBD in Plan" softens the structure-altitude requirement. Plan-skill phase will catch this when authoring CD-2 acceptance-criteria-related tasks. No fix in R6.

## Sequence

1. Apply fixes (single fix-r6 dispatch)
2. Single commit (no separate anchor commit — pattern dropped from R5 onward)
3. Write `round-06-commit.txt` as untracked (rides with R7's commit per protocol)
4. Re-loop or declare clean per next-round assessment
