---
finding: F01
reviewer: sf-claude
round: 2
task: task-03
severity: medium
change_type: correctness
file: tests/helpers/skill-markdown.bash
lines: 239-273
persistence_note: orchestrator-persisted (chat-only fallback)
---

# F01 — awk exit code swallowed; awk failure misreported as "anchor not found"

## Location

`tests/helpers/skill-markdown.bash` lines 239–273 (`extract_section_fence_aware`)

## What the code does

```bash
awk_out="$(awk -v anchor="$anchor" -v signal_tmp="$signal_tmp" '
  ...
  END {
    if (found) {
      if (has_content) { print "FOUND_WITH_CONTENT" > signal_tmp }
      else             { print "FOUND_EMPTY"        > signal_tmp }
    }
  }
' "$file")"
# $? is never checked here
```

## Silent failure path

If awk itself fails (OOM kill, exec failure, or any non-zero exit), the `END` block either does not run or runs incompletely. `signal_tmp` is never written, so `signal=""`. The `*)` wildcard case fires:

```bash
printf 'extract_section_fence_aware: %s: not found in %s\n' "$anchor" "$file" >&2
return 1
```

The caller receives exit 1 with "not found in <file>" — factually wrong. The anchor may be present in the file; awk simply crashed.

## Why it matters

* The spec explicitly requires the two error paths to be distinguishable by message body (missing-anchor vs. empty-region). An awk crash introduces a third, unlabelled failure path that impersonates the missing-anchor path.
* Any caller that acts on "not found" semantics will misdiagnose the failure.

## Recommended fix

```bash
awk_out="$(awk ... "$file")"
local awk_status=$?
if [ "$awk_status" -ne 0 ]; then
  printf 'extract_section_fence_aware: awk failed (exit %d) processing %s\n' \
    "$awk_status" "$file" >&2
  rm -f "$signal_tmp"
  return 1
fi
```
