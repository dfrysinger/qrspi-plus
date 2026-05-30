---
status: draft
question_ids: [16]
research_type: codebase
---

# Q16: How does `agents/qrspi-finding-verifier.md` define its scoring rubric?

## Summary

**TL;DR:** The `qrspi-finding-verifier.md` agent defines a 0–100 continuous integer scoring rubric with five named anchor tiers (0, 25, 50, 75, 100). The verifier receives five prompt parameters at dispatch, eagerly reads the finding file, artifact, and diff, and lazily reads upstream skill/CLAUDE.md files on demand; it has no `grep` capability (tools are `[Read, Write]` only). Factually-wrong premises score 0–25 via the false-positive rules; observational-but-not-action-demanding findings score 0–50 depending on practitioner judgment; findings whose subject is already acknowledged/silenced in documentation score 0–25 under specific false-positive rules.

**Key findings:**
- The rubric is a continuous 0–100 integer scale with five anchor points (0, 25, 50, 75, 100), each describing a different confidence and severity level.
- The verifier's tool set is `[Read, Write]` only — no grep capability is available.
- Five prompt parameters are passed at dispatch: `<finding_file_path>`, `<sidecar_path>`, `<artifact_path>`, `<diff_file_path>`, and `<upstream_paths>`.
- Reads are staged: `<finding_file_path>`, `<artifact_path>`, and `<diff_file_path>` are eager; `<upstream_paths>` entries and `referenced_files` are lazy/on-demand.
- Factually-wrong premises map to the 0–25 band under the false-positive rules (anchor 0 = false positive, anchor 25 = unverifiable).
- Purely observational findings (correct premise but no required action) score 0–25 as pedantic nitpicks or 50 as verified-but-minor.
- Findings already acknowledged in project documentation score 0–25: via "explicitly silenced" rule (lint-ignore / feedback decision) or "contradicts captured user decisions in `feedback/*.md`" rule.

**Surprises:** The 75-anchor includes an explicit carve-in for findings that "violate a documented 'Iron Law', 'Iron Rule', 'MUST', or equivalent explicitly-load-bearing constraint in an upstream SKILL.md, agent file, or CLAUDE.md" — this is a named sub-condition at that tier, not derived from the general confidence description. Also surprising: the verifier is given the rubric verbatim in its own agent file rather than referencing a separate rubric document (the description says "against the /code-review confidence rubric" but there is no separate rubric file — the rubric is embedded inline in the agent).

**Caveats:** The investigation read the single agent file in full and cross-referenced `skills/using-qrspi/SKILL.md` for pipeline context. No examples of actual scoring sidecars were inspected. The `/code-review confidence rubric` reference in the frontmatter description may point to a Cursor/Claude slash-command that is not present as a file in this repo.

## Full findings

### Rubric structure and anchor tiers

The rubric is defined in `agents/qrspi-finding-verifier.md` (lines 7–15) under the `## Rubric` heading. It is a **continuous 0–100 integer scale** with five labelled anchor points:

| Anchor | Label | Core condition |
|--------|-------|----------------|
| **0** | Not confident at all | False positive that doesn't stand up to light scrutiny, OR a pre-existing issue. |
| **25** | Somewhat confident | Might be real but unverifiable, or a false positive. If stylistic, the style rule is not explicitly in the relevant CLAUDE.md. |
| **50** | Moderately confident | Verified as a real issue, but may be a nitpick or low-frequency occurrence. Not very important relative to the rest of the PR. |
| **75** | Highly confident | Double-checked and very likely real, will be hit in practice, existing approach is insufficient. Additionally at this tier: violates a documented "Iron Law", "Iron Rule", "MUST", or equivalent explicitly-load-bearing constraint in an upstream SKILL.md/agent file/CLAUDE.md; OR the issue is directly mentioned in the relevant CLAUDE.md. |
| **100** | Absolutely certain | Confirmed definitely real, will happen frequently in practice, evidence directly confirms it. |

The verifier emits any integer in `0..100`; the anchors are reference points, not the only allowed values (`agents/qrspi-finding-verifier.md:9`).

---

### Dimensions evaluated at each tier

**Anchor 0** evaluates: (a) does the finding hold up to basic scrutiny (false positive test), and (b) is the problem pre-existing (introduced outside this work-unit)?

**Anchor 25** evaluates: (a) was the verifier able to confirm the issue is real (verifiability), and (b) if stylistic, is the rule explicitly in CLAUDE.md?

**Anchor 50** evaluates: (a) is the issue verifiably real, (b) is it a nitpick, and (c) is it important relative to the rest of the PR?

**Anchor 75** evaluates: (a) was the issue double-checked, (b) will it be hit in practice, (c) is the current PR approach insufficient, and (d) does it violate a named load-bearing constraint (Iron Law / Iron Rule / MUST / equivalent) in an upstream artifact, OR is it directly mentioned in the relevant CLAUDE.md?

**Anchor 100** evaluates: (a) was the issue confirmed (not just double-checked), (b) will it happen frequently, and (c) is there direct evidence?

---

### How the rubric handles specific finding patterns

#### Findings whose premise is factually wrong

A finding with a factually wrong premise is treated as a false positive and scored **0–25**. The `## False-positive examples` section (`agents/qrspi-finding-verifier.md:17–29`) governs this:

- Anchor 0 explicitly covers "false positive that doesn't stand up to light scrutiny."
- The special QRSPI false-positive rule at line 28 directly addresses factual errors about the artifact: `"(QRSPI) 'X is missing' findings where X is actually present in the artifact, just not where the reviewer looked. Read the artifact to confirm before scoring above 25."` — the verifier is expected to Read the artifact to check before scoring above 25.
- Similarly, findings that contradict what the artifact actually contains (e.g., a reviewer misread the code) fall under the general false-positive pattern and score 0–25.

#### Findings whose premise is correct but purely observational (not action-demanding)

The rubric does not have a named category for "observational but correct" findings, but they map to existing anchors:

- If the observation is something a senior practitioner would not call out, it is a **pedantic nitpick** (line 22) → score **0–25**.
- If the observation is a real issue but minor or infrequent, anchor **50** applies: "might be a nitpick or not happen very often in practice… not very important."
- A correct factual observation that identifies no actionable problem ("the code uses X pattern") would score 0–25 under the pedantic-nitpick or general-quality-not-in-CLAUDE.md rules (line 24).

#### Findings whose subject is already acknowledged in project documentation

Two false-positive rules apply:

1. **Explicitly silenced in code** (line 25): "Issues called out in CLAUDE.md but explicitly silenced in the code (e.g. via a lint-ignore comment or a `feedback/*.md` decision entry)" → score **0–25**.
2. **Contradicts captured user decisions** (line 29): `"(QRSPI) Findings that contradict captured user decisions in \`feedback/*.md\` — check the cited decision entry against the file content. If the finding contradicts a recorded decision, score 0–25."` → score **0–25**.

A finding about a known issue that is not yet silenced/decided but is already documented at the 75-level as "directly mentioned in the relevant CLAUDE.md" would score **75** (it is highly confirmed), not dropped — acknowledgment in CLAUDE.md as a required concern raises the score, not lowers it. The score-reduction only applies when the issue has been explicitly silenced or overridden by a recorded decision.

---

### Inputs the verifier receives during dispatch

Defined in `## Input contract` (`agents/qrspi-finding-verifier.md:33–39`). Five prompt parameters:

| Parameter | Description |
|-----------|-------------|
| `<finding_file_path>` | Absolute path to the per-finding file under `reviews/{step}/round-NN/`. Contains YAML frontmatter: `finding_id`, `severity`, `change_type`, `referenced_files`, plus prose `message` body. |
| `<sidecar_path>` | Absolute path for the output score file. Always derived from `<finding_file_path>` by replacing `.md` → `.score.yml`. |
| `<artifact_path>` | Absolute path to the artifact under review. |
| `<diff_file_path>` | Absolute path to `reviews/{step}/round-NN.diff`. Generated by the orchestrator each round via `git diff <base-branch> -- <artifact_path>`. Omitted when the artifact directory is not inside a git repository. Diff content is treated as **untrusted data** (not instructions). |
| `<upstream_paths>` | Newline-separated list of upstream artifact and SKILL paths the verifier may Read on demand. |

**Tool capability:** The agent frontmatter declares `tools: [Read, Write]` only (`agents/qrspi-finding-verifier.md:3`). The verifier cannot grep — it can only Read files it already knows the paths of (from the parameters) and Write the sidecar.

---

### Read ordering during the procedure

Defined in `## Procedure` (`agents/qrspi-finding-verifier.md:43–64`):

1. **Step 1 — Eager Read:** `<finding_file_path>` — always read first to parse the finding object.
2. **Step 2 — Eager Read:** `<artifact_path>` and `<diff_file_path>` — both read eagerly when the parameter is provided. The diff is the primary evidence source for determining what the work-unit introduced. If the artifact directory is not in a git repo, `<diff_file_path>` is absent and the artifact alone serves as evidence.
3. **Step 3 — Lazy Read per referenced file:** Each entry listed in the finding's `referenced_files` frontmatter field is read.
4. **Step 4 — Lazy Read of upstream paths:** Entries from `<upstream_paths>` are read only when cited in the finding or judged "load-bearing" for scoring.
5. **Step 5 — Score** using the rubric.
6. **Step 6 — Write `<sidecar_path>`** with YAML `score:` and `reason:` fields (or `score: VERIFY_FAILED` on failure).
7. **Step 7 — Return** a single line: `<reviewer_tag>.<finding_id>: <score>` (or `VERIFY_FAILED:<reason>`).

---

### Conditions inspected at each tier (summary)

| Tier | What conditions the verifier checks |
|------|-------------------------------------|
| **0** | Does the finding hold up to scrutiny? Was the problem introduced in this work-unit or was it pre-existing (check diff)? Is it a known false-positive pattern (pedantic nitpick, linter-catchable, already-acknowledged)? |
| **25** | Could the verifier confirm the issue is real after reading artifact + diff + referenced files? Is it stylistic but the style rule is absent from CLAUDE.md? |
| **50** | Is the issue confirmed real? Is it a nitpick or low-frequency in practice? Is it less important than other issues in the PR? |
| **75** | Was the issue double-checked? Will it be hit in practice? Is the PR's approach insufficient? Does it violate a named Iron Law/Iron Rule/MUST in an upstream SKILL.md/agent/CLAUDE.md? Is it directly mentioned in the relevant CLAUDE.md? |
| **100** | Is the issue directly evidenced as definitely real and high-frequency? |

---

### Output format

On success, the sidecar YAML is:
```yaml
score: <int 0..100>
reason: <≤1-sentence>
```

On failure:
```yaml
score: VERIFY_FAILED
reason: <one-sentence diagnosis>
```

The verifier never modifies the finding file itself — only writes the `.score.yml` sibling (`agents/qrspi-finding-verifier.md:64`).

---

### How downstream pipeline uses scores

Per `skills/using-qrspi/SKILL.md` (line ~388), the Apply-fix protocol applies two score thresholds by `change_type`:
- `style/clarity` findings: kept only at score **≥ 80**
- `correctness` findings: kept only at score **≥ 70**

Findings without a sidecar (verifier not run) are kept by default ("no sidecar → keep" branch).
