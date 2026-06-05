---
finding_id: R3-F03
reviewer: sf-claude
severity: high
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
---

# F03 — First-party path: compose_prompt redirect unchecked + mkdir -p unchecked

**Convergent with sf-codex R3-F01 / cq-codex R3-F01 / sec-codex R3-F01.** sf-claude adds a sub-case:

**(a) mkdir -p failure not propagated:** if `mkdir -p "$_fp_dispatch_dir"` fails (permissions, read-only fs), the directory does not exist. Bash then fails to open `"$_fp_prompt_file"` for writing and emits stderr — but since `set -e` is off, execution continues. `printf 'DISPATCH_FILE=%s\n'` emits a reference to a nonexistent file. `emit_first_party_manifest_entry` writes manifest entry claiming `status: dispatched`. `exit 0` fires.

**(b) compose_prompt partial output:** compose_prompt sources files with cat + strip_frontmatter (awk). A failure inside compose_prompt does not abort; the partially-written prompt file is closed, DISPATCH_FILE is emitted with the truncated body referenced, exit 0.

**The exit 0 at line 797 makes the first-party path a hard exit-code success gate** with no way for the orchestrator to distinguish success from failure using exit code alone. DISPATCH_FILE reference + manifest entry are the only signals — both written regardless.

**Fix:** check both mkdir and compose_prompt:

```bash
mkdir -p "$_fp_dispatch_dir" || {
  echo "error: cannot create dispatch dir $_fp_dispatch_dir" >&2
  exit 1
}
if ! compose_prompt > "$_fp_prompt_file"; then
  rm -f "$_fp_prompt_file"  # don't leave a partial file referenceable
  echo "error: compose_prompt failed" >&2
  exit 1
fi
```
