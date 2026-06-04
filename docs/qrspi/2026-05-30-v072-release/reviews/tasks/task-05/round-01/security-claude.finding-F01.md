---
finding_id: F01
reviewer_tag: security-claude
round: 1
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-change-type-partition.bats:203-205
artifact: tests/unit/test-change-type-partition.bats
---

# Path Traversal via Basename-Only Sanitization → Destructive `rm -rf` Outside BATS Tmpdir

Materialized from chat-only response by claude-sonnet-4.6.

```bash
local name="${src##*/}"          # basename only
local dest="$BATS_TEST_TMPDIR/$name"
rm -rf "$dest"                   # no guard on what dest resolves to
cp -R "$src" "$dest"
```

`${src##*/}` strips everything up to the last `/`, yielding only the final path component. It does NOT prevent the component from being `..`. If `src` ends in `/..` (or is the bare string `..`), `name` becomes `..` and `dest` becomes `$BATS_TEST_TMPDIR/..` — the parent of the per-test tmpdir. The subsequent `rm -rf "$dest"` deletes the parent directory.

Fix: validate `name` is a single-component token (no `.`, no `..`, no `/`) before constructing `$dest`.
