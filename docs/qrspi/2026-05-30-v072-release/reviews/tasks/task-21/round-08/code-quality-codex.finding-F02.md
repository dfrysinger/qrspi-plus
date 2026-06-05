---
finding_id: R8-F02
severity: low
change_type: clarity
referenced_files: [scripts/dispatch-agent.sh]
status: closed-cycle-9
---
Dead code: MARKER_LITERAL="<<<AGENT-BODY-END>>>" variable left behind from
marker-guard refactor; superseded by FORBIDDEN_MARKERS array. Closed by 2202d83.
