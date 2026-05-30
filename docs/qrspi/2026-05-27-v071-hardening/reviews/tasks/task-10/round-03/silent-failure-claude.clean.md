---
reviewer: silent-failure-claude
task: 10
round: 03
status: clean
---

# Silent-failure-claude — Task 10 Round 03 — CLEAN

No silent-failure findings. Round-02 KEPT finding F01 (fail-loud contract
missing for three model_routing invariants) is fully closed by the R2 fix.

## Verification of R2 F01 closure

The new paragraph inserted at `skills/using-qrspi/SKILL.md:470` (end of
`#### \`model_routing:\` block` section) names all three invariants and
forbids both silent fallback paths the R2 finding called out:

1. **Missing host key** — *"`detect_host` returns a host value for which
   `model_routing:` has no matching top-level key"* ✓
2. **Missing tier row** — *"an agent's tier name (or the implicit
   `inherit`) matches no row under the matched host's sub-mapping"* ✓
3. **Bare short-form value** — *"a tier value is a bare short-form
   (`haiku`, `sonnet`, `opus`) rather than a fully versioned model ID"* ✓

Action on violation: *"the dispatcher halts and reports the missing or
invalid entry"* ✓

Both fallback paths from F01 explicitly forbidden:
- Agent-bundled-default fallback: *"never falls back silently to the
  agent-bundled default"* ✓
- Host-CLI re-routing fallback: *"never passes the dispatch through to
  the host CLI's silent re-routing"* ✓

The paragraph closes with the G7b/#204 cross-reference making the
load-bearing intent explicit.

## Slice 2 (trusted_path: bullet) — no new silent-failure surface

The replacement of *"matches entries in `model_routing:`"* with
*"matches the `model_role:` value declared in an agent's frontmatter
— independent of `model_routing:`'s host-keyed structure"* **closes**
(rather than opens) a silent-failure surface: post-R1, the old wording
directed role-name `trusted_path:` entries to match against
host-keyed top-level keys (`claude-code:`/`copilot-cli:`), so any
role-name entry would silently fail to match. The new wording
redirects to `model_role:` frontmatter (the actual matching domain
per `skills/implement/SKILL.md:520`).

Pre-existing gap (unchanged by the diff, therefore out of scope):
neither wording documents the behavior when a `trusted_path:`
role-name entry matches NO agent's `model_role:` value. This gap
existed identically pre-fix and is not surfaced by round-03.

## Bats test changes — silent-surface scan

### test-config-model-routing.bats (Slice 3a)

Rename + `"role lookup"` → `"host/tier lookup"` flip **closes** a
silent-pin surface. The inline comment added by the fix explicitly
documents that the pre-R2 pin was silently passing under the old
wording via a bats `[[ ]]` short-circuit quirk. Post-R2 the pin
asserts the GREEN behavior explicitly. ✓

### test-using-qrspi-vocab.bats (Slices 3b + 3c)

The new local `_extract_h4` helper propagates failures correctly:
- awk-side `exit 1` triggers the `|| { ...; return 1; }` clause with a
  stderr message naming the missing anchor.
- Empty body check after extraction returns 1 with a stderr message.
- Test file requires `bats_require_minimum_version 1.5.0` at top, so
  failing `[[ ]]` assertions terminate the test body cleanly (no
  silent-pass quirk).
- A missing H4 anchor produces empty body → subsequent `[[ ]]`
  substring match fails → test loudly RED-fails. ✓

Soft pin-coverage observation (not raised as a finding because the
fix-task spec explicitly authorized this shape — see fix-task-02.md
Slice 3b rationale "Asserts the two key load-bearing phrases without
over-pinning"): the new pins assert presence of `"halts and reports"`
and `"never falls back silently"` and absence of `"silently fall back
to the agent-bundled default"` / `"silently degrade"`. A future edit
that deleted one of the three invariant clauses (e.g., dropped the
bare-short-form invariant) while leaving the surrounding "halts and
reports" + "never falls back silently" sentences intact would not
RED-fail these pins. The SKILL.md *contract* prose is complete and
correct as landed — this is purely a pin-breadth observation, not a
production silent-failure surface, and the fix-task spec was explicit
about the trade-off.

## Anchors regen (Slice 4)

`SKILL.anchors.json` deltas are mechanical +2 line-number shifts
throughout, matching the 2-line insertion at the `#### \`model_routing:\`
block` section. No semantic surface. ✓

## Summary

All four review criteria for the R2-fix-task spec are satisfied:
- (1) Three invariants named ✓
- (2) Both fallback paths forbidden ✓
- (3) trusted_path: bullet repair doesn't reopen silent-failure surface ✓
- (4) No other silent-failure surface in the diff ✓
