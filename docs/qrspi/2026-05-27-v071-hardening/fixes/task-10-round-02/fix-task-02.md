# T10 R2 Fix-Task 02 — Restore fail-loud contract + repair trusted_path schema cross-reference

**Round:** 02
**Origin findings:** silent-failure-claude F01 (KEPT @ 72), quality-claude F01 (KEPT @ 82)
**Bundled cleanup:** test-config-model-routing.bats:189 stale `"role lookup"` wording (out-of-scope observation from silent-failure F01, but loud-failing pre-existing pin uncovered by R1 fix landing)
**Target worktree:** `/Users/dfrysinger/code/qrspi-plus-v0.7.1/.worktrees/qrspi-plus-v071/task-10/`
**Branch:** `qrspi/v0.7.1-hardening/task-10`
**Base commit:** `c4173da` (R1 fix tip)
**Task type:** lightweight (doc-only, no production code paths)

## Preamble — scope license

Two independent reviewers (silent-failure-claude + quality-claude) raised distinct KEPT findings on the same artifact (`skills/using-qrspi/SKILL.md`). Both findings turn on the **same underlying Plan-phase scope-gap pattern** the R1 fix preamble already acknowledged: T10's target-file list named `skills/using-qrspi/SKILL.md` for the H4 addition at L511, but the in-skill consumer surfaces of the L448 schema replacement (precedence chain at L494, `trusted_path:` cross-reference at L477, fail-loud invariant template at the deleted `<provider-name>/<model-id>` paragraph) were not enumerated. R1 fixed two of these; R2 surfaces the remaining two. **Sixth instance of the Plan-phase scope-gap pattern in this hardening run** (T4 → implement/SKILL.md; T7 → run-codex-review.sh; T8 → SKILL.anchors.json; T10-R1 → SKILL.md L448/L494; T10-R1 → test-config-model-routing.bats stale assertions; T10-R2 → SKILL.md trusted_path: + fail-loud restoration). Worth filing as a Plan-phase reviewer-hygiene issue post-PR.

All in-scope correctness maintenance — the doc must be self-consistent before merge.

## Out of scope

- Any change to `docs/qrspi/2026-05-27-v071-hardening/config.md` (operator-edited run-instance file; its `model_routing:` table is correctly populated by `1748121`).
- Any code-path or runtime behavior implementation. The fail-loud contract added by Slice 1 is a **documented orchestrator contract** — the SKILL prose IS the contract by existing pattern (cf. the deleted `<provider-name>/<model-id>` sentence and the `Config Validation Procedure` block).
- The `#### Model Routing` resolution-flow section body at L522–545 (correct as-is — R1's authorized addition).
- Any agent file, script, or surface not listed under `target_files`.

## Target files

- `skills/using-qrspi/SKILL.md` (modify — Slices 1 + 2)
- `skills/using-qrspi/SKILL.anchors.json` (regen — Slice 4)
- `tests/unit/test-config-model-routing.bats` (modify — Slice 3a)
- `tests/unit/test-using-qrspi-vocab.bats` (modify — Slices 3b + 3c)

## Slice 1 — Restore fail-loud contract on partial model_routing corruption

**Where:** `skills/using-qrspi/SKILL.md`, end of the `#### \`model_routing:\` block` section (currently ends at L468 with `See \`#### Model Routing\` below for the dispatch-time resolution flow.`).

**Insert after that paragraph, before the next H4 (`#### \`trusted_path:\` block`):**

````markdown
The orchestrator validates these invariants at config-load time and on every dispatch. When `detect_host` returns a host value for which `model_routing:` has no matching top-level key, when an agent's tier name (or the implicit `inherit`) matches no row under the matched host's sub-mapping, or when a tier value is a bare short-form (`haiku`, `sonnet`, `opus`) rather than a fully versioned model ID, the dispatcher halts and reports the missing or invalid entry. The dispatcher never falls back silently to the agent-bundled default and never passes the dispatch through to the host CLI's silent re-routing — both fallbacks would reproduce the G7b/#204 silent-fallback class this hardening release exists to close.
````

**Rationale:** Restores the fail-loud invariant template the R1 schema-replacement deleted. The repair shape matches silent-failure F01's "Option 1" (extend the schema section itself) rather than "Option 2" (add to `Config Validation Procedure` per-field menus) because Option 1 keeps the invariant adjacent to the schema shape that defines it, is symmetric with the pre-R1 fail-loud rule's location, and requires less surface area for the contract to be load-bearing.

## Slice 2 — Repair trusted_path: schema cross-reference

**Where:** `skills/using-qrspi/SKILL.md`, the `#### \`trusted_path:\` block` section (currently L470–484).

**Replace the second bullet under "Entries can be:" (currently `- A role name string (matches entries in \`model_routing:\`).`) with:**

````markdown
- A role name string (matches the `model_role:` value declared in an agent's frontmatter — independent of `model_routing:`'s host-keyed structure).
````

**Rationale:** Per `research/q11-codebase.md` and `skills/implement/SKILL.md:520`, the role-name form of `trusted_path:` matches the agent's `model_role:` frontmatter value, not model_routing keys. The prior coincidence that v0.7's role→provider/model schema had role-keyed entries that LOOKED like the trusted_path's role-name domain was a notation artifact. R1's schema replacement made the cross-reference inarguably wrong. The example `- reviewer` is preserved (still a valid `model_role:` example).

**Constraint:** Existing pin assertions at `tests/unit/test-config-model-routing.bats:90–103` must still pass:
- `"trusted_path: short-circuit semantics documented"` pins `"short-circuit"` (unchanged).
- `"trusted_path: agent-file-path form documented"` pins `agent`+`.md file` OR `agent-file path` (unchanged).
- `"trusted_path: role-name form documented"` pins `"role name"` (case-insensitive); new wording contains `role name` → still passes.

## Slice 3 — Test surface alignment + new fail-loud pins

### Slice 3a — Fix stale precedence-chain pin

**Where:** `tests/unit/test-config-model-routing.bats`, the `@test "role-resolution fallback: ..."` block (currently L187–192).

**Edit:**
- Rename the test to `"precedence-chain co-location: model_routing: host/tier lookup AND agent-bundled default co-located in precedence chain"`.
- Update the body assertion `[[ "$out" == *"role lookup"* ]]` to `[[ "$out" == *"host/tier lookup"* ]]` matching R1's L503 wording.
- Add an inline comment: `# T10 R2 fix (post-R1 schema replacement): step-3 wording is now "host/tier lookup", not "role lookup". This pin was silently passing pre-R2 because of a bats [[ ]] short-circuit quirk; the post-R2 pin asserts the GREEN behavior explicitly.`

**Rationale:** Silent-failure F01's "out-of-scope observation" — assertion was pinned to OLD wording R1 retired but silently passed. Bundling here because it's the same class as R1's L71/L121 fixes, leaving a silently-passing assertion obscures the contract, and the fix is one line.

### Slice 3b — Pin fail-loud sentence presence in vocab pin file

**Where:** `tests/unit/test-using-qrspi-vocab.bats` (the R1 pin file).

**Append a new `@test` block:**

````bash
@test "model_routing block: fail-loud contract pinned for partial corruption" {
  local body
  body="$(_extract_h4 "$USING" '`model_routing:` block')"
  # T10 R2 fix (restore fail-loud contract):
  # The host→tier→model schema announces three structural invariants
  # (host key matches detect_host, four tier rows present, values are
  # fully versioned IDs). The schema doc MUST carry a fail-loud rule
  # naming what the dispatcher does on partial corruption, or the
  # G7b/#204 silent-fallback class reopens one layer deeper.
  [[ "$body" == *"halts and reports"* ]]
  [[ "$body" == *"never falls back silently"* ]] || [[ "$body" == *"never fall back silently"* ]]
}
````

**Rationale:** Load-bearing pin — would catch a future revert. Asserts the two key load-bearing phrases without over-pinning.

### Slice 3c — Pin absence of silent-fallback anti-pattern wording

**Where:** `tests/unit/test-using-qrspi-vocab.bats`, append a second new `@test` block:

````bash
@test "model_routing block: anti-pattern wording absent (no 'silently fall back' / 'silently degrade')" {
  local body
  body="$(_extract_h4 "$USING" '`model_routing:` block')"
  # T10 R2 fix (restore fail-loud contract):
  # Pin the absence of anti-pattern wording G7b/#204 was filed
  # against. If a future edit "softens" the fail-loud rule into a
  # silent-fallback, this pin RED-fails.
  [[ "$body" != *"silently fall back to the agent-bundled default"* ]]
  [[ "$body" != *"silently degrade"* ]]
}
````

**Rationale:** Negative pin paired with Slice 3b's positive pin.

## Slice 4 — Anchor regen

**Run:** `bash tools/g4-section-anchor-refresh.sh`

**Rationale:** Slice 1 adds ~3 lines inside the `#### \`model_routing:\` block` section. The `Config File (config.md)` parent anchor's `line_end` shifts; downstream sections shift by the same delta. Required to keep `tests/unit/test-section-anchor-narrow-read.bats` green.

## Acceptance gate (run before commit)

```bash
cd /Users/dfrysinger/code/qrspi-plus-v0.7.1/.worktrees/qrspi-plus-v071/task-10/

# Full unit suite — must remain green.
bats tests/unit/

# Targeted suites — must all pass.
bats tests/unit/test-config-model-routing.bats
bats tests/unit/test-using-qrspi-vocab.bats
bats tests/unit/test-section-anchor-narrow-read.bats
bats tests/unit/test-agent-frontmatter-no-model.bats

# Load-bearing demonstration: new pins must RED-fail against pre-Slice-1 tree.
git show HEAD:skills/using-qrspi/SKILL.md > /tmp/skill-pre-r2-fix.md
# (Manually verify by inspection that the new Slice 3b + 3c assertions
# would fail against /tmp/skill-pre-r2-fix.md, which lacks the
# fail-loud paragraph and lacks the anti-pattern wording — Slice 3c
# trivially passes against the pre-fix tree (no anti-pattern present
# either way), but Slice 3b's two positive assertions will RED-fail.)
```

## Commit shape

Single commit on `qrspi/v0.7.1-hardening/task-10` using `git commit -F /tmp/msg.txt` (heredoc has known issues with backticks).

## Constraint reminders

- Use `git commit -F /tmp/msg.txt` for the multi-line commit message.
- Report final bats counts and the load-bearing demonstration result.
- Note any deviations from this spec with rationale.
- Do NOT modify `docs/qrspi/2026-05-27-v071-hardening/config.md`, agent files, or any other surface not in `target_files`.
