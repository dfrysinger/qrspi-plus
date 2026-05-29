---
finding: F03
reviewer: sf-claude
round: 2
task: task-03
severity: medium
change_type: correctness
file: tests/helpers/skill-markdown.bash
lines: 242-245, 259-261, 264-270
persistence_note: orchestrator-persisted (chat-only fallback)
---

# F03 — fence-delimiter lines inside an anchored section never set has_content; an empty fenced block is silently misclassified as FOUND_EMPTY and its output is discarded

## Location

`tests/helpers/skill-markdown.bash` lines 242–245 and 259–261 (`extract_section_fence_aware`, awk body)

## What the code does

**Rule A — fence-delimiter handler (line 242–245):**
```awk
/^```/ {
  fence = !fence
  if (in_b) print          # prints the ``` line to stdout
  next                     # skips ALL remaining rules, including Rule B
}
```

**Rule B — body-content handler (lines 259–261):**
```awk
in_b {
  print
  if ($0 ~ /[^[:space:]]/) has_content = 1   # only place has_content is set
}
```

Because Rule A calls `next`, fence-delimiter lines (`` ``` ``) inside an anchored section are **printed** but **never reach Rule B**. `has_content` is never set by fence-delimiter lines alone.

## Silent failure path

Consider a section containing only an empty fenced block:

```markdown
### Target Section
```
```
### Next Section
```

Processing:
1. `### Target Section` → `in_b=1`, `found=1`, printed.
2. Opening `` ``` `` → Rule A: `fence=1`, printed, `next` — has_content not set.
3. Closing `` ``` `` → Rule A: `fence=0`, printed, `next` — has_content not set.
4. `### Next Section` → boundary detected, `exit`.
5. END: `found=1`, `has_content=0` → writes `FOUND_EMPTY`.

Back in shell, `signal="FOUND_EMPTY"` triggers `return 1` with "no content lines". **`awk_out` contains the anchor line and both fence-delimiter lines — real, non-whitespace content — but it is silently discarded.**

## Why it matters

* The spec says "a region containing only whitespace… triggers the no-content error path." Fence delimiters (`` ``` ``) are not whitespace.
* A caller that passes a section with only a fenced code block (e.g., a section that is purely a shell script) will receive a spurious extraction failure.

## Recommended fix

```awk
/^```/ {
  fence = !fence
  if (in_b) {
    print
    has_content = 1
  }
  next
}
```
