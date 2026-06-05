---
finding_id: R4-F01
severity: low
change_type: scope
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md:L402]
line_range: L384-L404
artifact: structure
round: 4
reviewer: scope-claude
---

Interface §13 ("Interaction-mode detector") includes a "Locked platform
directory" paragraph at line 402 that re-states architecture decisions
owned by Design:

> Locked platform directory (verified at design time as of 2026-05-31):
> Copilot CLI returns `DETECTION_TYPE=llm-context`; Claude Code returns
> `DETECTION_TYPE=llm-context`; unknown host returns
> `DETECTION_TYPE=user-override-only`. See design.md CD-4 §I.7 for full
> platform table.

The paragraph itself cites `design.md CD-4 §I.7` as the authoritative
source for the full platform→detection-type table, then duplicates a
subset of that table inline. Per the OWNS/DEFERS contract this is
boundary drift in two ways:

1. **Architecture decisions → Design (DEFERS rule).** Which signal each
   platform returns is *which approach* the host probe takes on that
   platform — a CD-4 architectural decision. Structure declares the
   script's CLI/API surface (which it correctly does in the code block
   on lines 388-398 with `Stdout: KEY=VALUE pairs...` and the
   per-`DETECTION_TYPE` shapes). Enumerating per-platform return values
   is architecture content, not interface-shape content.
2. **Single-source violation.** With the full table living in design.md
   CD-4 §I.7 and a subset re-stated here, the two surfaces can drift
   independently when a new host is added or a platform's detection
   type changes. The whole point of citing design.md is to avoid that.

The same risk does NOT apply to the rest of §13: the script-comment
block (exit codes, stdout shapes, KEY=VALUE grammar) and the audit-file
schema (`{platform, detection_type, verdict, evidence}`) are
parameter-shape / interface-surface content that Structure correctly
owns. Likewise the "Override chain" paragraph at line 400 is on the
borderline (env-var *name* is interface shape, but the safe-default
value `interactive` is also a Design decision) — flagging only the
clearer signal at line 402.

Suggested resolution: drop the "Locked platform directory" sentence
entirely and let the existing `See design.md CD-4 §I.7 for full
platform table.` citation stand alone (it already does the work). If
Structure needs a one-line pointer for navigability, replace the
duplicated mappings with a bare cross-reference such as: "Per-platform
return values are listed in design.md CD-4 §I.7."
