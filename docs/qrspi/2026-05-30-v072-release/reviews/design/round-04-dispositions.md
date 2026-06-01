---
step: design
round: 4
verifier_enabled: true
findings_total: 5
fixed: 2 (one fix addresses 2 convergent findings)
dropped_by_verifier: 1
user_override: 1
sub_threshold_observations: 1
---

# Design Round 04 — Dispositions

## Review summary

R4 dispatched **4 reviewers in parallel** for the first time this run — Claude side (quality + scope) AND Codex side (quality + scope) via `model: gpt-5.3-codex` Task override. This dogfoods the CD-1 PROMPT_FILE amendment (#283 closed in R2) which confirmed Codex availability in Copilot CLI. **Verifier-enabled this round** (5 findings, all sidecars written, all scored cleanly). All artifacts persisted to disk per protocol (Codex findings hand-persisted by orchestrator due to known constraint: OpenAI-family Task dispatches return chat-only even with `tools: Read, Write` in agent frontmatter — filed earlier as part of #283's PoC; not re-filed for R4).

## Verifier scores (post-rubric)

| Finding | Score | Threshold | Disposition |
|---|---:|---:|---|
| quality-claude R4-F01 (I.7 writer contradiction, correctness) | 82 | ≥70 | KEPT → FIXED |
| quality-claude R4-F02 (G28 stale line numbers, correctness) | 75 | ≥70 | KEPT → FIXED |
| quality-codex R4-F01 (I.7 writer ownership, correctness) | 72 | ≥70 | KEPT → FIXED (convergent with qc-F01, same fix) |
| quality-codex R4-F02 (rescue-off accounting, correctness) | **68** | ≥70 | **DROPPED by verifier** (recorded under Sub-Threshold Observations) |
| scope-codex R4-F01 (Plain-language sections, scope) | 25 | (bypass) | KEPT (bypass) → user-override per PI-HKP-005 |

## Cross-family convergence (the win of this round)

**quality-claude R4-F01 + quality-codex R4-F01** independently flagged the same I.7 writer-ownership contradiction from different angles. This is exactly the signal we ran the cross-family review to obtain — Claude approached it from "three sections describe incompatible writers"; Codex approached it from "for llm-context, evidence must come from orchestrator, but script is named writer." Both correct; convergent. The single fix below addresses both findings.

## Fixed in-artifact (2 fixes, 3 findings)

### qc R4-F01 + qcx R4-F01 (CONVERGENT, both correctness, scores 82 + 72) — I.7 writer-ownership contradiction → FIXED

**The bug:** R3's I.7 surgery left three sections describing incompatible writers for `<round-dir>/.interaction-mode-audit.json`:
- L628 Contract: `scripts/detect-interaction-mode.sh` is stdout-only.
- L671 Audit-log entry: "Every round-start invocation of the detection script writes" → reads as script-write.
- L675 Caching: orchestrator caches `{platform, detection_type, verdict, evidence}` and "the orchestrator's cached evidence is what gets cited in the audit log."

For `DETECTION_TYPE=llm-context`, evidence necessarily comes from the orchestrator's own context inspection — the script cannot see LLM context. So the script CAN'T be the writer for that branch. But for `shell-verdict` and `user-override-only`, the script already knows VERDICT and EVIDENCE. The audit file would split across writers depending on branch — exactly the kind of ownership ambiguity CD-4 is locked to prevent.

**The fix (orchestrator as exclusive writer):**
- L653 LLM-context instruction: orchestrator's action rewritten to "record the specific context signal it observed (or its absence) for citation in the audit log entry written by the orchestrator per the audit-log rule below." Removed the "MUST cite" passive language that contributed to the ambiguity.
- L671 Audit-log entry: rewritten as "After every round-start detection cycle (script invocation + orchestrator context inspection when required), the **orchestrator** writes ... The orchestrator is the exclusive writer per the single-writer principle locked across CD-4: the script's contract is stdout-only (it never opens a file), and for `DETECTION_TYPE=llm-context` the `evidence` field necessarily comes from the orchestrator's own context observation, which the script cannot see." Added explicit per-detection-type field-provenance subsection (shell-verdict / llm-context / user-override-only branches each name which fields the orchestrator copies vs derives).
- L681 Caching: rewritten to make orchestrator's full detection-cycle responsibility explicit: "completes the detection cycle (parsing script stdout, executing the context check for llm-context, applying the override chain when needed), caches the resolved tuple for the round, writes the tuple to `<round-dir>/.interaction-mode-audit.json` per the audit-log rule above, and reuses the cached tuple for every subsequent consumer check."

Single-writer principle now preserved across all three branches; Component E (`.verifier-fan-in-audit.json`) and I.7's `.interaction-mode-audit.json` are clean per-file single-writer with explicit different-writer/different-timing separation.

### qc R4-F02 (correctness, score 75) — G28 stale line numbers → FIXED

**The bug:** R3's letter rename (qc R3-F04) substituted letter tokens (H.5 → I.5, §H → §I) in G28's cross-references but didn't refresh the accompanying line numbers. 3 sites in G28 (D4 at L2265, cross-cutting note at L2294, References block at L2311) point at wrong lines:
- "L532, I.5" → actual I.5 is at L587
- "L642 amendment seam" → actual amendment seam is at L713
- "L380-444 verifier-fan-in pipeline" → actual CD-4 spans L352-712
- "L400 context-cost iron rule" → actual context-cost rule is at L421
- "L417 threshold rule" → actual threshold rule is at L438
- "G19 (L1708-1767)" → actual G19 is L1793-1853
- "G7 (L1201-1209)" → actual G7 is L1286-1295

**The fix:** Surgical line-number refresh across all 3 sites. External skill file refs (`skills/using-qrspi/SKILL.md L388` + `L989`; `skills/reviewer-protocol/SKILL.md L264-270`) reduced to section descriptions instead of line numbers — those files drift independently of this artifact and citing line numbers would re-stale on every installed-plugin update. New References block uses "(apply-fix protocol threshold prose + dispositions writer prose — line numbers omitted as the installed plugin file drifts independently of this artifact)" pattern for external refs.

## Dropped by verifier (1)

### qcx R4-F02 (correctness, score 68) — rescue-off accounting gap → DROPPED + recorded under Sub-Threshold Observations

**The finding:** Under `orchestrator_rescue: false`, the behavior matrix says every halt escalates immediately, but `.orchestrator-fixes.json` is defined as rescue-tier event logging. So under rescue=off, no rescue events fire and the file stays empty. The dispositions "Rescue tier breakdown" sourced from this file would report zero E1-E4 escalations even when escalations actually happened — non-repeatable audit trail.

**The verifier's call (score 68, below 70 correctness threshold):** Below threshold. Reading the verifier's rubric judgment: the breakdown's E1-E4 counts are implicitly rescue-on context (when rescue is off, the breakdown is moot — escalations equal halt-count trivially). The finding identifies a real audit gap but it's edge-case and the workaround (read halt-events directly) is obvious. This is exactly the "real but very low severity" 72-78 band the protocol's 70 correctness floor was set to NOT drop... but at 68 it falls just below.

**Why dogfooding this matters:** Per G28 D3 (our own newly-locked iron rule), sub-threshold findings MUST NOT be kept via orchestrator override. The script (here, the verifier) owns the kept-set; orchestrator does NOT override. The finding is real but stays dropped. Recorded below per G28 D2 (optional Sub-Threshold Observations section) so v0.7.3 calibration can see the pattern.

## Sub-Threshold Observations

(Per G28 D2 — informational; consumed by no v0.7.2 script; surfaces signal for v0.7.3 calibration.)

```yaml
observations:
  - summary: "Rescue-off audit accounting gap — .orchestrator-fixes.json stays empty when rescue=false, but the dispositions breakdown sources from it."
    findings:
      - path: reviews/design/round-04/quality-codex.finding-F02.md
        defect_class: implicit-disposition-context
        score: 68
        threshold: 70
        change_type: correctness
    notes: |
      Real but edge-case. Mitigations exist (E1-E4 count derivable from halt-events; breakdown implicitly rescue-on context).
      Below the 70 correctness threshold; dropped per G28 D3 iron rule.
      Worth re-examining if v0.7.3 surfaces additional findings against the same audit surface.
```

## User override per PI-HKP-005 (1)

### scx R4-F01 (scope, score 25, bypasses filter) — "Plain-language problem" sections in goal blocks → USER OVERRIDE

**Cited sites:** G15 (L1528), G18 (L1713), G19 (L1795), and "similar per-goal sections."

**Rationale:** The G1 per-goal block template explicitly carries "Plain-language problem" as a documented section. This pattern aids human reviewers walking the artifact (which is exactly what dfrysinger spent the bulk of this run doing across 33 goals). R1's scope-claude flagged the same pattern and the operator dispositioned it as kept-because-G1-template; R4's scope-codex independently surfaced the same pattern. The scope-claude side of R4 explicitly noted this in its brief return: "per-goal 'Plain-language problem' blocks present but operator-blessed under R1 PI-HKP-005 disposition stance."

**Disposition:** Operator override at human gate per PI-HKP-005 (the recurring G34-blessed scope false-positive pattern; goals.md G34 amends scope-reviewer OWNS/DEFERS to bless this content type, and ships in v0.7.2 itself). No artifact change.

## Round-status

- 5 findings total.
- 2 fixes applied (one fix closed both convergent quality findings).
- 1 finding dropped by verifier (sub-threshold).
- 1 finding user-overridden (PI-HKP-005 recurring scope false-positive; G34-blessed).
- 0 findings unresolved.
- Net artifact change: +6 lines (3021 → 3027) from I.7 audit-log per-detection-type provenance expansion.

## Process notes (self-host monitoring)

- **First R round with full ritual exercised end-to-end on design.md:** Claude × 2 + Codex × 2 reviewers + verifier × 5 + sidecars + round-NN-verified.md + dispositions. R1 + R2 ran Claude+Codex but no verifier; R3 ran Claude-only no verifier. R4 is the only round that has touched every component of the v0.7.2 architecture against the v0.7.2 artifact.
- **Codex dispatch via Copilot CLI `model: gpt-5.3-codex` Task override worked cleanly** for both quality and scope reviewers — confirms #283's CD-1 PROMPT_FILE amendment is sufficient for this transport. No new issues filed.
- **Codex-Write-to-disk constraint persists:** OpenAI-family Task dispatches still return chat-only even with `tools: Read, Write` in agent frontmatter. Orchestrator hand-persisted Codex findings to disk per the established workaround. Not a new issue — already known and stored in user memory.
- **Cross-family convergence on a real bug** (qc R4-F01 + qcx R4-F01 both naming the I.7 writer contradiction from different angles) — exactly the asymmetric upside the user predicted when authorizing R4.
- **G28 D2 (Sub-Threshold Observations section) dogfooded for real** for the first time in this run, against a real dropped finding. Section shape worked cleanly; no schema friction surfaced.
