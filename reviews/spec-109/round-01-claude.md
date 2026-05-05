---
artifact: spec-109
round: 1
reviewer: claude
---

# Spec #109 Review — Round 1 — claude

Spec: `docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md`
Reviewer scope: design verification against the actual repo state at `eea2c6e`.

## Summary

- Total findings: 9
- Severity: high=4, medium=4, low=1
- change_type breakdown: correctness=6, scope=2, clarity=1

Grouped by topic below.

## Internal Consistency / Migration Sequencing

```
1. finding_id: R1-F01
   severity: high
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md, skills/using-qrspi/SKILL.md]
   message: §9 step ordering breaks main between commits. Step 3 ("Reviewer agent file migrations in batches of ~5") flips reviewer agents from emitting `round-NN-{reviewer}.md` (single file) to per-finding files in `round-NN/<reviewer>.finding-F<NN>.md`. Step 6 ("Apply-fix protocol revision in `using-qrspi/SKILL.md`") is the migration that teaches main chat to read `round-NN-verified.md` instead of per-reviewer files. Between landing step 3 and landing step 6, main chat is still executing the current Apply-fix protocol at `using-qrspi/SKILL.md` line 518+, which `ls reviews/{step}/round-NN-*.md`s and Reads per-reviewer files that no longer exist (because reviewers now write to a `round-NN/` subdir). Any QRSPI run on main between those commits hard-fails. Migration must either (a) sequence step 6 before/concurrent with step 3 (apply-fix learns to read both shapes during the transition, then drops the legacy reader after step 3 lands), (b) ship steps 3 and 6 atomically in one commit, or (c) introduce a temporary compatibility shim. The spec's claim "migration is reversible at any step before step 6" (line 288) is true in the trivial sense that step 6 is the schema flip — but it ignores that steps 3-5 already break the runtime. Add the inter-step compatibility plan or re-order.

2. finding_id: R1-F02
   severity: high
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md, skills/reviewer-protocol/SKILL.md]
   message: Per-Finding File Contract conflicts with the existing Disk-Write Contract at `skills/reviewer-protocol/SKILL.md` lines 131-173 without acknowledging or amending it. The existing contract mandates: (a) "The dispatching skill provides an absolute output path … under a clearly-labeled field" (singular file), (b) the file format is a single multi-finding markdown with `# {Step} review — round NN — {reviewer-tag}` heading + `## Summary` + `## Findings`, (c) the brief return value must be exactly the four-line shape including `Written to: reviews/{step}/round-NN-{reviewer-tag}.md` (singular), and (d) `WRITE_FAILED:` is the only sanctioned failure return. The spec adds a new `## Per-Finding File Contract` section but never says the existing `## Disk-Write Contract` is replaced/amended, never updates the brief-return shape (now N files instead of one — does the reviewer return N "Written to:" lines? a single dir path? an enumeration of finding IDs?), and never updates the failure-return contract for partial-write failures (some finding files written, others failed). §2 line 115 says the brief return "lists the finding IDs and the round-NN/ directory path" — which directly contradicts the prescribed four-line return shape. The spec must either rewrite `## Disk-Write Contract` (and update its associated test `tests/unit/test-reviewer-disk-write.bats` if any) or explicitly carve out the per-finding case as a new contract that supersedes it.

3. finding_id: R1-F03
   severity: high
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md, skills/_shared/codex/launch-await-pattern.md, skills/implement/SKILL.md, skills/integrate/SKILL.md, skills/test/SKILL.md]
   message: Codex `<<<FINDING-BOUNDARY>>>` integration is underspecified for the multi-dispatch sites. The spec (§2 "scripts/codex-finding-splitter.sh", §9 step 4) describes the splitter as a single-file post-processor of one Codex stdout. But Codex is dispatched at multiple sites with different shapes:
   (a) `skills/implement/SKILL.md` lines 446 and 619 — one Codex per task per round (ok, single splitter call works).
   (b) `skills/integrate/SKILL.md` line 203 — "round-NN-{template}-codex.md" — multiple templates, multiple awaits, different output filenames.
   (c) `skills/test/SKILL.md` line 244 — same per-template multi-Codex shape.
   (d) The launch-await-pattern at `skills/_shared/codex/launch-await-pattern.md` line 33 vs 43 has both single-dispatch and multi-dispatch variants — both must be amended.
   (e) Non-zero Codex exit codes (10/11/12 at `launch-await-pattern.md` line 33) cause main chat to write explicit ceiling/crash/audit-fail notes to the per-round Codex file. Those notes are NOT findings, lack the `<<<FINDING-BOUNDARY>>>` delimiter, and have no `finding_id`/`severity`/etc. Per §4 "missing-delimiter" handling the splitter would dump the entire crash note as a single coarse `codex.finding-F00.md` and the verifier would attempt to score it — not the desired audit shape. The spec must specify: how the splitter is invoked at each multi-dispatch site, how the per-template suffix flows into the per-finding filename (`<scope>-codex-<template>.finding-F<NN>.md`?), and how the splitter detects "this is a ceiling/crash note, not a finding stream" so it skips emission rather than inventing fake findings.

4. finding_id: R1-F04
   severity: medium
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md, skills/using-qrspi/SKILL.md]
   message: Spec §2 line 82-91 references `skills/{config}/SKILL.md` for the `verifier_enabled` schema addition. There is no `skills/config/` directory and no `skills/{config}/SKILL.md`. The actual config schema lives in `skills/using-qrspi/SKILL.md` §"Config File (config.md)" at line 339+. The spec must specify the actual file to amend. The §9 step 5 ("config.md schema update") inherits the same ambiguity. Test #7 at §7 ("`verifier_enabled` field is documented in the config skill") then has no concrete target file to grep. Fix: replace `skills/{config}/SKILL.md` with `skills/using-qrspi/SKILL.md` and align test #7's grep target.

5. finding_id: R1-F05
   severity: medium
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md, skills/reviewer-protocol/SKILL.md]
   message: change_type vocabulary mismatch: the spec's §2 false-positive examples and §3 dispatch description allude to the QRSPI 5-field schema but the existing `skills/reviewer-protocol/SKILL.md` line 25 fixes the change_type values as `style|clarity|correctness|scope|intent`. The spec's per-finding example at line 188 uses `change_type: correctness` (valid), but the spec never explicitly aligns the example schema with reviewer-protocol's fixed enum; readers writing the verifier or splitter against this spec might interpret §2's "wording" / "altitude" / per-skill style language as new permitted values. Tighten by quoting the 5-value enum verbatim from `reviewer-protocol/SKILL.md` and asserting the per-finding YAML conforms exactly. (This is also load-bearing for the score≥80 dispatch in §2 step 7: that dispatch routes on `change_type`, not score, so any new tag would silently fall through.)

## Test Coverage Gaps

```
6. finding_id: R1-F06
   severity: high
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: §4 line 213 + §7 test #1 admit the gap explicitly: "verifier preserves preceding content" is "surfaced via a unit test on the verifier agent file body." A bats test that greps `agents/qrspi-finding-verifier.md` for instruction text can only confirm the string exists — it cannot enforce that a Haiku subagent at runtime actually preserves the preceding content. A misbehaving verifier that overwrites the finding object with just `## Verifier` would corrupt the audit trail (irreversible — no other copy of the finding exists post-#109 because per-reviewer files are gone) and the bats test would still pass. This is the highest-impact failure mode the design introduces and has no real test. Mitigation options: (a) integration test that runs the verifier against a fixture finding file and diffs pre/post, asserting the prefix is byte-identical; (b) make the verifier emit a sibling `<file>.verifier.md` instead of appending to the source file (eliminating the overwrite class entirely — but doubles the splitter/assembly cost); (c) add an orchestrator-side guard at the assembly step that checks each per-finding file for a non-empty pre-`## Verifier` body and aborts if missing. Pick one and document.

7. finding_id: R1-F07
   severity: medium
   change_type: scope
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: §7 has no test for the §4 "reviewer-side schema-violation guard" ("if main chat's step-4 `ls` finds zero per-finding files but a per-reviewer summary file exists, main chat fails loud"). This is the migration safety net for R1-F01 (in-flight legacy reviewers). With no test, the loud-failure language can rot during migration. Add a test asserting `using-qrspi/SKILL.md`'s Apply-fix step body cites the legacy-shape detection and the explicit failure message.

8. finding_id: R1-F08
   severity: medium
   change_type: scope
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: §7 has no test for the §5 "3-retry message" timing. Test #5 asserts the message is "present" but not that it appears specifically after 3 consecutive option-2 picks. The retry counter's scope is also unspecified (round-scoped? run-scoped? cleared on option 1 toggle?). Add either a state-machine test or, simpler, drop the 3-retry counter entirely and make the message always-on as a footer. (The 3-retry counter has scope-creep risk — it requires either persisting state in `config.md` or threading it through the orchestrator's transcript memory; the spec ducks both.)

## Per-Finding File / Verifier-Disabled

```
9. finding_id: R1-F09
   severity: low
   change_type: clarity
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: §3 line 201 + §2 step 7 specify that verifier-disabled findings are treated as `score: 80, reason: verifier-disabled`. With `≥80` as the keep threshold, this means "default-keep" — equivalent to pre-#109 behavior. The spec calls this out (line 201) and it is intentional. However, the choice of exactly 80 (the threshold itself) is brittle: if the threshold ever moves to ≥85 (e.g., a future tightening) the disabled-mode default would silently flip from keep to drop. Make the disabled-mode behavior an explicit branch ("if verifier_enabled=false: keep all findings; do not score") rather than an implicit synthetic score. The spec already has the explicit branch at §3 step 5 ("If false: jump to step 9 with all findings kept (no scoring)"), but §3 step 13 / §2 step 7 reintroduce the synthetic-80 path for the "verifier_enabled=true, but the file has no `## Verifier` block" case (e.g., a verifier silently failed without returning `VERIFY_FAILED:`). Decide one path and document it consistently.
```

## Items Verified Clean (no findings)

The following claims in the spec were verified against the repo and are correct:

- **§2 affected-file enumeration (32 files).** Counted 9 artifact-quality + 7 scope + (1 plan-quality + 5 plan-artifact) + 8 per-task implementation + 1 implement-gate + 1 security-integration = 32. All 32 files exist at the documented paths under `agents/qrspi-*.md`. The `silent-failure → qrspi-plan-silent-failure-hunter.md` parenthetical is correct.
- **§2 worker-exclusion list (5 files).** `qrspi-implementer.md`, `qrspi-test-writer.md`, `qrspi-research-specialist.md`, `qrspi-research-collator.md`, `qrspi-replan-analyzer.md` all exist and none emit findings (replan-analyzer's only `find` mention at line 32 is "fix history, and review findings" as input, not output).
- **§2 subagent-write-blocklist claim.** `<reviewer-tag>.finding-F<NN>.md` does not match `^(REPORT|SUMMARY|FINDINGS|ANALYSIS).*\.md$`. Confirmed — finding starts with the reviewer-tag, not the blocklist tokens.
- **§2 /code-review faithful-copy claim.** Read `~/.claude/plugins/cache/claude-plugins-official/code-review/unknown/commands/code-review.md` step 5 (lines 20-25). The 0/25/50/75/100 grade definitions and the "give this rubric to the agent verbatim" prefix language are reproducible verbatim. The per-finding-parallel dispatch pattern (one Haiku per finding) at step 5 is also accurately characterized. The ≥80 threshold at step 6 matches the spec's threshold.
- **§6 cost-discipline math.** ~50K Haiku-billed tokens/round at N=8 with 5K artifact + 500-token findings is plausible; $0.04/round at Haiku 4.5 input rates is order-of-magnitude correct.
- **#110 dependency.** Confirmed PR #110 (subagents in agent files) is at `eea2c6e` on main; `agents/qrspi-*.md` files exist and `skills:` frontmatter delivery is in place.

## Notes / Dispositions

- F01, F02, F03, F06 are blocking — the design cannot ship cleanly without addressing them.
- F04, F05, F07, F08 are concrete fixes — small wording / target-file / test additions.
- F09 is design-clarity tightening, not a blocker.
- R1-F01 and R1-F02 are partially overlapping — both relate to the migration cutover but address different surfaces (sequencing vs contract drift). Treat them as separate fixes.
