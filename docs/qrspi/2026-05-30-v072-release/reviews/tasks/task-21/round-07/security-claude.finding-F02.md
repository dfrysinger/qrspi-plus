---
finding_id: R7-F02
severity: high
change_type: correctness
referenced_files: [scripts/dispatch-agent.sh]
status: closed-cycle-8
---
--scope-hint value not checked for its own end marker (only AGENT-BODY-END was
checked), enabling marker-injection breakout from untrusted wrapper. Closed by
514a6cd via FORBIDDEN_MARKERS array (5 markers); both file and value rejection
helpers now iterate.
