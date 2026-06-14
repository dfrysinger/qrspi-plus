# Review Log Artifact Format

Read this file for the full markdown template of `reviews/tasks/task-NN-review.md`, the per-task review log. Main chat (the orchestrator) writes this file; reviewer subagents return findings to main chat, which assembles the log.

## File path

`reviews/tasks/task-NN-review.md` where `NN` is the zero-padded task number (e.g., `task-03-review.md`, `task-15-review.md`).

## Format

```markdown
---
task: NN
---

# Task NN Review

## Round 1 — Correctness

### spec-reviewer

**Model:** {actual model identifier, e.g., claude-opus-4-5}
**Prompt:**
{verbatim prompt sent to this reviewer}

**Response:**
{verbatim response received from this reviewer}

### {next reviewer}
{repeat the spec-reviewer block format for each correctness reviewer:
code-quality-reviewer, silent-failure-hunter, security-reviewer}

## Round 1 — Thoroughness (deep only)

### goal-traceability-reviewer
{same block format — repeat for: test-coverage-reviewer, type-design-analyzer, code-simplifier}

## Post-review fixes (round 1)
- {what was changed and why}

## Round 2 — Correctness
{repeat reviewer sections as above}

## Round 2 — Thoroughness (deep only)
{repeat reviewer sections as above}

## Post-review fixes (round 2)
- {what was changed and why}
```

## Skipped reviewers

When a reviewer is skipped (e.g., `type-design-analyzer` when no new types are introduced), include the section with:

```markdown
### type-design-analyzer

**Model:** skipped
**Response:** {why this reviewer was skipped, e.g., "No new types introduced in this task"}
```

## Codex subsections

When Codex is enabled, each reviewer section includes a `#### Codex` subsection after the Response carrying a **reference path** to the per-reviewer per-round Codex file (not the verbatim Codex output — finding text never enters main chat per the disk-write contract):

```markdown
### spec-reviewer

**Model:** {actual model identifier}
**Prompt:**
{verbatim prompt}

**Response:**
{verbatim response}

#### Codex

**Output file:** `reviews/tasks/task-NN/round-NN/<reviewer_tag>.finding-F<NN>.md`
**Status:** {success | ceiling-hit | crash | infra-fail | launch-fail}
```

The per-reviewer per-round Codex file holds verbatim Codex stdout on exit-0; per the shared launch-await pattern, on non-zero exit codes (10 ceiling-hit / 11 crash / 13|14 infra-fail) the **orchestrator** writes the corresponding explicit note into the same file before recording Status. Apply-fix dispatch reads each referenced Codex file at dispatch time to merge findings with the Claude reviewer findings.

## Rules

- Main chat (the orchestrator) writes this file — not the reviewer subagents.
- **Prompt and Response fields are verbatim** — no summarization, no paraphrasing.
- **Model identifiers are actual** — use the real model ID (e.g., `claude-opus-4-5`), not generic names.
- The `task` frontmatter field is **required** and must match the task number (numeric, no padding).
- Post-review fixes sections appear **between rounds**, listing what changed and why.
- Correctness reviewers: `spec-reviewer`, `code-quality-reviewer`, `silent-failure-hunter`, `security-reviewer`.
- Thoroughness reviewers (deep only): `goal-traceability-reviewer`, `test-coverage-reviewer`, `type-design-analyzer`, `code-simplifier`.
