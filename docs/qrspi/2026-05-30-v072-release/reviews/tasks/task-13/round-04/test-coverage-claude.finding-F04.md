# F04 — Malformed-anchor test covers only the wrong-charset shape, not the missing-trailing-newline shape the regex specifically rejects

**Severity:** low
**Files:** `tests/unit/test-scope-tagger-dispatch.bats` L741-764; `scripts/round-prepare.sh` L193-203

## The validation under test

```python
re.match(rb"^[0-9a-f]{40}\n$", data)
```

This regex enforces **three** independent properties of the prior anchor:
1. lowercase hex charset,
2. exactly 40 characters,
3. **exactly one trailing newline and nothing else.**

## The gap

The malformed-anchor test (L752) writes `printf 'not-a-sha\n'` — a value that fails on
properties 1 **and** 2 simultaneously. No fixture exercises a value that is a *valid 40-char
lowercase SHA* but fails property 3 — e.g. a 40-hex string **without** a trailing newline,
or with a trailing-space/extra content. That missing-newline case is the most plausible
real-world malformation (a prior round that wrote the anchor with `echo -n` or a truncated
write), and it is the exact reason the regex anchors on `\n$` rather than just matching the
SHA. Because the only malformed fixture also fails the charset/length checks, a regression
that loosened the trailing-newline requirement (e.g. `[0-9a-f]{40}` with no `\n$`) would
**still pass every test** — the wrong-charset fixture would still be rejected on charset
alone.

Symmetrically, the happy-path round-1 test (L592) confirms the *writer* emits a single LF
(L614-617), but no test confirms the *reader's* regex actually requires it; those are two
different code paths.

## Suggested coverage

Add a malformed-anchor fixture that writes a genuine 40-char SHA **without** a trailing
newline (e.g. `printf '%s' "$valid_sha"`) and assert exit 1 + `malformed` diagnostic. This
pins the trailing-newline branch of the regex independently of the charset/length branch.
