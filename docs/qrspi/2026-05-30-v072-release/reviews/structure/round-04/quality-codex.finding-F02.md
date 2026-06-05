---
artifact: structure
reviewer_tag: quality-codex
finding_id: R4-F02
round: 4
severity: medium
change_type: clarity
line_range: [449, 457]
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
---

# Interface §16 splitter NO_FINDINGS sentinel filename/path unspecified

## Problem

Interface §16 (line 456) says:

```
# Side effect: ... writes NO_FINDINGS sentinel file on clean NO_FINDINGS stdout
```

The sentinel filename/path is not defined. Sibling interfaces in structure.md all name exact filenames (`kept-findings.txt`, `.round-complete.json`, `<tag>.finding-F<NN>.md`), but this one says only "NO_FINDINGS sentinel file."

## Impact

Implement and Test consumers of this interface cannot know what filename to look for when checking whether a third-party reviewer returned NO_FINDINGS. The apply-fix protocol's clean-sentinel detection logic depends on knowing the sentinel's exact path.

## Fix

Specify the exact output path/filename. Recommended tag-scoped form to mirror the per-finding pattern:

```
# Side effect: ... writes <round-dir>/<tag>.no-findings on clean NO_FINDINGS stdout
```

Or pin to the canonical clean-sentinel pattern used elsewhere in the apply-fix protocol: `<round-dir>/<tag>.clean.md` with `status: clean` frontmatter.
