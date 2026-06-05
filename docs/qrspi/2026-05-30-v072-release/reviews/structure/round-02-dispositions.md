# Round 02 dispositions

## Applied (kept findings)

1. **quality-claude.R2-F01** (correctness, 80) — Line 700 (G34 §Hook-Point Locations) cross-ref corrected: `design.md CD-4 §D1` → `design.md G34 §D1`.
2. **quality-claude.R2-F02 + quality-codex.R2-F01 part 2** (correctness, 75/85 — convergent pair) — Interface §11 audit-json schema corrected to match CD-4 §E lock: removed `round_dir` and `failed` fields, added `thresholds: { "style": 80, "clarity": 80, "correctness": 70 }`, renamed `halts[].reason` → `halts[].cause`. Field order now matches CD-4 §E.
3. **quality-claude.R2-F03** (correctness, 75) — Removed spurious `VF --> PR` cross-subgraph edge from Mermaid Architectural Diagram. No design authority established a direct script-to-script dependency from `verifier-fan-in.sh` to `round-prepare.sh`.
4. **quality-codex.R2-F01 part 1** (correctness, 85) — Interface §1 `kept-findings.txt` output description corrected from "newline-separated finding IDs" to "one absolute finding-file path per line" per CD-4 component D lock. Companion comment for audit JSON updated to reflect corrected schema shape.
5. **scope-claude.R2-F01** (scope, medium) — Interface §13 prose drift corrected: (a) removed env-var/detection-signal parentheticals `(COPILOT_CLI=1)` and `(no COPILOT_CLI, system-reminder framing present)` from platform directory — output mapping retained; (b) removed orchestrator conditional processing sentence ("For `shell-verdict` and `user-override-only`…") — audit file path and schema contract retained.
6. **scope-claude.R2-F02** (scope, medium) — Added Interfaces §14 (`scripts/dispatch-companion.sh`), §15 (`scripts/await-round.sh`), §16 (`scripts/third-party-finding-splitter.sh`) covering CLI shape, exit codes, and stdout/side-effect contracts derived from design.md CD-1 components #4–#6. Section Contracts intro updated to cross-reference all three as §14–§16.

## Dropped

None — all R2 findings KEEP per verifier scores or scope bypass.

## Notes

- Convergent cross-family evidence on Interface §11 schema drift (quality-claude R2-F02 + quality-codex R2-F01 part 2) provided strong signal; CD-4 §E verified against design.md lines 444–452 before editing.
- scope-codex R2 returned CLEAN sentinel — strong signal R1 scope fixes worked.
- Tagger emitted `line_range:`-tagged scope-set this round (R1 broadened due to missing `line_range`; R2 reviewers were explicitly required to include the field).
- New interfaces §14–§16 placed between §13 and `## Architectural Diagram` per authoring instruction. Section Contracts cross-reference list updated accordingly.
