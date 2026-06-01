# Structure R11 — Verified findings (post fan-in)

**Round:** 11 (broaden vs R9 fix commit 612b5b5; R10 was CLEAN at same SHA)
**Diff:** 3255 lines (full restructure wave: per-file blocks + verbatim format contract + Cross-Cutting Schemas H2 + 6 prose-hardening commits)
**Scope-hint:** none (broaden)
**User scope authorization:** "we expanded past the current rules as a test of the future rules and I approve this scope" — per-file blocks + verbatim payload lifts + new H2 sections approved; defect-class findings inside the expanded shape still in-scope to flag.

## Reviewer fan-in summary

| Reviewer | Result | Notes |
|---|---|---|
| quality-claude | 5 findings (F01–F05) | high×2, medium×3 |
| scope-claude | 2 findings (F01–F02) | medium×1, low×1 |
| quality-codex | 4 findings (F01–F04) | high×3, medium×1 — hand-persisted chat-only return |
| scope-codex | 3 findings (F01–F03) | high×1, medium×2 — hand-persisted chat-only return |
| stitching-audit | 1 finding (F01) | must-fix; 9 of 10 checks PASS; check 10 (citation accuracy) fails broadly (34/49 blocks) |

**Total raw:** 15 findings.

## Convergence map (cross-reviewer / cross-family)

| Defect class | Findings | Convergence |
|---|---|---|
| round-prepare.sh exit-code contract drift | QC-F01 (high) + QCX-F04 (high) | **Cross-family** (Claude + Codex) — same defect, same fix surface |
| Section Contracts vs G31 wrapper-SKILL verbatim body conflict | QC-F02 (high) + QCX-F02 (high) | **Cross-family** — same defect, same fix surface |
| Prose Provenance Convention version-history narration | SC-F02 (low) + SCX-F03 (medium) | **Cross-family scope** — same paragraph flagged twice |
| Plan-territory drift (LOC estimates + test detail) | SC-F01 (medium) + SCX-F02 (medium) | **Cross-family scope** — overlapping surfaces (Slice 1.7 LOC + Slice 1.5 test assertions) |
| Citation drift (Source line ranges + cross-refs) | QC-F04, QC-F05, ST-F01 | **Cross-finding within Claude** — citation rot is a single defect class spanning 3 reviewers' surfaces |

## Verified findings (all KEEP — auto-KEEP on cross-family corroboration or concrete spot-check evidence)

| Finding | Severity | Type | Decision | Summary |
|---|---|---|---|---|
| QC-F01 + QCX-F04 | high | correctness | **KEEP** | `round-prepare.sh` exit 10 has three contradictory meanings (Slice 1.3 interface, Slice 1.4 interface, Slice 1.4 verbatim payload); only the verbatim payload matches design.md G4 authority. Cross-family convergence. |
| QC-F02 + QCX-F02 | high | correctness | **KEEP** | `## Section Contracts` table demands 4 H2 sections (`## Overview`, `## Detection`, `## Rules Application`, `## Process`) for `prompt-prose-{writer,reviewer}/SKILL.md` but the locked `Lift type: Full file body` verbatim payloads have only H1 + two `!cat` lines. Fix: Option A — rewrite Section Contracts rows to match the locked file bodies. |
| QCX-F01 | high | correctness | **KEEP** | Missing per-file block for `scripts/second-reviewer-available.sh` (design.md G27 D5 requires it; File Index lists surrounding scripts but not this one). |
| SCX-F01 | high | scope | **DROP** | Flags `scripts/round-prepare.sh` shell body (L977-1001) as Structure-territory overflow. **Verified:** the body is a verbatim lift from design.md §G4 (L1061-L1085) under the approved verbatim-payload expansion. Design.md owns whether to author shell pseudocode; structure.md lifts byte-identically. Boundary concern moot under user-approved expanded scope. |
| QC-F03 | medium | correctness | **KEEP** | Verbatim convention drift — G15/G18 lifts at L665-676, L683-702, L729-735, L743-751 preserve `> ` blockquote markers contrary to convention L19 ("no leading `> ` blockquote markers"). G34/G35 lifts correctly strip them. Fix: Option A — strip `> ` from the 4 G15/G18 payloads. |
| QC-F04 | medium | correctness | **KEEP** | Stale `§3`/`§4` cross-refs (6 sites) + stale `L<NNN>` Hook-Point Locations citations (~15-20 sites) after the §Interfaces→§Cross-Cutting Schemas renumber + the §Hook-Point Locations→§Hook-Point Cross-Slice Index move. |
| QC-F05 | medium | correctness | **KEEP** | `scripts/_resolve-lib.sh` host×vendor matrix verbatim block cites design.md L117-125 (4-col version) but payload is the 5-col version at L2192-L2200 (G27 D5). Marker phrase is synthetic (ungreppable). Fix: rewrite to `Source: design.md §G27 D5 (L2192-L2200)` + `Marker phrase: "D5 — CD-1 host×vendor matrix extension."` + `Lift type: Section body`. |
| QCX-F03 | medium | correctness | **KEEP** | Dispatch Manifest schema example uses `anthropic`/`openai` vendor IDs while `model_routing` / `_resolve-lib.sh` / `dispatch-companion.sh` use `claude`/`openai-codex`. Normalize to `claude`/`openai-codex`. |
| SC-F01 + SCX-F02 (partial) | medium | scope | **KEEP** | LOC estimates leak into 3 Slice-1.7 per-file blocks (`~6 LOC` at L2673; `~3-5 lines each` + `≤ 20 lines` at L2691; `~30 additional lines` at L2710). SCX-F02's adjacent test-assertion-detail concern in Slice 1.5 (`score: 0` / `HALLUCINATED:` fixtures at L594-601) is a separate sub-finding — also KEEP but assess separately. |
| SC-F02 + SCX-F03 | low/medium | scope | **KEEP** | `## Prose Provenance Convention` `**Why per-file blocks.**` paragraph at L15 narrates artifact's own revision history ("Earlier revisions split...") — Evergreen-Output Rule violation (CD-2, which this same release introduces). Fix: one-paragraph rewrite to present-tense framing. |
| ST-F01 | must-fix | correctness | **KEEP** | 34/49 verbatim blocks have stale `**Source:**` design.md line ranges after the design.md restructure. Citation rot — Plan/Implement consumers cannot verify lifts via cited ranges. Fix: re-audit + re-anchor each Source citation against current design.md content. |

## Decision summary

- **14 KEEP** (1 DROP — SCX-F01).
- **2 high cross-family convergences** (round-prepare contract + Section Contracts wrapper-SKILL conflict) — top priority.
- **1 high single-reviewer** (missing `second-reviewer-available.sh` per-file block) — additive content.
- **3 citation-class findings** (QC-F04, QC-F05, ST-F01) — broad mechanical sweeps; will dispatch a sub-agent.
- **5 small targeted fixes** (QC-F03 strip `> ` markers; SC-F01 strip 3 LOC estimates; SC-F02+SCX-F03 rewrite L15 paragraph; QCX-F03 normalize vendor IDs).

## Convergence trend

R10=0 (CLEAN) → R11=14 kept (broaden round forced by 6-commit prose-hardening + restructure wave).
The R10→R11 jump is the cost of the major restructure between rounds. Expected. R12 will narrow (HEAD~1 against R11 fix commit) and re-verify convergence.
