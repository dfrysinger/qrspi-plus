---
task_id: fix-int-r5-01
task_type: lightweight
mode: fix
round: 5
artifact: integration
addresses:
  - R5-F01 (integration-claude, security, verifier 70) — validators: trusted-model re-run path uncovered
  - R5-F01 (security-claude, security, verifier 72) — both validators: re-run AND missing-block backfill uncovered
  - R5-F01 (security-codex, security, verifier 80) — corroborates both surfaces
references:
  - skills/using-qrspi/SKILL.md (only source file to edit; H4s at L490 validators: and L512 Missing model_routing:)
  - tests/unit/test-using-qrspi-vocab.bats (only test file to edit; append 4 new @test blocks)
  - docs/qrspi/2026-05-27-v071-hardening/reviews/integration/round-05/*.finding-F01.md (3 corroborating findings)
  - docs/qrspi/2026-05-27-v071-hardening/fixes/integration-round-04/fix-task-01.md (the R4 fix this extends — same pattern)
---

# fix-int-r5-01: Extend fail-loud contract to validators: + missing-block H4s (Option A)

## Problem

Three R5 reviewers independently surfaced the same residual defect class
after fix-int-r4-01 closed R4-F01:

- security-claude (verifier 72) — explicitly admits R4-F01 was undercounted
  (3 surfaces, R4 fixed 1)
- integration-claude (verifier 70)
- security-codex (verifier 80) — strongest score, independent corroboration

**The class:** After T9 emptied `model:` from all 41 agents, precedence
chain step 4 ("agent-bundled default") resolves to nothing for every
agent. ANY prose path in SKILL.md that routes to step 4 — bypassing
`model_routing:` — has the same three-way ambiguity R4-F01 enumerated:

| Choice | G7b/#204 status |
|---|---|
| (a) Halt loudly | Closed |
| (b) Silent fall to `model_routing:` | **Reopened** |
| (c) Silent fall to host CLI default | **Reopened** |

**Three surfaces total:**
1. ✅ `trusted_path:` short-circuit (L488) — closed by fix-int-r4-01
2. ❌ `validators:` trusted-model re-run (L499) — uncovered
3. ❌ Missing `model_routing:` block backfill (L514-522) — uncovered

R5-F01 reviewers all converged on Option A: mirror the fix-int-r4-01
pattern (per-H4 fail-loud paragraph + per-H4 vocab pin pair) to surfaces
2 and 3.

## Fix

Three coupled edits in one task. All required.

### Step 1: append fail-loud paragraph to `validators:` H4

In `skills/using-qrspi/SKILL.md`, the `validators:` H4 at L490 currently
ends at L499 with the citation_density_floor bullet. Append (as a new
paragraph immediately after the bullet, before the blank line that
precedes `#### Precedence chain` at L501) the fail-loud paragraph:

> When the validator triggers the trusted-model re-run and the matched agent's frontmatter declares no `model:` field (the state established for all agents after the T9 sweep), the re-run has no concrete target. The dispatcher halts and reports the validator trigger plus the empty agent-bundled default. The dispatcher never falls back silently to `model_routing:` (which the re-run explicitly bypasses) and never passes the re-run through to the host CLI's silent re-routing — both fallbacks would reproduce the G7b/#204 silent-fallback class this hardening release exists to close, one layer deeper than the `model_routing:` and `trusted_path:` paths.

### Step 2: append fail-loud paragraph to `Missing model_routing: block` H4

In `skills/using-qrspi/SKILL.md`, the `Missing model_routing: block` H4
at L512 ends at L522 with the last backfill-behavior bullet. Append (as
a new paragraph immediately after the bullet list, before the blank line
that precedes `#### Model Routing` at L524) the fail-loud paragraph:

> When the in-memory backfill resolves an agent's "bundled default" but the matched agent's frontmatter declares no `model:` field (the state established for all agents after the T9 sweep), the backfill has no concrete value to apply. The dispatcher halts and reports the missing-`model_routing:` condition plus the empty agent-bundled default. The dispatcher never falls back silently to the host CLI's silent re-routing and never substitutes an unannounced model — either fallback would reproduce the G7b/#204 silent-fallback class this hardening release exists to close, one layer deeper than the `model_routing:` and `trusted_path:` paths. The one-time warning above announces the missing block; the halt-and-report on empty step 4 announces the consequence.

### Step 3: append 4 vocab pins to `tests/unit/test-using-qrspi-vocab.bats`

Append at the end of the file (after the last existing @test block — the
new trusted_path: anti-pattern pin added in fix-int-r4-01):

```bash
@test "validators block: fail-loud contract pinned for empty step 4" {
  local body
  body="$(_extract_h4 "$USING" '`validators:` block')"
  # R5-F01 fix (close validators: trusted-model re-run silent-fallback):
  # The validators: H4 documents a trusted-model re-run path that
  # "bypasses model_routing: and dispatches to the agent-bundled default
  # model". Post-T9, the agent-bundled default is empty for every agent.
  # Without a fail-loud rule pinned here, the re-run path reproduces the
  # G7b/#204 silent-fallback class one layer deeper than trusted_path:.
  [[ "$body" == *"halts and reports"* ]]
  [[ "$body" == *"never falls back silently"* ]] || [[ "$body" == *"never fall back silently"* ]]
}

@test "validators block: anti-pattern wording absent" {
  local body
  body="$(_extract_h4 "$USING" '`validators:` block')"
  # R5-F01 fix: pin absence of the anti-pattern wording G7b/#204 was
  # filed against, scoped to the validators: H4 body specifically.
  [[ "$body" != *"silently fall back to the agent-bundled default"* ]]
  [[ "$body" != *"silently degrade"* ]]
}

@test "missing model_routing block: fail-loud contract pinned for empty step 4" {
  local body
  body="$(_extract_h4 "$USING" 'Missing `model_routing:` block in `config.md`')"
  # R5-F01 fix (close missing-block backfill silent-fallback):
  # The Missing model_routing: H4 documents a backfill path that uses
  # "agent-bundled defaults for this session". Post-T9, those defaults
  # are empty for every agent. Without a fail-loud rule pinned here, the
  # backfill path reproduces the G7b/#204 silent-fallback class through
  # a different bypass.
  [[ "$body" == *"halts and reports"* ]]
  [[ "$body" == *"never falls back silently"* ]] || [[ "$body" == *"never fall back silently"* ]]
}

@test "missing model_routing block: anti-pattern wording absent" {
  local body
  body="$(_extract_h4 "$USING" 'Missing `model_routing:` block in `config.md`')"
  # R5-F01 fix: pin absence of the anti-pattern wording scoped to the
  # missing-block H4 body specifically.
  [[ "$body" != *"silently fall back to the agent-bundled default"* ]]
  [[ "$body" != *"silently degrade"* ]]
}
```

**Verify the _extract_h4 helper handles the missing-block H4 label correctly** — the H4 heading text is `Missing \`model_routing:\` block in \`config.md\`` (literal backticks in the heading). The helper at L45 of the same file uses awk substring match on the heading line. If the helper requires escaping for backticks in the pattern, adapt accordingly. Run the new tests in isolation FIRST to confirm the extractor finds the H4 body before adding the assertion logic.

### Step 4: regenerate SKILL.anchors.json

The 2 new paragraphs shift line numbers in SKILL.md. Regenerate the
anchors index:

```bash
bash tools/g4-section-anchor-refresh.sh
```

Verify the regeneration is mechanical (line-count bookkeeping only) by
diffing the before/after — only `line_start` / `line_end` integer values
should change. If any anchor name or text changes, STOP and investigate.

## Wording invariants (for both new paragraphs)

To be pinnable by Step 3's bats tests:
- Contains literal substring `halts and reports`
- Contains either `never falls back silently` or `never fall back silently`
- Does NOT contain `silently fall back to the agent-bundled default`
- Does NOT contain `silently degrade`

## Probes (run after the edits, BEFORE committing)

1. **Both new fail-loud sentences present in their respective H4s:**
   ```
   awk '/^#### `validators:` block/,/^#### Precedence chain/' skills/using-qrspi/SKILL.md | grep -c 'halts and reports'
   awk '/^#### Missing `model_routing:` block/,/^#### Model Routing/' skills/using-qrspi/SKILL.md | grep -c 'halts and reports'
   ```
   Expected: `1` for each.

2. **Anti-pattern wording absent in both new H4 bodies:**
   ```
   awk '/^#### `validators:` block/,/^#### Precedence chain/' skills/using-qrspi/SKILL.md | grep -c 'silently fall back to the agent-bundled default'
   awk '/^#### Missing `model_routing:` block/,/^#### Model Routing/' skills/using-qrspi/SKILL.md | grep -c 'silently fall back to the agent-bundled default'
   ```
   Expected: `0` for each.

3. **All 4 new bats tests GREEN; pre-edit they would RED:**
   ```
   bats tests/unit/test-using-qrspi-vocab.bats
   ```
   Expected: 14/14 passing (10 pre-fix + 4 new).

4. **Full bats suite still green:**
   ```
   bats tests/unit/
   ```
   Expected: 1322/1322 passing (was 1318/1318 at 1df5c97; +4 new).

5. **R4 trusted_path: pins still GREEN (not accidentally broken):**
   ```
   bats tests/unit/test-using-qrspi-vocab.bats -f trusted_path
   ```
   Expected: 2/2 pre-existing pins still green.

6. **Anchors regen is mechanical:**
   ```
   git diff --stat skills/using-qrspi/SKILL.anchors.json
   ```
   Expected: byte-shift in `line_start` / `line_end` values only; no
   structural change to the JSON.

## Commit message

```
integrate(r5): R5-F01 close validators: + missing-block silent-fallback paths

Closes round-05 corroborating findings (3 reviewers, verifier 70/72/80):
- integration-claude R5-F01 (validators: re-run path)
- security-claude R5-F01 (both validators: AND missing-block paths)
- security-codex R5-F01 (corroborates both surfaces)

R4-F01 fixed 1 of 3 surfaces in the post-T9-empty-step-4 silent-fallback
class. R5 reviewers identified the 2 remaining surfaces. Option A fix
(per all 3 R5 reviewers): mirror the R4 per-H4 fail-loud paragraph +
vocab pin pattern to:

1. validators: H4 (SKILL.md:499) — trusted-model re-run path
2. Missing model_routing: block H4 (SKILL.md:514-522) — backfill path

Adds 2 paragraphs to SKILL.md (mirroring the L488 trusted_path: para)
and 4 vocab pins to test-using-qrspi-vocab.bats (2 per H4, mirroring
the L136-159 trusted_path: pin pair). Regenerates SKILL.anchors.json
for the +4 line shift.

The G7b/#204 silent-fallback class is now closed at ALL three reachable
"agent-bundled default" route sites (trusted_path: + validators: re-run
+ missing-block backfill). A future T9-equivalent sweep emptying another
field would still need a 4th fail-loud paragraph; per-H4 mirror pattern
is intentional (each H4 carries its own contract; pin extractor handles
arbitrary H4 labels via _extract_h4).
```

## Out of scope

- Do NOT modify the R4 trusted_path: paragraph at L488 or its pins. They
  correctly cover the trusted_path: branch.
- Do NOT modify the R2 model_routing: paragraph at L470 or its pins.
  They correctly cover the model_routing: failure path.
- Do NOT change the `_extract_h4` helper logic. It accepts arbitrary
  H4 labels per fix-int-r4-01's design.
- Do NOT add a top-level "promoted invariant" (Option B from the R5
  reviewer's suggestions). Per-H4 self-contained pattern is the
  established convention.
- Do NOT add Option C structural changes (deprecate step 4, deprecate
  validators: re-run, etc) — those are v0.7.2+ design discussions.
- Do NOT touch any agent file or config.md.

## Expected output

Three-file diff:
- `+` 2 new paragraphs in `skills/using-qrspi/SKILL.md` (after L499 + after L522)
- `+` 4 new `@test` blocks in `tests/unit/test-using-qrspi-vocab.bats` (appended at end)
- `~` mechanical line-shift in `skills/using-qrspi/SKILL.anchors.json`

Status: DONE / commit SHA / 3 files modified / 1322 tests passing.
