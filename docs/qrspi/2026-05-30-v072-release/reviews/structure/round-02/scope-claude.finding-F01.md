---
finding_id: R2-F01
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
artifact: structure
line_range: [370, 391]
---

## Boundary drift — Interface §13 embeds orchestrator implementation behavior and internal detection signals

**What the artifact does.**  
Interface §13 ("Interaction-mode detector", lines 370–391) correctly opens with a bash comment block that declares the script's exit codes and stdout output shapes — that is within Structure OWNS ("script entry points, CLI argument shapes"). But two items in the post-code prose cross into DEFERS territory:

**Item A — Detection signal parentheticals (line 388):**
> Locked platform directory (verified at design time as of 2026-05-31): Copilot CLI **(COPILOT_CLI=1)** returns `llm-context`; Claude Code **(no COPILOT_CLI, system-reminder framing present)** returns `llm-context`; unknown host returns `user-override-only`.

The parenthetical fragments `(COPILOT_CLI=1)` and `(no COPILOT_CLI, system-reminder framing present)` specify the environment-variable signals and framing heuristics that the script uses internally to identify each platform. These are implementation details of the detection algorithm — not the interface outputs. The interface contract is "Copilot CLI → `DETECTION_TYPE=llm-context`"; *how* the script identifies Copilot CLI (`COPILOT_CLI=1` env var inspection) belongs in Plan/Implement.

**Item B — Orchestrator behavior prose (line 390):**
> Audit file: after each detection cycle, the orchestrator (exclusive writer) writes `<round-dir>/.interaction-mode-audit.json` with shape `{platform, detection_type, verdict, evidence}`. **For `shell-verdict` and `user-override-only` the orchestrator copies fields directly from script stdout; for `llm-context` the orchestrator derives verdict and evidence from its own context inspection.** Separate file from `.verifier-fan-in-audit.json` (different writer, different timing — round-start vs round-end).

The bolded sentence specifies how the orchestrator must process the script's output differently for each `DETECTION_TYPE` — a conditional processing algorithm. This is orchestrator implementation behavior, not the script's interface contract. The audit file path and schema (`{platform, detection_type, verdict, evidence}`) are OWNS (comparable to Interface §11's audit JSON schema). The orchestrator conditional logic — "copies fields directly" vs. "derives verdict and evidence from its own context inspection" — is implementation and belongs in Plan/Implement.

**Analogous R1 fix for reference.**  
R1 scope-claude-F01 flagged Interface §12 for pre-authoring the complete wording of `skills/_shared/verifier-filter-rule.md` and required collapsing to a placeholder. The same boundary applies here: Structure should declare the audit file path and schema but not author the orchestrator's per-DETECTION_TYPE processing logic.

**What Structure should do instead.**  

For Item A, strip the parenthetical detection signals and retain only the output mapping:
> Locked platform directory (verified at design time): Copilot CLI returns `DETECTION_TYPE=llm-context`; Claude Code returns `DETECTION_TYPE=llm-context`; unknown host returns `DETECTION_TYPE=user-override-only`. See design.md CD-4 §I.7 for full platform table.

For Item B, retain the audit file path/schema contract and drop the orchestrator logic sentence:
> Audit file: `<round-dir>/.interaction-mode-audit.json` with shape `{platform, detection_type, verdict, evidence}`. Separate from `.verifier-fan-in-audit.json` (different writer, different timing).

The orchestrator's per-DETECTION_TYPE field-derivation behavior belongs in the Plan/Implement authoring pass for `skills/using-qrspi/SKILL.md` (or whichever skill owns the audit-write procedure).
