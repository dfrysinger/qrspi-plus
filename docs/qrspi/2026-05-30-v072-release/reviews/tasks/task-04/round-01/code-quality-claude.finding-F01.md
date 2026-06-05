---
finding_id: R1-F01
severity: low
change_type: style
referenced_files: ["tests/unit/test-change-type-partition.bats:L86-L88"]
artifact: code
round: 1
reviewer: code-quality-claude
---

The new schema-guard test captures stderr via a hand-rolled tempfile at a hardcoded `/tmp` path:

```bash
out=$(_partition_finding "$fixture" 2>/tmp/ct-stderr-$$.log) && rc=0 || rc=$?
err=$(cat /tmp/ct-stderr-$$.log); rm -f /tmp/ct-stderr-$$.log
```

Two cleanliness problems with this idiom:

1. **Non-portable path.** `/tmp` is not guaranteed writable in every environment the bats suite may run in (sandboxed CI, hermetic builders). Bats already provides `BATS_TEST_TMPDIR` (per-test, auto-cleaned) and `BATS_FILE_TMPDIR` for exactly this case — the suite would not need to make any assumption about `/tmp`.
2. **Tempfile is unnecessary.** The test only needs stderr; it discards stdout-on-error and inspects stdout-on-success separately. The standard shell idiom for capturing only stderr without a tempfile is `err=$(_partition_finding "$fixture" 2>&1 >/dev/null)` — and the rc capture can be done by a second invocation or by inverting which stream goes where. Bats `run --separate-stderr` (bats-core ≥ 1.5) would also collapse the entire `out`/`err`/`rc` block into `run --separate-stderr _partition_finding …` followed by `$status` / `$output` / `$stderr` reads, but that's a bigger stylistic change and the rest of the file does not use `run`.

The current code is the *only* tempfile use in `tests/unit/test-change-type-partition.bats`; the existing tests above (lines 4-49) all do plain variable capture. The new block is also the only `/tmp` reference in the file. A tempfile-free formulation would keep the new block consistent with the file's existing idiom.

A minimal fix that stays in the file's existing style:

```bash
local out err rc
err=$(_partition_finding "$fixture" 2>&1 >/dev/null) && rc=0 || rc=$?
out=$(_partition_finding "$fixture" 2>/dev/null) || true
```

(or, if the duplicate invocation is a concern, swap streams once and split locally — both formulations avoid the tempfile and avoid `/tmp` entirely.)

Severity is `low` because the current code does work and the `rm -f` runs before the assertions, so there is no leak on assertion-failure paths in practice; the concern is portability and consistency with the rest of the file, not a correctness defect.
