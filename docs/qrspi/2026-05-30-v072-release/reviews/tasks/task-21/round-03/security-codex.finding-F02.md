---
finding_id: F02
reviewer: security-codex
severity: low
change_type: correctness
referenced_files: [scripts/dispatch-agent.sh:900-979, scripts/dispatch-agent.sh:691, scripts/dispatch-agent.sh:1033, scripts/dispatch-companion.sh:609-614, scripts/dispatch-companion.sh:635]
---
**TOCTOU symlink swap between check and cat.** Path validated then re-read by string; symlink flip after check reads new target. Hardening: open-read-by-fd at check time and reuse fd, or call realpath() once and pass canonical path forward.

**Adjudication:** DEFER to v0.7.3. Local-shell-access TOCTOU is outside the G16 single-process ingestion-guard threat model; multi-process attacker requires shell access (already a worse compromise). Trade-off is API churn (open-fd-based ingestion) vs. low practical risk. Track for v0.7.3 architectural hardening.
