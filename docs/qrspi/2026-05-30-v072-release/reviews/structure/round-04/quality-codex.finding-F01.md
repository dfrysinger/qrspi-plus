---
artifact: structure
reviewer_tag: quality-codex
finding_id: R4-F01
round: 4
severity: medium
change_type: correctness
line_range: [210, 214]
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
---

# Interface §3 verifier-fanout glob `*.finding-F*.md` may match sidecar files

## Problem

Interface §3 (line 213) specifies:

```
# Script globs <round-dir>/*.finding-F*.md to enumerate findings; --agents is not used
```

The verifier-fanout entry point will dispatch one verifier per matched file. If sidecar files share a `.finding-F<NN>.` segment in their filename, reruns/retries could re-dispatch verifiers against sidecar artifacts rather than the original finding files.

## Impact

If sidecars match the glob, verifier-fanout reruns would over-dispatch. The contract should constrain enumeration to finding files only (e.g., by glob shape or explicit exclusion).

## Fix

Either:
- Tighten the glob to be exclusive of sidecar suffixes (e.g., `*.finding-F[0-9][0-9].md` — note that sidecars are written as `.score.yml` per the using-qrspi spec, so a `.md`-anchored glob may already exclude them; verify and document explicitly).
- OR document the sidecar suffix convention inline (the using-qrspi protocol uses `.score.yml`) and state that the glob is safe because sidecars are `.yml`.

Either way, make the exclusion explicit in the interface contract so an implementer who reads §3 in isolation doesn't accidentally write sidecars as `.md` files.
