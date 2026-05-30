---
artifact: integration
round: 6
reviewer: integration-claude
status: clean
hotfix_b_thresholds:
  correctness_security_keep: 70
  clarity_style_keep: 80
---

# Integration review round 06 — clean

## Scope

Round-06 diff is the single fix-int-r5-01 commit (229-line focused delta):

- `+` 2 paragraphs in `skills/using-qrspi/SKILL.md` (L501 validators: H4; L526 missing-block H4)
- `+` 4 `@test` blocks in `tests/unit/test-using-qrspi-vocab.bats`
- `~` mechanical line-shift in `skills/using-qrspi/SKILL.anchors.json` (+4 lines propagated through all dependent ranges)

Prior T8/T9/T10 + R4 + R5 fix work was reviewed in rounds 01–05 and is unchanged.

## Evidence by focus area

### 1. All three R5-F01 surfaces closed

The post-T9 "empty agent-bundled default" silent-fallback class is now covered at every dispatch contract surface in SKILL.md:

| Surface | Line | Contract status |
|---|---|---|
| `trusted_path:` short-circuit | L488 | closed (R4 fix) |
| `validators:` trusted-model re-run | **L501** | **closed (R5 fix, new)** |
| Missing `model_routing:` block backfill | **L526** | **closed (R5 fix, new)** |

Both new paragraphs match the spec verbatim and carry the identical anchor pair the R4 paragraph established: `"halts and reports"` + `"never falls back silently"`, with explicit enumeration of which bypass paths are forbidden. Each paragraph identifies its own depth ("one layer deeper than the `model_routing:` and `trusted_path:` paths") so a reader at any single H4 can locate the structural context.

### 2. No additional "agent-bundled default" routing surfaces require coverage

Grep audit of every occurrence of "agent-bundled default" in SKILL.md:

- **L422** — framing prose introducing all four routing blocks. Says "their absence means dispatch falls back to agent-bundled defaults." Not a per-dispatch contract; per-H4 contracts at L470/L488/L501/L526 govern. Could be cosmetically refined in a future round but does not reopen the silent-fallback class.
- **L470** — `model_routing:` invariant fail-loud (R2). Closed.
- **L474, L512** — descriptive/cross-reference prose, no contract.
- **L488, L501, L526** — the three closed contracts above.
- **L499, L518** — anti-pattern context paragraphs paired with their respective fail-loud contracts.
- **L510** — abstract step-4 definition inside the precedence chain. Not a contract.

Every site that names a *dispatch routing decision* now carries the halt-and-report contract.

### 3. The 4 new vocab pins are load-bearing

Deletion test: removing either L501 or L526 would strip `"halts and reports"` from the corresponding extracted H4 body, RED-failing the positive assertion in both that H4's tests. The anti-pattern assertions additionally catch the more subtle softening-regression vector (replacing fail-loud prose with the documented anti-pattern wording).

### 4. `[ -n "$body" ]` safety net interacts correctly with `_extract_h4`

Verified the helper at `tests/unit/test-using-qrspi-vocab.bats:45–66`. Failure modes:

- Heading not found → stderr write + return 1, stdout empty
- Heading found, body empty → stderr write + return 1, stdout empty

In bash, `local body="$(_extract_h4 …)"` discards the subshell exit status because the `local` builtin's own 0 status takes precedence. Without the safety net, a helper failure would set `body=""` silently, and the *negative* assertions `[[ "$body" != *"silently fall back…"* ]]` would evaluate TRUE on an empty string — silently passing the regression they exist to catch.

The implementer's `[ -n "$body" ]` precondition catches this before reaching the substring check. The inline comment in the missing-block test correctly documents the specific risk (multi-word + backticked H4 label vulnerable to extractor-regression silent-pass).

For the H4 label `` Missing `model_routing:` block in `config.md` ``: the awk script at L49–60 uses `$0 == target` string equality, which treats backticks as literal characters. The heading at SKILL.md:L514 matches exactly. No escaping needed; the safety net documents the regression risk should that ever change.

### 5. Safety-net asymmetry is a low-grade follow-up, not a round-06 finding

The R5 pins (4 new) include the safety net; the R2 pins (L112–134) and R4 pins (L136–159) do not. If a future regression broke the H4 label *and* the anti-pattern wording for `model_routing:` or `trusted_path:` simultaneously, the anti-pattern pins would silently pass. This is a two-fault scenario; the current H4 labels match and the extractor is correct.

Self-scored as a clarity observation at ~65 → KILL under Hotfix B clarity threshold (≥80). Worth surfacing as a one-line note for a future R7+ pin author: adopt the safety-net pattern uniformly, and consider retrofitting the R2/R4 pins during the next bats touch. Not a fix-this-round requirement.

## Cross-cutting integration checks

- **Cross-task consistency:** the two new paragraphs use the identical contract vocabulary as the L488 R4 paragraph, with structural language ("one layer deeper than…") that locates each contract within the same precedence-chain class. No vocabulary drift.
- **Interface mismatches:** none. The 4 new bats tests use the existing `_extract_h4` helper interface unchanged; the helper's contract (return non-empty stdout on success, empty stdout + return 1 on failure) is honored by the safety net.
- **Data flow correctness:** the H4-label → awk-match → body-extraction → substring-assertion path is end-to-end verified for both new labels.
- **Integration test coverage:** the 4 new pins are themselves the cross-boundary tests for the prose↔contract integration; the boundary they cross is "SKILL.md prose stays load-bearing for the silent-fallback class".
- **Duplicate/conflicting implementations:** none. The R5 paragraphs mirror the R4 structure deliberately (per spec) — not duplicate logic but parallel contract statements at distinct dispatch surfaces.
- **Dependency ordering:** SKILL.anchors.json regen is mechanical (+4 line shift propagated consistently); no structural change. Verified by inspecting the diff: every dependent range from L549 onward shifts by exactly +4.

## Verdict

Clean. All three R5-F01 surfaces in the post-T9 silent-fallback class are closed. The implementer's `[ -n "$body" ]` safety net is a load-bearing defensive addition correctly scoped to the higher-risk new H4 labels. No findings rise to Hotfix B keep thresholds.
