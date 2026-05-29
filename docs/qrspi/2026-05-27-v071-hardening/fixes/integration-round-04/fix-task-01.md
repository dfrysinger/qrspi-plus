---
task_id: fix-int-r4-01
task_type: lightweight
mode: fix
round: 4
artifact: integration
addresses:
  - R4-F01 (security-claude, security, score 70) — trusted_path: short-circuit reopens G7b/#204 silent-fallback class
defers:
  - R4 IC-F01 (tier-orphaning, claude, verifier 68) — dead-schema clarity gap, file as post-PR v0.7.2 issue
  - R4 IC-F02 / ICX-F01 (validation-table cross-link, verifier 35/38) — doc-discoverability polish, post-PR v0.7.2
  - R4 ICX-F02 (mischaracterization of inherit→sonnet collapse, verifier 22) — false positive, no follow-up
references:
  - skills/using-qrspi/SKILL.md (only file to edit in source; H4 at L472-486 for trusted_path: block)
  - tests/unit/test-using-qrspi-vocab.bats (only file to edit in tests; add pin mirroring L112-134)
  - docs/qrspi/2026-05-27-v071-hardening/reviews/integration/round-04/security-claude.finding-F01.md (the finding to close)
---

# fix-int-r4-01: Close trusted_path: silent-fallback under post-T9 empty step 4

## Problem

security-claude R4-F01 (verifier score 70 = KEEP) identified a cross-task
defect that only emerges from combining T9 + T10:

1. **T9 effect (already merged):** Removed `model:` from all 41 agents.
   "Agent-bundled default" (precedence chain step 4 at SKILL.md:506)
   resolves to **nothing** for every agent post-T9.
2. **T10 R2 add:** Fail-loud paragraph at SKILL.md:470 forbids silent
   fallback to agent-bundled default OR host CLI silent re-routing — but
   the surrounding sentences scope the prohibition to the three
   `model_routing:` lookup-failure cases (unknown host, unmapped tier,
   bare short-form value). NOT a global rule.
3. **The gap:** `trusted_path:` short-circuit at SKILL.md:508 reads
   "skips steps 1-3 and routes directly to the agent-bundled default
   (step 4)" — i.e., routes to the very thing R2 forbids elsewhere. The
   contradiction is on-page. Three plausible dispatcher implementations:
   - (a) halt loudly, report empty step 4 → G7b closed
   - (b) silently fall to `model_routing:` → G7b **reopened**
   - (c) silently fall to host CLI default → G7b **reopened**

SKILL.md pins only (a)-equivalent for the `model_routing:` path. The
`trusted_path:` branch is unspecified.

The new vocab pins in `test-using-qrspi-vocab.bats` extract only the
`#### \`model_routing:\` block` H4 body. A future edit that weakens
trusted_path: would not RED-fail any test.

## Fix

Two coupled edits in one task. Both required.

### Step 1: append fail-loud sentence to `trusted_path:` H4

In `skills/using-qrspi/SKILL.md`, the H4 `#### \`trusted_path:\` block`
currently ends at line 486 with:

> `trusted_path:` is documented separately from the precedence chain below because it is a short-circuit, not a step in the chain — matching agents or roles bypass the chain entirely.

Append (as a new paragraph immediately after that line, before the empty
line that precedes the `#### \`validators:\` block` heading) the fail-loud
contract paragraph mirroring R2's wording at L470:

> When `trusted_path:` matches but the matched agent's frontmatter declares no `model:` field (the state established for all agents after the T9 sweep), step 4 has no concrete value to return. The dispatcher halts and reports the trusted_path: match plus the empty agent-bundled default. The dispatcher never falls back silently to `model_routing:` (which `trusted_path:` explicitly bypasses) and never passes the dispatch through to the host CLI's silent re-routing — both fallbacks would reproduce the G7b/#204 silent-fallback class this hardening release exists to close, one layer deeper than the `model_routing:` path.

**Wording invariants the new paragraph MUST satisfy** (to be pinnable by
Step 2's bats test):
- Contains the literal substring `halts and reports`
- Contains either `never falls back silently` or `never fall back silently`
- Does NOT contain `silently fall back to the agent-bundled default`
- Does NOT contain `silently degrade`

### Step 2: add vocab pin extracting trusted_path: H4

In `tests/unit/test-using-qrspi-vocab.bats`, append two new `@test`
blocks at the end of the file mirroring the existing model_routing: pins
at L112-134, but extracting the `#### \`trusted_path:\` block` H4 body
via the same `_extract_h4` helper:

```bash
@test "trusted_path block: fail-loud contract pinned for empty step 4" {
  local body
  body="$(_extract_h4 "$USING" '`trusted_path:` block')"
  # R4-F01 fix (close trusted_path: silent-fallback):
  # Post-T9, agent-bundled default (precedence chain step 4) is empty
  # for every agent. The trusted_path: short-circuit routes directly to
  # step 4. Without a fail-loud rule pinned here, two of three plausible
  # dispatcher implementations reproduce the G7b/#204 silent-fallback
  # class one layer deeper than the model_routing: path.
  [[ "$body" == *"halts and reports"* ]]
  [[ "$body" == *"never falls back silently"* ]] || [[ "$body" == *"never fall back silently"* ]]
}

@test "trusted_path block: anti-pattern wording absent" {
  local body
  body="$(_extract_h4 "$USING" '`trusted_path:` block')"
  # R4-F01 fix (close trusted_path: silent-fallback):
  # Pin absence of the anti-pattern wording G7b/#204 was filed against,
  # scoped to the trusted_path: H4 body specifically. If a future edit
  # softens the trusted_path: fail-loud rule into a silent-fallback,
  # this pin RED-fails.
  [[ "$body" != *"silently fall back to the agent-bundled default"* ]]
  [[ "$body" != *"silently degrade"* ]]
}
```

The `_extract_h4` helper at L45 already accepts any quoted H4 label, so
no helper change is needed.

## Probes (run after the edit, BEFORE committing)

1. **Fail-loud sentence present in trusted_path: H4:**
   ```
   awk '/^#### `trusted_path:` block/,/^#### `validators:` block/' skills/using-qrspi/SKILL.md | grep -c 'halts and reports'
   ```
   Expected: `1`.

2. **Anti-pattern wording absent in trusted_path: H4:**
   ```
   awk '/^#### `trusted_path:` block/,/^#### `validators:` block/' skills/using-qrspi/SKILL.md | grep -c 'silently fall back to the agent-bundled default'
   ```
   Expected: `0`.

3. **New bats tests RED before edit, GREEN after:**
   ```
   bats tests/unit/test-using-qrspi-vocab.bats
   ```
   Expected: all 9 tests pass (7 existing + 2 new). Pre-edit, the 2 new
   tests would RED-fail; post-edit, both GREEN.

4. **Full bats suite still green:**
   ```
   bats tests/unit/
   ```
   Expected: 1318/1318 passing (was 1316/1316 at adb050a baseline; +2
   new tests).

5. **Existing model_routing: pins untouched:**
   ```
   bats tests/unit/test-using-qrspi-vocab.bats -f model_routing
   ```
   Expected: pre-existing 2 model_routing pins still GREEN, proving the
   new pins don't accidentally interfere with the existing extractor.

## Commit message

```
integrate(r4): R4-F01 close trusted_path: silent-fallback for empty step 4

Closes round-04 security-claude finding (verifier score 70): T9 emptied
agent-bundled default (precedence chain step 4) on all 41 agents; T10 R2
added fail-loud paragraph at SKILL.md:470 scoped to model_routing:
failures only; trusted_path: short-circuit at L508 routes "directly to
agent-bundled default" — which is now undefined for every agent, with no
fail-loud contract documented for this path.

Two of three plausible dispatcher implementations (silent fall to
model_routing:, silent fall to host CLI default) would reopen the
G7b/#204 silent-fallback class this hardening release exists to close,
one layer deeper than the model_routing: path.

Fix: append a fail-loud paragraph to the trusted_path: H4 mirroring R2's
wording, plus 2 vocab pins extracting the trusted_path: H4 body and
asserting the same halts-and-reports + never-falls-back-silently
substring pair (and absence of the anti-pattern wording).

Defers: R4 IC-F01 (tier-orphaning dead-schema clarity, verifier 68),
R4 IC-F02 / ICX-F01 (validation-table cross-link polish, verifier 35/38)
to v0.7.2. ICX-F02 (mischaracterization, verifier 22) requires no
follow-up.
```

## Out of scope

- Do NOT modify the `model_routing:` H4 at L470 or its existing pins. R2
  already addressed the model_routing: failure path; this fix closes the
  trusted_path: branch only.
- Do NOT change `_extract_h4` helper logic. It already accepts arbitrary
  H4 labels.
- Do NOT broaden R2's fail-loud paragraph in-place. The mirror-paragraph
  approach (one per H4) keeps each H4's contract self-contained and
  pinnable via its own extractor call.
- Do NOT add T9 reverts or schema changes — the fix is prose + tests.
- Do NOT touch `config.md` or any agent file.

## Expected output

Two-file diff:
- `+` 1 new paragraph in `skills/using-qrspi/SKILL.md` (after L486)
- `+` 2 new `@test` blocks in `tests/unit/test-using-qrspi-vocab.bats`
  (appended at end)

Status: DONE / commit SHA / 2 files modified / 1318 tests passing.
