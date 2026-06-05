---
finding_id: R4-SF-F02
reviewer: silent-failure-claude
severity: low
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
at_cap: true
escalate: true
---

# F02 — First-party path emits `DISPATCH_FILE=` to stdout before manifest write completes — partial-success signal on manifest failure

**Introduced by R4 Group B (first-party copilot-cli dispatch path).**

## Location

`scripts/run-codex-review.sh` lines 911–913 (first-party dispatch path):

```bash
# Emit the orchestrator-facing DISPATCH_FILE reference to stdout.
printf 'DISPATCH_FILE=%s\n' "$_fp_prompt_file"
emit_first_party_manifest_entry "$_fp_prompt_file"
exit 0
```

## Failure mode

`printf` writes the `DISPATCH_FILE=` line to stdout **before** `emit_first_party_manifest_entry` is called. If `emit_first_party_manifest_entry` subsequently fails — because `_append_manifest_entry`'s jq call fails, `mkdir -p` fails, the lock cannot be acquired, or `mv` fails — `_append_manifest_entry` calls `exit 1`, and the script exits with code 1.

At that point, the orchestrator's stdout pipe already contains:

```
DISPATCH_FILE=/path/to/out/.dispatch/spec-codex.prompt
```

The caller now receives **both** a non-zero exit code (failure) **and** a `DISPATCH_FILE=` reference that points at a real file that was successfully written. This is a partial-success state:

- The prompt file **exists** and is valid.
- The manifest **does not** record the dispatch.
- The script's exit code correctly signals failure.
- But any caller that parses stdout for `DISPATCH_FILE=` before checking the exit code (or that logs stdout for later audit) has a reference to a prompt file with no corresponding manifest entry.

The spec requires both the `DISPATCH_FILE=` reference (orchestrator contract) and the manifest entry (auditability contract). Emitting the reference before committing the audit record breaks the commit ordering: the caller's view of "dispatch happened" (DISPATCH_FILE= present) diverges from the manifest's view ("dispatch not recorded").

## Why this is silent

- The script does exit non-zero, so a correct caller will not proceed with the dispatch.
- However, if the caller captures stdout and exit-code independently (e.g., `stdout=$(script ...); rc=$?`), the stdout is already committed to the variable before `rc` is checked. Tooling that logs `DISPATCH_FILE=` for later replay could queue a prompt file whose dispatch entry the manifest will never contain.
- A retry of the script will re-write the prompt file and re-attempt the manifest write — this is idempotent — but the window between the failed first attempt and the successful retry leaves the system in a state where the manifest and the prompt-file directory disagree.

## Fix

Reverse the order: write the manifest entry **first**, then emit `DISPATCH_FILE=` to stdout only after the audit record is committed. On manifest failure, no stdout is emitted and the caller sees a clean failure:

```bash
# Commit audit record before signalling the orchestrator.
if ! emit_first_party_manifest_entry "$_fp_prompt_file"; then
  rm -f "$_fp_prompt_file"
  echo "error: manifest write failed for first-party dispatch" >&2
  exit 1
fi
# Emit the orchestrator-facing DISPATCH_FILE reference to stdout.
printf 'DISPATCH_FILE=%s\n' "$_fp_prompt_file"
exit 0
```

This ensures that `DISPATCH_FILE=` on stdout is only ever visible to a caller that also sees exit 0, closing the partial-success window.
