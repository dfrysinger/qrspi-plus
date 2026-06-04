---
finding_id: R3-F01
reviewer: sf-codex
severity: high
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
---

# F01 — First-party dispatch reports success on failed prompt assembly

**File:** scripts/run-codex-review.sh lines 793-797

`compose_prompt > "$_fp_prompt_file"` is unchecked. The script then unconditionally emits `DISPATCH_FILE=...`, writes the manifest, and `exit 0`. Because the script runs without `set -e`, prompt assembly/read failures produce a partial or empty prompt file while the caller sees success and a manifest entry pointing at the broken file.

**Convergent with cq-codex R3-F01:** cq-codex independently flagged the same issue, noting it "regresses the prior fail-loud behavior."

**Fix:** check `compose_prompt`'s exit code explicitly before emitting `DISPATCH_FILE=`:

```sh
if ! compose_prompt > "$_fp_prompt_file"; then
  printf 'first-party prompt assembly failed for tag %s\n' "$REVIEWER_TAG" >&2
  exit 1
fi
```

Verify the prompt file is non-empty before emitting the manifest entry.
