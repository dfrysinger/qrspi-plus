---
reviewer: simplify-claude
finding: F03
task: task-10
round: 04
severity: advisory
category: duplication
file: tests/unit/test-using-qrspi-vocab.bats
lines: 809-830
status: open
---

# F03 — `_extract_h4` is duplicated verbatim across two BATS files

## What

The helper `_extract_h4` is defined identically in two places:

- `tests/unit/test-config-model-routing.bats` lines 26-48 (T07 origin)
- `tests/unit/test-using-qrspi-vocab.bats`    lines 809-830 (T10 R2 fix)

The R2 copy explicitly acknowledges the duplication in its own
preamble comment (lines 802-808):

```
# H4 section extractor — the shared helper supports H2/H3 only. The
# fail-loud paragraph added by T10 R2 lives at the END of the H4 section
# `#### \`model_routing:\` block`, so the R2 pins below extract the H4 body
# (between the H4 anchor and the next H1-H4 boundary) and grep within it.
# Mirrors the _extract_h4 helper defined in test-config-model-routing.bats.
```

The two function bodies are byte-identical: same `awk` script, same
"h4 anchor not found" diagnostic, same "h4 extract empty" diagnostic,
same `printf '%s\n'` output convention. There is no behavior
difference between the two copies — just a copy-paste.

The shared helper module `tests/helpers/skill-markdown.bash` already
provides `extract_section` (H2/H3) and explicitly notes the gap that
`_extract_h4` was created to fill:

```
extract_section <file> <heading_level> <heading_text>
  - heading_level is "H2" or "H3" (case-sensitive).
```

## Why it's a simplification candidate

- **Two future regressions, not one.** If the SKILL.md H4 anchor
  convention changes (someone adds H5 or shifts the schema to H3),
  two test files have to be updated in lock-step. A divergence between
  the two copies — e.g. one allows H5 as a non-boundary, the other
  does not — would silently change what each test extracts.
- **The "Mirrors" comment is a smell.** The comment exists because
  the author knew they were duplicating but had no shared-helper home
  for the function. The shared-helper home already exists at
  `tests/helpers/skill-markdown.bash`; the H4 variant just hadn't
  been added.
- **No semantic difference to preserve.** Unlike cases where two
  copies have subtly diverged for good reason (different terminator
  rules, different error formats), these two copies are byte-identical
  and consciously kept that way.

## Suggested shape (semantics-preserving)

Add `extract_section` H4 support to the shared helper. Two routes:

**Route A (smallest change):** Add `H4` as a valid value in
`_skill_md_prefix_for_level`:

```bash
_skill_md_prefix_for_level() {
  case "$1" in
    H2) printf '## '   ;;
    H3) printf '### '  ;;
    H4) printf '#### ' ;;            # +1 line
    *) _skill_md_die "invalid heading_level '$1' (expected H2, H3, or H4)"
       return 1 ;;
  esac
}
```

The existing `extract_section` body uses
`substr($0, plen + 1, 1) == "#"` as the "deeper heading" guard, which
already does the right thing for H4 (deeper = H5+, which the schema
doesn't use anyway). The two consumer files then call
`extract_section "$file" H4 '`model_routing:` block'` instead of their
local `_extract_h4`.

**Route B (helper sticks closer to the current `_extract_h4` shape):**
Add a dedicated `extract_h4 <file> <heading-text>` function to
`skill-markdown.bash` that wraps the existing `extract_section` with
`H4` as the fixed level. Two consumers call `extract_h4` instead of
`_extract_h4`. Slightly more code than Route A, but preserves the
two-arg consumer signature both files currently use.

Either route deletes ~23 lines from `test-using-qrspi-vocab.bats`
(the duplicated function body) and ~23 lines from
`test-config-model-routing.bats`. Net change: ~−40 LOC, single point
of repair, helper-module consistency with H2/H3 pattern.

## Why this is advisory only

The duplication is functional — both copies work, both produce
correct diagnostics, both are loud on miss. The R1/R2 fix-task scope
was tightly bounded (add the vocab pins, restore the fail-loud
contract); cross-file refactor of a shared helper is out of scope for
either fix task. Verifier may KEEP if cross-file helper hoisting is
deferred to a separate cleanup task. The scope reviewer's brief
explicitly flagged this as a documented deviation worth surfacing.

## Pointer

- `tests/unit/test-config-model-routing.bats:26-48` (T07-era definition)
- `tests/unit/test-using-qrspi-vocab.bats:802-830` (T10 R2 mirror + acknowledging comment)
- `tests/helpers/skill-markdown.bash:56-65` (current H2/H3-only prefix gate — natural extension point)
