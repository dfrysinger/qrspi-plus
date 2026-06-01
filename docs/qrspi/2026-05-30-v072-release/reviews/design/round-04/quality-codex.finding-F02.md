---
finding_id: R4-F02
severity: medium
change_type: correctness
referenced_files:
  - design.md (CD-4 § I.3)
---

## Issue
The rescue/disposition accounting is inconsistent when `orchestrator_rescue: false`: behavior matrix says every halt escalates immediately, but `.orchestrator-fixes.json` is defined as rescue-tier event logging and the dispositions "Rescue tier breakdown" is sourced from that file. Under rescue-off, escalations occur without rescue-tier execution, so E1–E4 escalation counts are not reliably derivable from the declared source.

## Why it matters
Round-end dispositions can become non-repeatable or incorrect (showing zero/partial escalations despite real escalations), weakening the audit trail this change is intended to provide.

## Proposed change
Extend the audit contract to log escalation events independently of rescue-tier execution (including rescue-off paths), or narrow dispositions sourcing to only what the file can deterministically represent and define a second source for escalations.

## Citation
- design.md:L525-L533
- design.md:L539-L542
- design.md:L545-L549
