---
reviewer: cq-claude
round: 2
finding: F03
change_type: style
file: tests/unit/test-host-detection.bats
lines: "57"
severity: minor
---

# F03 — QRSPI-internal round token `R8` embedded in a test-file comment

## Location
`tests/unit/test-host-detection.bats` line 57:

```bash
# Carry-forward set-asides from Plan R8:
```

## Problem

`R8` matches the QRSPI-internal ID pattern (`\b[GRDFTQ]-?[0-9]+\b`) and is a
run-specific round token — a reference to an internal planning round of the QRSPI
process.  Per the ID hygiene rule, QRSPI-internal IDs are forbidden in code comments
and test-file comments outside `docs/qrspi/`.

The test file will live in `tests/unit/`, which is not under `docs/qrspi/`, so the
exemption for that tree does not apply.  A future reader encountering `Plan R8` in the
source gains no actionable signal (there is no public artefact called "Plan R8" they
can look up in the repository), and the token ties the comment to a process epoch that
has no stable meaning once the run is over.

## Recommended fix

Replace the opaque process reference with a plain-language description of the
set-asides' origin:

```bash
# Carry-forward set-asides noted during spec review:
```

or simply inline the intent without the process reference:

```bash
# Retained scope decisions:
```

Either phrasing preserves the orientation value of the comment without embedding a
run-specific internal ID.
