---
artifact: spec-109
round: 2
reviewer: claude
---

# Spec #109 Review — Round 2 — claude

Spec: `docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md` @ `7997312`
Reviewer scope: NEW issues introduced by the round-1 rewrite, round-1 issues not actually resolved, and issues the rewrite revealed but did not address.

## Summary

- Total findings: 8
- Severity: high=3, medium=4, low=1
- change_type breakdown: correctness=6, clarity=1, scope=1

## Round-1 disposition (not re-emitted)

- **R1-F01 (sequencing breaks main):** addressed by §9's atomic-cutover restructure (step 4). See R2-F01 for residual concern about step 5 split.
- **R1-F02 (Disk-Write Contract drift):** addressed — §2 explicitly REPLACES the existing `## Disk-Write Contract`, redefines the brief-return shape (5 lines), partial-write semantics, and clean-sentinel.
- **R1-F03 (Codex multi-dispatch):** substantively addressed — multi-template Codex sites get per-template reviewer-tag (`codex-<template>` / `scope-codex-<template>`), and crash notes are routed to `<reviewer-tag>.crash.md` directly instead of being splitter input. See R2-F05 for residual fallback concern.
- **R1-F04 (config target file):** addressed — `skills/using-qrspi/SKILL.md` Config-File schema is now the named target.
- **R1-F05 (change_type vocabulary):** addressed — §1 + §2 + §3 all pin to the canonical 5-value enum from `reviewer-protocol/SKILL.md` lines 25/35-36. The 3-vs-2 partition (style/clarity/correctness auto-apply; scope/intent pause) matches.
- **R1-F06 (preserve-content has no real test):** addressed via §4's orchestrator-side preserve guard (pre-dispatch checksum + post-verify re-checksum). See R2-F02 for the heading-truncation flaw and R2-F08 for test-#11's residual self-deluding language.
- **R1-F07 (no test for schema-violation guard):** addressed — test #10 covers it with negative fixtures.
- **R1-F08 (3-retry counter):** addressed — counter dropped, replaced with always-on footer (the round-1 reviewer's own preferred resolution).
- **R1-F09 (synthetic-80 brittleness):** addressed — §3 explicitly switches to "no `## Verifier` block → keep, no synthetic score" branch; the synthetic-80 path is gone everywhere.

## Findings

```
1. finding_id: R2-F01
   severity: high
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: §9 step 5 is a runtime regression risk against step 4. Step 4 is described as the "atomic cutover" that lands the Apply-fix protocol revision (line 381) — which §2 line 99 + §5 lines 297-313 say MUST present the §5 failure menu when any verifier returns VERIFY_FAILED. But step 5 (line 386) explicitly defers "the mutation logic for `verifier_enabled: false` (option 1 of the §5 menu)" to a separate commit, with the parenthetical admission "Could be merged into step 4 if scope allows; kept separate for review-readability." If step 4 ships the menu (because the Apply-fix protocol cites it) but step 5's mutation logic has not yet landed, then between the two commits a user picking option 1 either (a) sees no config.md write happen and verifier_enabled stays true (silent failure of the user's chosen escape hatch), or (b) the protocol language asserts the mutation but the agent has nothing to dispatch. Either way main is not green between commits 4 and 5. Resolution: either move the option-1 mutation logic into step 4 (it is ~5 lines of protocol body — the "review-readability" cost is small), or have step 4 land the protocol revision with the menu explicitly noting "option 1 not yet wired — pick option 2 or 3 for now" and step 5 flips it on. The current language allows the implementer to interpret step 5 as truly post-cutover, which breaks the cutover's atomicity claim.
```

```
2. finding_id: R2-F02
   severity: high
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: §4 preserve-guard's "truncate at first `## Verifier` heading" is ambiguous against legitimate finding content. §4 line 293 specifies: "re-checksums after verifier dispatch by truncating each post-verify file at the first `## Verifier` heading and comparing." But the per-finding `message` body is reviewer-authored prose, multi-paragraph allowed (§2 line 73), and a reviewer can legitimately write a finding that quotes or discusses prior verifier output — e.g., a round-3 reviewer flagging that a round-2 finding was incorrectly auto-applied could embed the literal string `## Verifier` in its message body when discussing the prior round's verifier verdict. The post-verify file would then have TWO `## Verifier` headings (the legitimate body one + the actual appended block). Truncating at the FIRST occurrence yields a too-short prefix, the checksum mismatches, and the dispatcher hard-aborts on a clean verifier write. Resolution options: (a) require the verifier's appended `## Verifier` block to be preceded by a unique sentinel line (e.g., `<!-- verifier-block-boundary -->`) that the reviewer's body content is contractually forbidden to contain; (b) snapshot the entire pre-verifier file content (not just a checksum) and on re-checksum diff the full post-verify file against `<snapshot> + appended-block-pattern`; (c) require verifier output to live in a separate sibling file (`<finding>.verifier.md`) — the original R1-F06 option (b) — eliminating the heading-collision class entirely. Pick one; the heading-match is not unambiguous as written.
```

```
3. finding_id: R2-F03
   severity: high
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: Schema-violation guard does not detect a per-reviewer outage when other reviewers emit normally. §4 line 285 specifies the guard fires when "main chat's step 6 `ls` finds zero `*.finding-*.md` files AND zero `<reviewer-tag>.clean.md` markers AND zero `<reviewer-tag>.crash.md` files for a reviewer the dispatcher expected to run" — note "FOR A REVIEWER", but the actual implementation surface in §3 step 6 is a directory-wide `ls` ("Empty-list-and-no-clean-and-no-crash → fail loud"), not a per-reviewer tally. Concrete failure scenario: claude writes 2 findings, codex writes a clean marker, scope-claude writes a crash file, scope-codex writes NOTHING (silently broke the contract — agent file regression, runtime crash mid-stream that didn't reach the partial-write path, etc.). Directory `ls` returns non-empty (2 finding files + 1 clean + 1 crash), so the dispatcher proceeds. Verifier dispatches against scope-codex's nonexistent output trivially, totals header reports the 2 + 1 + 1 it sees, and the missing scope-codex contribution is silently lost — the user never sees a finding scope-codex would have flagged. Resolution: the guard must be per-expected-reviewer, not directory-wide. The dispatcher needs to know the set of expected reviewer-tags for this artifact step (claude + scope-claude + codex + scope-codex for #109-scope artifacts) and assert each tag has at least one `*.finding-*.md` OR `*.clean.md` OR `*.crash.md` file. Spec must enumerate the per-step expected-reviewer set or add a "for each tag in expected_reviewers" step to §3 step 6 / §4.
```

```
4. finding_id: R2-F04
   severity: medium
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: Splitter missing-delimiter F00 fallback's synthetic frontmatter routes the malformed Codex output through the auto-apply path, defeating its stated audit goal. §2 line 139 + §4 line 289: synthetic frontmatter is `severity: high, change_type: clarity, referenced_files: []`. Body is the raw garbage. Verifier reads nonsense → likely scores 25 (rubric grade c — "almost certainly false positive" — fits a finding with no extractable claim). §3 step 14 then partitions: change_type `clarity` is auto-apply class; score 25 < 80 → DROPPED. Final outcome: malformed Codex output is silently dropped from the round, with only a stderr warning (which main chat does not surface to the user post-/compact). The stated goal "audit captures the malformed Codex output" is met on disk but never reaches the user. Resolution: tag the F00 synthetic finding with `change_type: scope` (or `intent`) so it bypasses the score filter and ALWAYS reaches the pause gate per the §1 filter-ordering rule. The user then sees "scope-codex emitted malformed output" as an actionable pause, which is the correct surfacing for a contract violation. Alternative: route the missing-delimiter fallback through the `<reviewer-tag>.crash.md` path instead of the F00-finding path — same effect, simpler dispatch (crash files already pause-gate per §3 step 14).
```

```
5. finding_id: R2-F05
   severity: medium
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: Empty-stdout-vs-NO_FINDINGS discrimination is documented but not surfaced to the user. §2 line 140 + §4 line 290: the splitter writes a clean marker for both, with a `## Splitter Note` body in the empty-stdout case "treated as clean for apply-fix purposes; flagged in the totals header for human review." But the totals header (§2 step 5: "totals: scored/kept/dropped/failed/clean") does NOT include a "splitter-flagged" or "broken-codex" tally. The "## Splitter Note" body lives inside the clean-marker file which is concatenated into round-NN-verified.md (§3 step 12), but the dispatcher's apply-fix only Reads the verified file and partitions on findings — clean markers carry no findings, so the prose body is never surfaced through the menu or pause gate. A user inspecting round-NN-verified.md WOULD see it, but a typical run flows through dispatch+commit with main chat treating it as clean. Net: a Codex that crashed before producing stdout (but somehow still returned exit 0 to await — e.g., a wrapper bug) registers as a clean round indistinguishable from a real `NO_FINDINGS` emission. Resolution: either (a) add a `splitter_flagged` field to the totals header and have the dispatcher surface findings_count == 0 && splitter_flagged > 0 via the pause gate, or (b) route empty-stdout through the crash.md path (same as await non-zero exit), since empty-stdout from a successful await is itself a contract violation symptom.
```

```
6. finding_id: R2-F06
   severity: medium
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: §2 procedure step 5 ("EXACTLY one of 0/25/50/75/100") has no specified behavior when Haiku returns an off-bucket value. Haiku is a stochastic model; even with the verbatim discrete rubric in the prompt, occasional outputs like `score: 80`, `score: 90`, `score: 65` are plausible (the model sees the threshold "≥80" in the false-positive examples and may anchor on it). Spec does not say what main chat does when the returned score is not in {0,25,50,75,100}. Three possible interpretations: (a) treat as VERIFY_FAILED (failure menu fires — but this is a parsing problem, not a verifier-availability problem, and option 1 "verifier_enabled=false for the run" is a heavyweight escape for a parse glitch); (b) round to nearest bucket (silent — but loses the "≥80 keep" semantics if 80 rounds to 75); (c) accept as-is (but then the "discrete rubric" guarantee in §2 is contractual but not enforced — any future change tightening the threshold to ≥85 has the threshold-vs-bucket aliasing R1-F09 resolution was meant to eliminate). Resolution: explicitly specify one of the three. Recommended: round DOWN to nearest bucket (so 80→75, 65→50) which preserves the conservative-drop semantics, AND emit a stderr/audit note for off-bucket returns to surface model-drift over time.
```

```
7. finding_id: R2-F07
   severity: medium
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: §3 step 11 jump-back semantics are ambiguous against step 7. Step 11 says option 2 "re-dispatches failed verifiers (jump back to step 7)" but step 7 is "Dispatches one Haiku verifier per finding-file path in parallel" — i.e., the unconditional all-parallel dispatch. A literal jump back re-dispatches ALL verifiers (re-running the ones that succeeded), which (a) wastes the successful Haiku spend, and (b) creates a checksum violation on the already-verified files (their `## Verifier` block was appended in the first pass — re-running the verifier writes ANOTHER block, the preserve-guard at step 12 truncates at the FIRST `## Verifier` heading and now the prefix differs from the snapshot, hard abort). §2 step 4 says explicitly "re-dispatches the failed verifiers" (failed only). The two are inconsistent — step 7 must either be re-worded as "Dispatches one Haiku verifier per finding-file path-without-`## Verifier`-block in parallel" (so it is idempotent under retry) or step 11 must say "jump back to step 7 with `--retry` filter restricting to VERIFY_FAILED files." Compounded by R2-F02: the second-pass write would itself trip the heading-collision guard if the first-pass Verifier block were treated as "preceding content." Pick a wording and align step 7 + step 11 + §2 step 4.
```

```
8. finding_id: R2-F08
   severity: low
   change_type: clarity
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: §7 test #11 ("test-preserve-guard.bats", line 352) claims to assert "the dispatcher's hard-abort path is exercised in the protocol language" and "Includes a fixture where a verifier corrupts the preceding content and asserts the dispatcher's hard-abort path is exercised in the protocol language." A bats test that greps the SKILL.md body for protocol prose can confirm the prose says "abort", but cannot drive the dispatcher's actual checksum routine — there is no executable dispatcher being tested. The "fixture where a verifier corrupts the preceding content" sentence implies runtime exercise but the trailing "in the protocol language" caveat negates it. As written, test #11 is a duplicate of test #4's protocol-grep coverage with extra prose wrapping, not a new orthogonal test. This is the same self-deluding pattern R1-F06 flagged on the original "verifier preserves preceding content" test. Resolution: either (a) honestly describe test #11 as a doc-grep test for the preserve-guard prose (and rely on #4 for orchestrator-side coverage), removing the "fixture" and "exercised" language; or (b) make it a real integration test that materializes a fixture round-NN/ directory, runs an actual checksum routine (a small awk/sha helper extracted from the protocol body), corrupts a fixture file, and asserts the helper exits non-zero. Option (b) requires extracting the checksum logic out of pure protocol prose into a callable script — which would also resolve R2-F02 by giving the heading-truncation logic a single canonical implementation to fix.
```

## Notes

- R2-F01, R2-F02, R2-F03 are blocking. The cutover atomicity claim, the preserve-guard's correctness, and the schema-violation guard's per-reviewer scoping are all load-bearing for the design's safety story.
- R2-F02 and R2-F07 interact: solving R2-F02 by introducing a sentinel line ALSO makes R2-F07's idempotent-retry tractable (the dispatcher can detect "already verified" by sentinel presence, not by `## Verifier` heading).
- R2-F04 and R2-F05 are both about Codex contract violations being silently swallowed by the auto-apply path; both have the same resolution shape (route through scope/intent or crash, not through the score-filtered auto-apply class).
- R2-F06 is concrete — Haiku stochasticity is not addressable by spec discipline alone, the parse contract has to specify the round-or-fail decision.
- R2-F08 is a clarity/honesty fix to the test description; not blocking.
