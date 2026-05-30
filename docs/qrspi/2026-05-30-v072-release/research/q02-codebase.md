---
status: draft
question_ids: [2]
research_type: codebase
---

# Q02: Per-reviewer agent `change_type:` field — explicit requirement and allowed-value enumeration vs. SKILL.md schema

## Summary

**TL;DR:** None of the three per-reviewer agent files (`qrspi-silent-failure-hunter.md`, `qrspi-security-reviewer.md`, `qrspi-code-quality-reviewer.md`) explicitly name `change_type:` as a required frontmatter field, nor do any of them enumerate the allowed values. All three delegate entirely to `skills/reviewer-protocol/SKILL.md` via a one-sentence reference and the `skills: [reviewer-protocol]` frontmatter directive. The canonical 5-field schema — including `change_type` with its allowed-value set — lives exclusively in SKILL.md § Per-Finding Disk-Write Contract (line 232). No field-name or allowed-value divergence exists between the agent files and SKILL.md because the agent files simply contain no schema definition at all.

**Key findings:**
- All three agent files include `skills: [reviewer-protocol]` in their YAML frontmatter (lines 5, 5, 5 respectively), loading the skill automatically.
- Each agent file contains exactly one sentence delegating emission details to the skill: "Findings emission follows the disk-write contract from the reviewer-protocol skill (loaded automatically via the `skills:` frontmatter)" — `qrspi-silent-failure-hunter.md:26`, `qrspi-security-reviewer.md:25`, `qrspi-code-quality-reviewer.md:27`.
- Neither `change_type` nor any of its five allowed values (`style`, `clarity`, `correctness`, `scope`, `intent`) appear anywhere in any of the three agent files.
- SKILL.md § Per-Finding Disk-Write Contract (line 232) is the sole location that names `change_type` and enumerates its allowed values: `style|clarity|correctness|scope|intent`.
- The 5-field schema is defined at `skills/reviewer-protocol/SKILL.md:232`: `finding_id`, `severity` ∈ `low|medium|high`, `change_type` ∈ `style|clarity|correctness|scope|intent`, `referenced_files` (list), `message` (body).

**Surprises:** The agent files contain no schema text at all — not even a summary or reminder of the field names. The entirety of the finding-schema specification is loaded by reference through the skill system rather than being inline-duplicated in the agent bodies.

**Caveats:** Only the three named agent files were examined for this comparison; other `qrspi-*-reviewer.md` files were not checked. The SKILL.md file was read via `grep` and `view_range` rather than in full, but the Per-Finding Disk-Write Contract section (lines 208–260) was read completely.

## Full findings

### Agent file: `agents/qrspi-silent-failure-hunter.md`

- **Frontmatter** (`agents/qrspi-silent-failure-hunter.md:1–6`): includes `skills: [reviewer-protocol]`.
- **Delegation sentence** (`agents/qrspi-silent-failure-hunter.md:26`): "Findings emission follows the disk-write contract from the reviewer-protocol skill (loaded automatically via the `skills:` frontmatter): one `<reviewer_tag>.finding-F<NN>.md` file per finding, or a `<reviewer_tag>.clean.md` sentinel when no findings exist."
- **`change_type` present?** No. The field name is not mentioned anywhere in this file.
- **Allowed values enumerated?** No.

### Agent file: `agents/qrspi-security-reviewer.md`

- **Frontmatter** (`agents/qrspi-security-reviewer.md:1–6`): includes `skills: [reviewer-protocol]`.
- **Delegation sentence** (`agents/qrspi-security-reviewer.md:25`): identical wording to the silent-failure-hunter file above.
- **`change_type` present?** No. The field name is not mentioned anywhere in this file.
- **Allowed values enumerated?** No.

### Agent file: `agents/qrspi-code-quality-reviewer.md`

- **Frontmatter** (`agents/qrspi-code-quality-reviewer.md:1–6`): includes `skills: [reviewer-protocol]`.
- **Delegation sentence** (`agents/qrspi-code-quality-reviewer.md:27`): identical wording to the other two files.
- **`change_type` present?** No. The field name is not mentioned anywhere in this file.
- **Allowed values enumerated?** No.

### SKILL.md § Per-Finding Disk-Write Contract

Located at `skills/reviewer-protocol/SKILL.md:208–260`. The canonical schema definition appears at line 232:

> **Schema fields** (the canonical 5-field finding schema): `finding_id`, `severity` ∈ `low|medium|high`, `change_type` ∈ `style|clarity|correctness|scope|intent`, `referenced_files` (list), `message` (body).

The five fields and their constraints are:

| Field | Type | Allowed values / notes |
|---|---|---|
| `finding_id` | string | Canonical form `R{NN}-F{NN}`; unique per `(round, reviewer_tag)` |
| `severity` | enum | `low`, `medium`, `high` |
| `change_type` | enum | `style`, `clarity`, `correctness`, `scope`, `intent` |
| `referenced_files` | list | Absolute or repo-relative paths; line-range citation required for location-tied findings |
| `message` | body (prose) | Multi-paragraph prose, transported in the file body rather than YAML frontmatter |

Three additional **audit fields** appear in frontmatter only: `artifact`, `round`, `reviewer` (`skills/reviewer-protocol/SKILL.md:234`).

The description of `change_type` semantics is expanded further at `SKILL.md:58–59`:

> `change_type` — one of `style`, `clarity`, `correctness`, `scope`, `intent`. The classifier value (see `## Change-Type Classifier` below). Default action of the review loop depends on this field: `style`, `clarity`, `correctness` auto-apply; `scope` and `intent` pause for the user.

### Divergence analysis

There is no field-name or allowed-value-set divergence between the three agent files and SKILL.md because the agent files define no schema. The schema is not duplicated — it is referenced by delegation. The only schema specification is in `skills/reviewer-protocol/SKILL.md:232`. The agent files contain no statements about `change_type`, its field name, or its allowed values that could diverge from SKILL.md.
