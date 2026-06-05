---
finding_id: R3-F02
severity: low
change_type: correctness
referenced_files:
  - scripts/verifier-fan-in.sh
reviewer_tag: silent-failure-claude
round: 3
task: 02
---

`extract_frontmatter_field || true` swallows awk failures with wrong halt-cause attribution.

Locations (after the R2 readability guards):
- line 210: `ct=$(extract_frontmatter_field "$finding" change_type || true)`
- line 250: `raw_score=$(extract_frontmatter_field "$sidecar" score || true)`

The R2 `[[ ! -r ]]` guards (lines 200/239) protect against chmod-000 files. But `extract_frontmatter_field` invokes `awk` as a subprocess. `|| true` suppresses ANY non-zero exit, including: (1) awk absent from PATH (stripped container/sandbox); (2) OS resource exhaustion (OOM, fd limit); (3) TOCTOU race (file becomes unreadable between `[[ ! -r ]]` and awk's `open(2)`).

**Silent misattribution:** awk failure at line 210 → `ct=""` → `record_halt "$fid" missing_change_type` (wrong cause — real cause is awk failure). At line 250 → `raw_score=""` → `record_halt "$fid" score_unparseable` (same misattribution class). This is EXACTLY the wrong-halt-cause pattern that motivated the R2 `finding_unreadable`/`sidecar_unreadable` additions.

**Asymmetry:** the script has an explicit jq startup guard (lines 44-47) with `command -v jq` but no equivalent for awk.

**Fix (option A — consistent with jq guard, preferred):**
```bash
command -v awk >/dev/null 2>&1 || {
  echo "verifier-fan-in: awk is required but not found in PATH" >&2
  exit 2
}
```

This is lower-cost than inline defensive guards and mirrors the existing pattern.
