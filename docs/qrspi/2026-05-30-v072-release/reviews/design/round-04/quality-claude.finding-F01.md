---
severity: high
change_type: correctness
artifact: design
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md:628-630
  - docs/qrspi/2026-05-30-v072-release/design.md:645-653
  - docs/qrspi/2026-05-30-v072-release/design.md:671
  - docs/qrspi/2026-05-30-v072-release/design.md:675
---

# `.interaction-mode-audit.json` writer is internally contradictory for the `llm-context` detection type

## Summary

CD-4 §I.7's `.interaction-mode-audit.json` specification — rewritten in R3 per the qc R3-F02 fix that moved the audit destination from `<run-dir>/.verifier-fan-in-audit.json` to `<round-dir>/.interaction-mode-audit.json` with a flattened schema — carries three mutually inconsistent statements about who writes the file. The contradiction is load-bearing because the `llm-context` branch (covering both supported v0.7.2 hosts: Copilot CLI and Claude Code) cannot be implemented under any of the three contradictory readings.

## The three incompatible specifications

**1. The Contract section (L628–630)** locks the script's output channel to stdout only:

> Outputs a small structured block on stdout (one key per line, `KEY=value` shape) describing how the orchestrator should determine auto vs. interactive for the active host. Exit code 0 on successful detection (including the safe-default branch); nonzero only on internal script error.

No file-write is in the script's contract.

**2. The Audit-log entry section (L671)** attributes the JSON file write to the script, and the separation note explicitly names the script as the single writer:

> Every round-start invocation of the detection script writes `<round-dir>/.interaction-mode-audit.json` with shape `{platform, detection_type, verdict, evidence}` …
>
> Separate file from Component E's `.verifier-fan-in-audit.json` (different writer — `scripts/detect-interaction-mode.sh` vs `scripts/verifier-fan-in.sh`; different timing — round-start vs round-end; **single-owner property preserved per file**).

**3. The LLM-context branch description (L645–653) and the Caching section (L675)** locate verdict + evidence derivation in the orchestrator, not the script:

> Orchestrator action: read `INSTRUCTION`, execute the check against its own context, derive `auto` or `interactive`. The orchestrator MUST cite (in the audit log entry below) the specific context signal it observed (or its absence) so the decision is traceable post-hoc.

> Orchestrator invokes the script once per round-start, caches `{platform, detection_type, verdict, evidence}` for the round, and reuses it for every subsequent consumer check in that round. … The orchestrator's cached evidence is what gets cited in the audit log.

## Why this is a contradiction (not just under-specification)

For `DETECTION_TYPE=llm-context` (the case that covers both Copilot CLI and Claude Code, per the locked platform directory at L611–614), two of the four audit fields — `verdict` and `evidence` — are computed by the orchestrator inspecting its own context after the script returns. The script has no way to know either value. Therefore:

- If the script writes the audit file (per the Audit-log entry section + separation note), it cannot populate `verdict` or `evidence` for the `llm-context` case — the fields would be missing or wrong, defeating "this makes mis-detections diagnosable."
- If the orchestrator writes the audit file (the only actor with the data), the separation note's "single-owner property preserved per file" claim is false and the L671 sentence "the detection script writes" is incorrect.
- If both write (script writes shell-verdict + user-override-only cases, orchestrator writes llm-context cases), there are two writers for one file — also contradicting "single-owner property preserved per file" and unspecified mechanically (does the orchestrator overwrite, append, merge?).

There is no implementer-discoverable resolution in the design block.

## Concrete downstream impact

- **Structure / Plan / Implement guessing.** Sub-Rule C requires every output to name a consumer and every step's I/O to be traced. Here the *writer* is unspecified for the case that covers all supported v0.7.2 hosts. Plan task authoring for `scripts/detect-interaction-mode.sh` cannot decide whether the script needs a write capability (path arg, atomic-mv pattern, manifest entry) without re-opening Design.
- **Multi-Actor Flow Check (CD-3) will fire downstream.** Structure / Plan / Implement consumers running CD-3 on this decision will hit a missing element ("how A invokes B" / "who reads C's output" in the diagnostic template) and halt — exactly the failure mode CD-3 catches.
- **Sub-Rule D is also tripped.** The detection signal table at L611–614 is well-cited per Sub-Rule D, but the post-detection audit-write mechanism (a flow specification, not an external-knowledge claim) has no consistent owner.

## Recommendation

Pick one writer and rewrite the three sections to agree. Two clean shapes:

**Option A — Orchestrator-only writer.** Strip the audit-write responsibility from the script entirely. Update the Contract section to remain stdout-only (no change). Rewrite the Audit-log entry section to read "After each round-start invocation, the **orchestrator** writes `<round-dir>/.interaction-mode-audit.json` with shape `{platform, detection_type, verdict, evidence}`, populating `verdict` and `evidence` from the values it derived per the LLM-context INSTRUCTION (or the values the script returned for `shell-verdict` / `user-override-only` cases)." Update the separation note's writer attribution from `scripts/detect-interaction-mode.sh` to "orchestrator (post-script)." Single owner is preserved at the orchestrator.

**Option B — Two-pass script writer.** Extend the script's Contract to take an additional `--write-audit <path> --verdict <auto|interactive> --evidence <prose>` invocation form, invoked by the orchestrator *after* it derives the values from context inspection. The script then writes the audit JSON. The Contract section must be updated to document the second invocation form and its exit codes. The orchestrator-side flow becomes two bash calls per round-start (detect, then audit-write).

Option A is simpler (one bash call, one writer, no new script flags) and matches the precedent set by the `.orchestrator-fixes.json` audit file in I.3 (writer = orchestrator). Recommend Option A.

Either way, the three sections (Contract, Audit-log entry, Caching) must all use the same writer attribution, and the separation note's writer name must match.

## Why this matters at design quality (not scope)

This is internal contradiction within a single CD's locked-component spec — the design-quality check named in the reviewer protocol ("No internal contradictions — component descriptions, data-flow explanations, and interface definitions are mutually consistent"). It is not a scope boundary concern.
