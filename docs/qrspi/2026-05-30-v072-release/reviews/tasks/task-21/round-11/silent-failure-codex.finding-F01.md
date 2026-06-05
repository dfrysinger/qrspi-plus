---
reviewer_tag: silent-failure-codex
round: 11
finding_id: R11-F01
severity: medium
change_type: scope
referenced_files:
  - scripts/dispatch-agent.sh:776-793
  - scripts/dispatch-agent.sh:1133-1139
  - scripts/dispatch-agent.sh:1188-1202
---

# F01 — cat/awk read failures silently ignored

dispatch-agent.sh runs with `set -u` but NOT `set -e`. In batch prompt assembly (L776-793, especially `cat "$BATCH_ARTIFACT_ABS"` at L787), `emit_untrusted_artifact` (L1133-1139, `cat "$path"` at L1137), and `compose_prompt` (L1188-1202, multiple strip_frontmatter/cat calls), failing reads (permission denied, transient I/O) do not halt execution. Subsequent successful `printf` commands overwrite the command-group exit status, so dispatch can exit 0 with truncated prompts.

Concrete failure mode: artifact/skill/task file passes -f guard, then becomes unreadable (TOCTOU race or perms change), prompt assembly continues silently, callers receive incomplete prompt with successful exit code.

Note: this is a generic shell-discipline concern (latent since pre-cycle-11), not introduced by fix-cycle 11. Closure requires either `set -o pipefail` + explicit per-read error handling or a wholesale refactor to read-into-var-with-status-check pattern across all cat/awk sites in the 1400+ line script.
