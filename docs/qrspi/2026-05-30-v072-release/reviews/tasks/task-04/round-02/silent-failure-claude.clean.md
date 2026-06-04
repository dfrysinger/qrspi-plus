---
reviewer: silent-failure-claude
task: 4
round: 2
status: clean
---

# Silent-Failure Review — T04 R2 — Clean

All three R1 silent-failure findings are closed by the R2 fix diff
(`round-02.diff`):

1. **awk now frontmatter-restricted.** `_test_mirror_partition_finding`
   (tests/unit/test-change-type-partition.bats:72–76) tracks `in_fm` /
   `fm_count` and only matches `change_type:` between the first two `---`
   markers. A `change_type:` token appearing only in body prose can no
   longer false-route a frontmatter-malformed finding.

2. **Helper renamed + commented as test-mirror.** The helper is renamed
   to `_test_mirror_partition_finding`
   (tests/unit/test-change-type-partition.bats:69) and the comment block
   on lines 58–68 explicitly identifies it as a test-local mirror of the
   schema-guard contract, naming T05 (`scripts/verifier-fan-in.sh`) as
   the production-enforcement owner. Future readers cannot mistake this
   helper for the production routing path.

3. **Audit loop loud-fails on missing files.** The silent `continue` on
   missing scope files is replaced with
   `{ echo "scope audit: required file missing: $f" >&2; return 1; }`
   (tests/unit/test-change-type-partition.bats:162). A scope-list file
   that goes missing now produces a named-cause stderr diagnostic and
   fails the test, rather than letting the audit pass vacuously.

No new silent-failure regressions were introduced by the R2 changes:

- The `BATS_TEST_TMPDIR/ct-stderr.log` redirect (line 98) replaces the
  R1 racy `/tmp/ct-stderr-$$.log` with a bats-managed, auto-cleaned
  path — no swallowed-error window on parallel runs and no orphan-file
  leak on test failure.
- The awk `BEGIN { in_fm = 0; fm_count = 0 }` initialization is
  explicit; there is no implicit-empty-string state that could mask a
  malformed first `---` marker.
- The missing-`change_type:` test asserts all three observable
  properties of loud failure simultaneously: non-zero rc, empty stdout
  (no route emitted), and a named-cause stderr regex match
  (lines 101–104). Silent acceptance, silent drop, and default-routing
  are each independently disprovable.
