# First-Party Reviewer Emission

This file defines the on-disk emission contract for **first-party reviewer dispatches** — reviewer subagents running in the host environment with full filesystem access, where the Write tool is available. Codex / third-party reviewers run in a read-only sandbox and follow `skills/reviewer-protocol/third-party-emission.md` instead. The two files are siblings: every reviewer dispatch follows exactly one of them; there is no third path.

The shared, transport-neutral protocol surfaces — finding schema, change-type classifier, untrusted-data handling, phase routing, dispatch contract — live in `skills/reviewer-protocol/SKILL.md` and apply equally to both emission paths.

## First-Party Emission Contract

First-party reviewers emit findings as files under the per-round directory `<round_subdir>` supplied by the dispatcher. The on-disk schema is identical to what the third-party splitter materializes — only the writer differs.

> **IRON RULE — exactly one finding per file. Never combine findings.** The Apply-fix protocol dispatches one Haiku verifier per `*.finding-*.md` file in parallel; combining findings causes the verifier to score them as a unit, which breaks the change-type partition (style/clarity/correctness score-filtering applies to the bundle instead of each finding). Two findings = two files, every time. Zero findings → write one `<reviewer_tag>.clean.md` sentinel (defined below). Never write zero files for an expected reviewer tag — the schema-violation guard at apply-fix step 2 surfaces the §3 menu when an expected tag emits no output.

**Per-finding file format.** YAML frontmatter (4 schema fields + 3 audit fields) + body (prose `message`):

```yaml
---
finding_id: R3-F02
severity: high
change_type: correctness
referenced_files: [skills/design/SKILL.md]
artifact: design
round: 3
reviewer: quality-claude
---

{message body — multi-paragraph prose, the 5th schema field, transported in the body to avoid YAML quoting}
```

**Schema fields** (the canonical 5-field finding schema): `finding_id`, `severity` ∈ `low|medium|high`, `change_type` ∈ `style|clarity|correctness|scope|intent`, `referenced_files` (list), `message` (body).

**Audit fields** (frontmatter only): `artifact`, `round`, `reviewer` (must equal `<reviewer_tag>` and the filename prefix).

**`finding_id` uniqueness** — unique per `(round, reviewer_tag)`. Canonical form `R{NN}-F{NN}`. Schema-guard regex: `^R\d+-F\d+$`.

**Clean-round sentinel** — when a reviewer's analysis surfaces zero findings, write a single `<round_subdir>/<reviewer_tag>.clean.md` with a frontmatter-only body (`reviewer: <tag>`, `round: <NN>`, `findings: 0`):

```markdown
---
reviewer: <reviewer_tag>
round: <round-number>
findings: 0
---
```

**Reviewer brief-return shape** — exactly five lines, in this order:

```
Step: <artifact-name>
Round: <round-number>
Reviewer: <reviewer_tag>
Findings: N (high=X, medium=Y, low=Z)
Written to: <round_subdir>/
```

(Partial-write failures — some finding files persisted, some not — are not separately signaled. The schema-violation guard at apply-fix step 2 catches only the all-or-nothing case where the expected tag produced ZERO output.)

**Trailing newline** — every per-finding file ends with exactly one `\n` (deterministic byte-level normalize-then-warn at apply-fix step 2 if malformed).

### Write-Tool Requirements

First-party reviewers MUST emit findings using the Write tool. The Write tool is available in the host environment; calls succeed and the orchestrator reads the resulting files from disk on the reviewer's behalf.

- Use the Write tool for every per-finding file and for the clean-round sentinel — one Write call per file.
- Do NOT emit finding bodies, summaries, or boundary-prefixed blocks in the chat reply. The chat reply carries only the five-line brief-return shape above.
- Do NOT batch multiple findings into one Write call — one Write per finding file (IRON RULE above).
- A reviewer that returns finding content in chat without writing the corresponding files is treated as having emitted zero findings for that tag.

### Path Rules

The on-disk file paths for first-party emission are fixed by the dispatcher-supplied `<round_subdir>` and `<reviewer_tag>` values:

- **Per-finding file:** `<round_subdir>/<reviewer_tag>.finding-F<NN>.md` — F-numbered zero-padded in emission order. One file per finding.
- **Clean-round sentinel:** `<round_subdir>/<reviewer_tag>.clean.md` — exactly one file when the reviewer surfaces zero findings; absent when any finding files exist.

The filename prefix is the dispatcher-supplied `<reviewer_tag>` (e.g., `quality-claude`, `scope-claude`, `spec-claude`). The `reviewer:` audit-field value MUST equal that prefix.

**Iron law: emit findings ONLY by Write tool to `<round_subdir>/<reviewer_tag>.finding-F<NN>.md` (one file per finding) or `<round_subdir>/<reviewer_tag>.clean.md` (zero-findings sentinel). Any other channel — chat-only return, narrative reply, stdout emission, summary prose — is a contract violation and produces zero findings for your tag. The orchestrator's apply-fix step will report 'expected tag produced no output' and the round will fail to converge.**
