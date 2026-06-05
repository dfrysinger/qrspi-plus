---
finding_id: F02
reviewer: security-claude
severity: high
change_type: correctness
referenced_files: [scripts/dispatch-agent.sh:611, scripts/dispatch-agent.sh:679, scripts/dispatch-agent.sh:697, scripts/dispatch-companion.sh:621, scripts/dispatch-companion.sh:659]
---
**Batch `--agents` tag injection — arbitrary write gadget.** `_tag="${_pair%%=*}"` has no allowlist (single mode does at L758). Crafted `--agents "../../etc/cron=agents/foo.md"` sets `_prompt_file="$BATCH_OUTPUT_DIR/.dispatch/../../etc/cron.prompt"`, writing assembled prompt to attacker-chosen path. Same `_tag` propagates to `dispatch-companion.sh:621` job-id construction. Fix: add `[[ "$_tag" =~ ^[a-z][a-z0-9_-]*$ ]]` allowlist in batch mode + companion launch.
