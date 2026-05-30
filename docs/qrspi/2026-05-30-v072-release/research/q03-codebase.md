---
status: draft
question_ids: [3]
research_type: codebase
---

# Q3: Verifier filter rule definition, paraphrase count, and presence in implement/SKILL.md

## Summary

**TL;DR:** `skills/using-qrspi/SKILL.md` defines the verifier filter rule in six distinct locations/forms, with the canonical definition at line 388. The rule splits by `change_type` tier: style/clarity findings are dropped if score < 80 (kept if ≥ 80); correctness findings are dropped if score < 70 (kept if ≥ 70); scope/intent findings are always kept. `skills/implement/SKILL.md` does **not** contain the threshold values (≥ 80, ≥ 70) anywhere in the file — it references "verifier filtering" and "kept findings" but defers all numerical thresholds to `using-qrspi/SKILL.md`.

**Key findings:**
- The verifier filter rule is: `style`/`clarity` → drop if `score < 80`; `correctness` → drop if `score < 70`; `scope`/`intent` → always keep.
- The rationale for the lower correctness threshold is that hardening-relevant correctness gaps (silent failures, attack surface) tend to score in the 72–78 "real but low-severity" rubric band and would be lost at a uniform ≥ 80 threshold.
- The rule appears in **6 distinct paraphrases/forms** across `using-qrspi/SKILL.md` (narrative × 2, abbreviated inline, formal set-notation, bash pseudocode, bullet-per-tier list).
- `skills/implement/SKILL.md` contains **no occurrences** of the specific threshold values ≥ 80 or ≥ 70; it references the verifier mechanism generically and treats finding counts post-filter as opaque inputs.

**Surprises:** `implement/SKILL.md` is completely silent on the numerical thresholds despite owning the per-task verifier dispatch loop; the thresholds are fully centralized in `using-qrspi/SKILL.md`.

**Caveats:** Both files exceed 100 KB and were searched with targeted `grep` patterns rather than read in full; any occurrence of the thresholds embedded inside block-quoted or escaped text that the grep patterns did not match would be missed. The count of "distinct paraphrases" applies a qualitative judgement about whether two passages encode the same rule in different surface forms.

---

## Full findings

### Canonical definition of the verifier filter rule

**File:** `skills/using-qrspi/SKILL.md`, line 388 (within the `verifier_enabled` config-field description):

> "When `true`, the artifact-level Apply-fix protocol dispatches one `qrspi-finding-verifier` per finding-file in parallel and **filters findings by `change_type`: style/clarity at score ≥80** (high bar for nitpicks) **and correctness at score ≥70** (lower bar for hardening-relevant correctness gaps — silent failures, attack surface, and other correctness gaps that the rubric tends to score in the 72-78 "real but low-severity" band would be lost at the higher threshold)."

The rule has three tiers:

| `change_type` | Keep threshold | Drop condition |
|---|---|---|
| `style` | ≥ 80 | score < 80 |
| `clarity` | ≥ 80 | score < 80 |
| `correctness` | ≥ 70 | score < 70 |
| `scope` | always kept | (no score filter) |
| `intent` | always kept | (no score filter) |

`scope` and `intent` are out-of-scope for the score filter; they are caught as valid enum values in step 2's schema guard and always routed to `kept` (confirmed at line 987: "Out-of-enum `change_type` values are loud failures from step 2's schema guard").

---

### Six distinct paraphrases/restatements in `using-qrspi/SKILL.md`

**Paraphrase 1 — Narrative with full rationale (line 388)**  
Located in the `verifier_enabled` config-field inline description. Full prose with `change_type` label, both thresholds, and the 72–78 "real but low-severity" band justification for the lower correctness bar:

> "…filters findings by `change_type`: style/clarity at score ≥80 (high bar for nitpicks) and correctness at score ≥70 (lower bar for hardening-relevant correctness gaps — silent failures, attack surface, and other correctness gaps that the rubric tends to score in the 72-78 "real but low-severity" band would be lost at the higher threshold)."

---

**Paraphrase 2 — Abbreviated inline in cascade section (line 397)**  
Located in the auto-approve cascade description. The thresholds are given parenthetically to specify what "post-verifier-filter count" means:

> "…the count after the artifact-level Apply-fix protocol applies the verifier's by-change_type threshold — **≥80 for style/clarity, ≥70 for correctness**…"

No rationale prose, just the numerical mapping.

---

**Paraphrase 3 — Narrative in "Fields that affect pipeline behavior" section (line 661)**  
Located in the durable-fields behavioral-contract section. Same structure as paraphrase 1 but slightly different wording and without the "high bar for nitpicks" label:

> "…filters findings by `change_type`: style/clarity at score ≥80 and correctness at score ≥70 (lower correctness threshold so hardening-relevant correctness gaps in the 72-78 "real but low-severity" rubric band are not dropped)."

---

**Paraphrase 4 — Bash pseudocode in the step 7 assembly algorithm (lines 881–886)**  
Located inside an inline shell script that builds the verified-findings header. The thresholds appear as executable assignments:

```bash
# Threshold split: style/clarity require ≥80 (high bar for nitpicks);
# correctness requires ≥70 (lower bar for silent failures, attack
# surface, and hardening-relevant correctness gaps that the rubric
# tends to score in the 72-78 "real but low-severity" band).
threshold=80
[[ $ct == "correctness" ]] && threshold=70
if (( score < threshold )) && [[ $ct =~ ^(style|clarity|correctness)$ ]]; then
  dropped=$((dropped + 1))
fi
```

This is the only form in which the rule is expressed as executable logic rather than prose or formal notation.

---

**Paraphrase 5 — Formal set-notation in verified-findings header semantics (line 921)**  
Located in the `verified-findings` header-field semantics comment embedded in the step 7 assembly pseudocode output. Uses set-membership and comparison operators:

> "`dropped` = sidecars where `change_type ∈ style|clarity` AND `score < 80`, OR `change_type = correctness` AND `score < 70`"

---

**Paraphrase 6 — Per-change_type bullet rules in step 8 (lines 984–985)**  
Located in step 8 ("Filter and dispatch findings by `change_type`"). Expressed as two separate bullet points, one per tier group:

> - "`style`, `clarity`: filter at score ≥80 (verifier-enabled rounds with a sidecar score) or keep-all (verifier-disabled rounds, sidecar absent, OR sidecar has VERIFY_FAILED…)"
> - "`correctness`: filter at score ≥70 (lower bar than style/clarity — hardening-relevant correctness gaps like silent failures and attack surface tend to score in the 72-78 "real but low-severity" rubric band) or keep-all (verifier-disabled rounds, sidecar absent, OR sidecar has VERIFY_FAILED)."

---

### Summary: paraphrase count

Six distinct paraphrases/restatements of the verifier filter rule exist in `skills/using-qrspi/SKILL.md`:

| # | Location (line) | Form |
|---|---|---|
| 1 | 388 | Narrative prose with rationale — config-field inline description |
| 2 | 397 | Abbreviated inline parenthetical — cascade section |
| 3 | 661 | Narrative prose — "Fields that affect pipeline behavior" section |
| 4 | 881–886 | Bash pseudocode — step 7 assembly algorithm |
| 5 | 921 | Formal set-notation — verified-findings header semantics |
| 6 | 984–985 | Per-tier bullet list — step 8 filter-and-dispatch |

---

### Presence of threshold values in `skills/implement/SKILL.md`

`skills/implement/SKILL.md` **does not contain** the threshold values ≥ 80 or ≥ 70 anywhere in the file. A targeted grep for `≥80`, `≥70`, `score.*80`, `score.*70`, `72-78`, `threshold.*70`, `threshold.*80` returned zero matches.

The file does reference the verifier mechanism in multiple places:

- **Line 144**: Mentions the `verifier_enabled` backfill pattern and cross-references `using-qrspi/SKILL.md` as the source of that pattern.
- **Line 146**: Smoke check condition 1 — asserts `agents/qrspi-finding-verifier.md` exists.
- **Line 155**: Smoke check condition 3 — asserts `config.md` carries a parseable `verifier_enabled` field.
- **Line 828**: Step 4 of the Review Fix Loop — dispatches `qrspi-finding-verifier` per finding-file when `verifier_enabled: true`.
- **Lines 836–854**: HARD-GATE (step 5) — gates implementer-fix dispatch on sidecar presence, bypass marker, or phase-start snapshot; uses the phrase "kept findings" but defines what is kept only by reference to the sidecar, not by re-stating the score thresholds.
- **Line 1205**: Scope-tagger dispatch refers to "finding-files that survived any verifier filtering" without restating what that filtering entails.

In every case, `implement/SKILL.md` treats the verifier filter as a black box whose results are inputs to the HARD-GATE logic. The actual score thresholds (80 for style/clarity, 70 for correctness) are defined exclusively in `using-qrspi/SKILL.md` and are not duplicated in `implement/SKILL.md`.
