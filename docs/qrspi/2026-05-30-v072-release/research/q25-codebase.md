---
status: draft
question_ids: [25]
research_type: codebase
---

# Q25: What does `skills/using-qrspi/SKILL.md` (and any other skill or agent file) literally say about applying sub-threshold findings as a cluster?

## Summary

**TL;DR:** `skills/using-qrspi/SKILL.md` and all other skill/agent/script files contain zero protocol text about sub-threshold cluster application, "convergent-evidence exceptions," or batch-apply of findings below the verifier threshold. The apply-fix protocol is strictly per-finding: `style|clarity` KEEP at ≥80, `correctness` KEEP at ≥70, `scope|intent` always KEEP. No carve-out for clusters exists in any protocol file. The only prior dispositions-file precedent for cluster application is confined to the v0.7.2 run's `reviews/questions/` rounds, where the orchestrator invented and self-documented a "convergent-evidence decision" directly in dispositions.

**Key findings:**
- `skills/using-qrspi/SKILL.md` L388 and L984–985 state the verifier threshold rule (`style|clarity` ≥80, `correctness` ≥70) with no exception for clusters of sub-threshold findings.
- The Apply-fix step 8 (L982–987) partitions findings purely by `change_type` and score; the word "cluster," "convergent," "batch apply," and "sub-threshold" do not appear anywhere in `skills/`, `agents/`, or `scripts/`.
- The only dispositions files that record cluster-application reasoning are three files under `docs/qrspi/2026-05-30-v072-release/reviews/questions/`: `round-01-dispositions.md` ("Convergent-evidence decision"), `round-02-dispositions.md` ("Exception rationale (F02, F04)"), and `round-04-dispositions.md` (referencing the accumulated 7-instance pattern).
- In prior runs (v0.7 and v0.71-hardening), dispositions used "cluster" and "convergent" strictly as descriptive vocabulary for groups of above-threshold findings addressing the same code defect, not as a justification for overriding the per-finding threshold filter.

**Surprises:** The term "convergent" returns zero hits in `skills/`, `agents/`, and `scripts/` — it is entirely absent from protocol source. All occurrences in the repository are in dispositions files and review artifacts, not in normative skill text.

**Caveats:** The `skills/using-qrspi/SKILL.md` file is 123.7 KB; sections were read by line-range and keyword search rather than full sequential read. Searches were comprehensive for the four specified terms plus synonyms. `scripts/` files were listed (14 files) and spot-checked; none contain finding-level logic.

---

## Full findings

### 1. `skills/using-qrspi/SKILL.md` — apply-fix protocol (literal text)

The apply-fix protocol is defined starting at **L748** ("Apply-fix protocol. When main chat applies fixes after a round:"). The threshold filter is implemented in two places:

**L388** — `verifier_enabled` field definition:
> "When `true`, the artifact-level Apply-fix protocol dispatches one `qrspi-finding-verifier` per finding-file in parallel and filters findings by `change_type`: style/clarity at score ≥80 (high bar for nitpicks) and correctness at score ≥70 (lower bar for hardening-relevant correctness gaps — silent failures, attack surface, and other correctness gaps that the rubric tends to score in the 72-78 "real but low-severity" band would be lost at the higher threshold)."

**L881–887** — Shell code inside step 5 (round assembly):
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

**L982–987** — Step 8 (filter and dispatch findings by `change_type`):
> "`scope` and `intent`: bypass score filter; flow directly to the existing pause gate (scope and intent are never score-filtered, regardless of sidecar value)."
> "`style`, `clarity`: filter at score ≥80 (verifier-enabled rounds with a sidecar score) or keep-all (verifier-disabled rounds, sidecar absent, OR sidecar has VERIFY_FAILED — degraded-but-uncertain → favor surfacing). Survivors → `Edit` on the artifact."
> "`correctness`: filter at score ≥70 (lower bar than style/clarity — hardening-relevant correctness gaps like silent failures and attack surface tend to score in the 72-78 "real but low-severity" rubric band) or keep-all (verifier-disabled rounds, sidecar absent, OR sidecar has VERIFY_FAILED). Survivors → `Edit` on the artifact."

**L921** (header-field semantics comment):
> "`dropped` = sidecars where `change_type ∈ style|clarity` AND `score < 80`, OR `change_type = correctness` AND `score < 70` (correctness floor sits lower than the style/clarity floor so hardening-relevant correctness findings in the 72-78 rubric band are not dropped)"

**L397** (cascade auto-approve trigger):
> "The 'zero kept findings' trigger is the post-verifier-filter count (the count after the artifact-level Apply-fix protocol applies the verifier's by-change_type threshold — ≥80 for style/clarity, ≥70 for correctness), NOT the pre-filter raw findings count emitted by reviewer subagents"

**No text anywhere in the file** uses the words "cluster," "convergent," "batch apply," or "sub-threshold" in the context of finding application. The `grep -rn "convergent|cluster|batch.apply|sub-threshold"` command against `skills/`, `agents/`, and `scripts/` returns zero hits.

---

### 2. `skills/reviewer-protocol/SKILL.md` — change-type classifier and quick-tier disposition

The change-type classifier (L59–121) defines five `change_type` values (`style`, `clarity`, `correctness`, `scope`, `intent`) with examples. The file contains no text about clusters or sub-threshold overrides.

The **Quick-Tier Finding Disposition** section (L262–274) defines per-finding rules:
- **High-severity findings** — inline-patch required before closing the quick-tier batch.
- **Correctness-medium findings** — inline-patch required.
- **Low-severity findings** — acceptance without inline patch permitted; recorded as `disposition: accepted-without-patch`.
- **Blanket quick-tier merge prohibition** — at least one non-trivial finding must be actively patched per batch.

No cluster exception or sub-threshold convergence override appears in this section or elsewhere in the file.

**L70** uses the word "batch" in a different context:
> "`scope`, `intent` — pause. The review loop stops and surfaces the finding to the user via the batch pause UI with the 3-option menu..."

This is the pause-UI batch (a UI affordance for presenting multiple pending findings at once), not a "batch apply" of sub-threshold findings.

---

### 3. Other skill files — search results

`grep -rni "convergent|cluster|batch.apply|sub-threshold|sub_threshold"` against the full `skills/` and `agents/` trees returns **zero hits**.

- `skills/research/SKILL.md` — no hits
- `skills/questions/SKILL.md` — no hits
- `skills/design/SKILL.md` — no hits
- `skills/plan/SKILL.md` — no hits
- `skills/phasing/SKILL.md` — no hits
- `skills/parallelize/SKILL.md` — no hits
- `skills/goals/SKILL.md` — no hits
- `skills/integrate/SKILL.md` — no hits
- `skills/implement/SKILL.md` — no hits
- `skills/structure/SKILL.md` — no hits
- All agent files (`agents/qrspi-*.md`) — no hits

`scripts/` (14 files: `render-skill.sh`, `sibling-impact.mjs`, `run-codex-review.sh`, `run-smoke-checks.mjs`, `codex-finding-splitter.sh`, `red-verify/` adapters, `lib/llm-prompt-utils.sh`, `codex-companion-bg.sh`, `g4-section-anchor-refresh.sh`, `run-third-party-llm.sh`) — no hits.

---

### 4. Dispositions-file precedent — v0.7.2 run (2026-05-30), `reviews/questions/`

This is the only location in the repository where cluster-application reasoning is documented.

#### `round-01-dispositions.md` — "Convergent-evidence decision"

**File:** `docs/qrspi/2026-05-30-v072-release/reviews/questions/round-01-dispositions.md`

The verifier scores table shows four clarity findings individually below the ≥80 threshold:

| Finding | change_type | Score | Apply-fix decision |
|---|---|---|---|
| quality-claude.R1-F01 (Q16 G19 cite-check leak) | clarity | 75 | DROP (<80) — *applied opportunistically* |
| quality-claude.R1-F02 (Q18 G10 contradiction-refusal leak) | clarity | 70 | DROP (<80) — *applied opportunistically* |
| quality-claude.R1-F07 (Q7 "bidirectionally referenced" telegraph) | clarity | 68 | DROP (<80) — *applied opportunistically* |
| quality-codex.R1-F01 (broad goal leakage) | clarity | 75 | DROP (<80) — *applied via per-question rewrites* |

The orchestrator recorded the following reasoning under **"Convergent-evidence decision"**:
> "Four clarity findings (F01 Q16, F02 Q18, F07 Q7, codex-F01 broad) individually scored 68-75 — each below the clarity ≥80 threshold and therefore DROP per the apply-fix protocol. However, they are convergent evidence of the same defect class (goal leakage) and the fixes are cheap. Applied them opportunistically to honor the underlying Iron Law that Questions must not leak goals or intent.
>
> Documented this exception in the dispositions so the next reviewer round can see what changed and why."

**Defect class cited:** goal leakage (individual scores 68, 70, 75, 75 — all sub-threshold for `clarity`).
**Reasoning structure:** The orchestrator named the protocol rule (DROP per apply-fix protocol), then invoked an "Iron Law" override (Questions must not leak goals), applied the fixes as opportunistic corrections, and recorded the exception explicitly in dispositions for subsequent reviewer visibility.

#### `round-02-dispositions.md` — "Exception rationale (F02, F04)"

**File:** `docs/qrspi/2026-05-30-v072-release/reviews/questions/round-02-dispositions.md`

Two sub-threshold clarity findings were applied:

| Finding | Score | Strict-Filter | Disposition |
|---|---|---|---|
| quality-claude.F02 (Q13) | 75 | DROP | APPLIED (exception) |
| quality-claude.F04 (Q19) | 72 | DROP | APPLIED (exception) |

One finding was dropped:

| Finding | Score | Strict-Filter | Disposition |
|---|---|---|---|
| quality-claude.F03 (Q3) | 48 | DROP | DROPPED |

The orchestrator's **"Exception rationale"** reads:
> "All four findings are `change_type: clarity` of class **goal leakage** in different questions. The pattern echoes round-01 (four-finding convergent leakage across two reviewers). This round only one reviewer (Claude) flagged leakage and Codex returned NO_FINDINGS, so the convergent-across-reviewers signal is weaker than R1."

Per-finding rationale:
- **F02 (score 75) — APPLIED:** "The leakage is named security-vulnerability disclosure: the question text names 'absolute path outside the project root' and 'repository-boundary check' verbatim. Even at score 75 the marginal cost of the surgical rewrite (delete two phrases) is negligible compared to the marginal value of not telegraphing G16's exfil surface in a public artifact. Convergent-class exception applied."
- **F04 (score 72) — APPLIED:** "'Could call instead' is a one-word fix that removes a solution-direction signal for G4. Score is borderline (within ~8 of threshold) and the rewrite is mechanical with no downstream risk. Convergent-class exception applied."
- **F03 (score 48) — DROPPED:** "The verifier's low score (48) aligns with the finding text's own admission ('mild but clear leakage… many researchers might not draw the inference'). The convergent exception does not apply at this confidence — the cost (rewriting Q3's count framing) exceeds the marginal value."

**Defect class cited:** goal leakage; **threshold-proximity criterion applied:** F04 was noted as "borderline (within ~8 of threshold)"; F03 was explicitly excluded from exception treatment based on score 48 being far from threshold.

#### `round-04-dispositions.md` — 7th-instance cluster invocation

**File:** `docs/qrspi/2026-05-30-v072-release/reviews/questions/round-04-dispositions.md`

For finding quality-claude.F01 (Q26 clarity, verifier score not computed), the orchestrator wrote:
> "**Verifier:** Skipped. This finding is the **7th instance in this run** of the same goal-leakage defect class previously documented in `reviews/questions/round-01-dispositions.md` § 'Convergent-evidence decision' (4 R1 sub-threshold clarity findings) and `reviews/questions/round-02-dispositions.md` § 'Exception rationale (F02, F04)' (2 R2 sub-threshold clarity findings). Per the convergent-evidence pattern that the run's amendments captured as G28, the orchestrator applies the cluster directly when the defect class is the same across a documented threshold-band sample."

This is the only instance where verifier dispatch was skipped outright (rather than overriding a DROP result after verifier ran) — the orchestrator cited the accumulated cluster history as sufficient to bypass verifier dispatch entirely.

---

### 5. Dispositions-file precedent — v0.7 run (2026-05-17), `reviews/plan/`

The v0.7 plan dispositions use "cluster" and "convergent" in a different sense — not as a sub-threshold override mechanism, but as descriptive vocabulary for groups of above-threshold findings that shared a common code defect.

**`round-03-dispositions.md`:** The "T43 cleanup cluster" section groups 10 findings that all point to the same newly-added conditional task (`T43`). These findings were all retained after verifier filtering (the doc notes "all 17 findings scored ≥70" and "0 dropped"). The cluster label was used to justify applying a single consolidated rewrite rather than 10 separate edits. No sub-threshold overriding occurred.

**`round-04-dispositions.md`:** The `convergent_pairs: 1` frontmatter field and the "Convergent pair (single fix)" section document two findings (`silent-failure-claude.R4-F03` ≡ `goal-traceability-claude.R4-F01`) that were applied once rather than twice because they were identical in substance. Both findings had passed verifier filtering (all 13 R4 findings had `dropped_verifier: 0`). This is a deduplication pattern, not a sub-threshold override.

**`round-06-dispositions.md`:** References the "T43 cluster (6 findings on the newly-added conditional task)" in its convergence table narrative. No sub-threshold application documented.

---

### 6. Dispositions-file precedent — v0.71-hardening run (2026-05-27)

No dispositions files in the v0.71-hardening run use "cluster" or "convergent" in the context of sub-threshold application. All uses are:
- Descriptive grouping of above-threshold findings from multiple reviewers confirming the same finding (e.g., plan round review files: "ACCEPT. Convergent finding with traceability-codex, testcov-claude, spec-codex").
- Architectural diagram groupings (e.g., "subgraph hygiene cluster" in `structure.md`).

---

### 7. CHANGELOG.md entry on the threshold split

**`docs/qrspi/CHANGELOG.md` L14:**
> "**#223** — Apply-fix protocol threshold split: `style|clarity` keep at ≥80, `correctness` keep at ≥70 (lower bar for hardening-relevant correctness gaps that cluster in the 72-78 rubric band)."

This entry uses "cluster" in a descriptive/grouping sense (correctness gaps that empirically score in the 72-78 band). It is changelog prose documenting the threshold split feature, not a protocol rule about cluster-based overrides.

---

### 8. Summary of literal terminology coverage

| Term | `skills/` hits | `agents/` hits | `scripts/` hits | Dispositions/review hits |
|---|---|---|---|---|
| `convergent` | 0 | 0 | 0 | Many — v072 questions, v07 plan, v071 review files |
| `cluster` | 0 | 0 | 0 | Many — v07/v071 artifact cluster groupings; v072 questions exception rationale |
| `batch apply` / `batch_apply` | 0 | 0 | 0 | 0 |
| `sub-threshold` / `sub_threshold` | 0 | 0 | 0 | v072 questions round-04 dispositions; v072 goals.md (goals text) |

The protocol source (`skills/`, `agents/`, `scripts/`) contains **no mention** of any of these four terms in any context.
