---
round: 01
artifact: goals
---

# Round 01 dispositions

## Findings inventory

- quality-claude: 4 (1 medium scope, 3 low)
- scope-claude: 3 (1 high scope, 1 medium scope, 1 low scope)
- quality-codex: 1 (medium scope)
- scope-codex: clean

Total: 8 findings. Verifier dispatch skipped this round; user reviewed findings directly.

## Per-finding dispositions

### Auto-batch applied (low-severity polish, user approved as batch)

| Finding | Disposition | Action |
|---|---|---|
| quality-claude R1-F01 (low/style) | Applied | Replaced "Risk Daniel surfaced explicitly:" → "Explicit risk:" in G4 |
| quality-claude R1-F02 (low/clarity) | Applied | Renamed G15→G16 title "F-23 wave nesting" → "Wave nesting in parallelization.md"; G16→G17 title "K3 CI" → "GitHub Actions CI for qrspi-plus" |
| quality-claude R1-F04 (low/clarity) | Applied | Rewrote Cross-Cutting Notes — added explicit bullet listing intentionally-standalone goals (G7, G15, G17 post-renumber) and noted G7 adjacency to runtime-prose hygiene cluster |

### Paused findings (per-finding user decisions)

| Finding | Disposition | Action / Rationale |
|---|---|---|
| scope-claude R1-F01 (high/scope) | Applied | Deleted Constraint bullet ("Porting QRSPI's main-chat orchestrator...") and G1 "What we know so far" bullet ("Budget tracking is explicitly out of scope..."). User intent originally added both; user overrode the original intent and accepted the DEFERS-clean version. |
| scope-claude R1-F02 (medium/scope) | Applied | Reframed G1's first "What we know so far" bullet from deliverable commitment to candidate framework shape Design should weigh. |
| scope-claude R1-F03 (low/scope) | Applied | Generalized G14's BATS helper bullets — dropped the specific file path and three function identifiers in favor of a single shape-level candidate bullet. |
| quality-claude R1-F03 (medium/scope) | Applied — option (a) split | Split old G5 into new G5 (Dispatcher tolerance research) and new G6 (Test-writer subagent investigation). Renumbered subsequent goals G6→G7 through G17→G18. Total goal count: 18 (was 17). |
| quality-codex R1-F01 (medium/scope) | Skipped | Reviewer recommended splitting v0.7 into multiple QRSPI runs. Contradicts user release strategy ("treat the chat list as the working order... parallelization > ranking realistically since they are all in the same phase of work"). 18 goals in one release is the chosen shape. |

## Post-fix structural state

- Goal count: 18 (was 17 + the G5 split)
- Type distribution: 13 known-fix + 5 exploratory (G1, G4, G5, G6, G11, G15 — wait, recount needed; one of G1/G4/G5/G6 may have changed type)
- All goals carry exactly the three required subsections.
- No top-level Out of Scope, Acceptance Criteria, or Success Criteria sections.
- Cross-Cutting Notes references match new goal IDs.

## Fix bug caught and repaired

The fix-subagent flagged that Edit 3 referenced "G6" as the owner of the empirical dispatcher matrix, but post-split G5 owns the matrix and G6 is the test-writer investigation. Repaired inline before commit: G1's first "What we know so far" bullet now correctly attributes the matrix to G5.
