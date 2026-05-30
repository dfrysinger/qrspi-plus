# sf-claude · Finding F01 · Round 08

**Task:** T9 – Remove `model:` from agent frontmatter  
**Artifact:** `tests/unit/test-agent-frontmatter-no-model.bats`  
**Commit under review:** a73ecb8 (b431a7f..a73ecb8)  
**Change type:** clarity / intent  
**Severity:** minor

---

## Description — Fixture filename now semantically incorrect after R7 body change

### Location
`tests/unit/test-agent-frontmatter-no-model.bats`, line 278:

```bash
local fixture="${BATS_TEST_TMPDIR}/qrspi-test-scalar-at-end-no-body-model.md"
```

### What changed in R7
The R7 fix changed the body of this fixture from:
```
no model key anywhere in this body
```
to:
```
model: this line must not appear in frontmatter output
```

The fixture filename — `qrspi-test-scalar-at-end-no-body-model.md` — was chosen in an earlier round to mean "scalar-at-end topology, body has no `model:`."  After R7 the body **does** contain a `model:` line, so the filename is now inverted: it says "no-body-model" but the body carries exactly that key.

### Why this is a silent-failure risk
The fixture filename is a diagnostic artifact. When a bats test fails, BATS prints the fixture path in the error message (e.g. via the `echo "  offending_line=${offending_line}"` fallback path at line 295). A maintainer who reads:

```
offending_line=5:model: this line must not appear in frontmatter output
  fixture: …/qrspi-test-scalar-at-end-no-body-model.md
```

…sees a filename asserting "no body model" while the failing output proves there is a body `model:`. This contradiction:

1. **Obscures the failure direction** — the reader may wonder whether the fixture file was modified or the test description is wrong before examining the code.
2. **Inverts the test's stated intent** — anyone grepping for `no-body-model` to find the "verify clean when body is clean" test will find the test that now verifies the opposite topology.
3. **Is invisible at test-pass time** — when the test passes (correct `_frontmatter` behaviour), no one sees the filename mismatch. The error only surfaces in exactly the debugging session where clear naming is most valuable.

### Recommended fix
Rename the fixture to reflect the new topology (body contains `model:`):

```bash
# Before (line 278):
local fixture="${BATS_TEST_TMPDIR}/qrspi-test-scalar-at-end-no-body-model.md"

# After:
local fixture="${BATS_TEST_TMPDIR}/qrspi-test-scalar-at-end-body-model-overread.md"
```

The companion test at line 249 already uses `qrspi-test-scalar-at-end-body-model.md`; appending `-overread` avoids a collision and signals that this test's body `model:` exists specifically to be caught by the over-read detector.

---

## Primary question answered
**R7 closed R6 sf.F01 correctly.** The assertion `[ -z "$offending_line" ]` is now genuinely non-vacuous: a body-level `model:` exists for `_frontmatter` to over-read into, and the grep would return a non-empty match if the fix were reverted. No new silent-failure logic paths are introduced by the R7 change — the naming inconsistency is the sole residual issue.
