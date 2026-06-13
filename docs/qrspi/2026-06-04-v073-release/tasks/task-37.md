---
status: approved
task: 37
phase: 1
pipeline: full
goal_ids: [G9]
task_type: tdd
tier: medium
---

# Task 37: Create scripts/measure-active-footprint.sh, run it against the trimmed tree, and write g9-footprint-report.md

- **Target files:** `scripts/measure-active-footprint.sh` (Create), `docs/qrspi/2026-06-04-v073-release/g9-footprint-report.md` (Create)
- **Dependencies:** T32, T33, T34, T35, T36
- **LOC estimate:** ~120
- **Description:** A measurement script resolves `!cat` references transitively across the trimmed skill bodies (with cycle detection and named diagnostics — `footprint-snippet-unresolvable:` for an unresolvable `!cat` target, `footprint-snippet-cycle:` for circular `!cat` references), tokenises the resolved content with a pinned tokenizer (default `tiktoken:cl100k_base`), and emits a per-turn footprint count for a typical session (`using-qrspi` + the heaviest active skill + all `!cat`'d shared snippets). The captured stdout becomes the body of `g9-footprint-report.md`, recording the post-trim footprint as the G9 acceptance evidence.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - The script resolves `!cat` references transitively against a fixture skill body where `skill-body` carries `!cat snippet-a.md` and `snippet-a.md` carries `!cat snippet-b.md`: the script's stdout contains the fully-resolved body with both `snippet-a.md` and `snippet-b.md` contents inlined in the expected positions, and the resolved-content fixture's documented token count matches the script's emitted footprint number (test-coverage-codex R9-F01).
  - An unresolvable `!cat` reference surfaces the `footprint-snippet-unresolvable:` named diagnostic and a non-zero exit (no silent skip; coverage-claude F01).
  - A circular `!cat` reference (A `!cat`s B which `!cat`s A) is detected and surfaces the `footprint-snippet-cycle:` named diagnostic and a non-zero exit (cycle detection coverage; coverage-claude F01).
  - Run against the trimmed tree (post-T32-through-T36), the script "shows total per-turn footprint (using-qrspi + heaviest active skill + `!cat`'d shared snippets) below 30K tokens for a typical session" (G9 Acceptance bullet 7, verbatim).
  - Tokenizer-pin verification: a fixture input of known content (e.g., the literal string `"hello world"` plus a longer canonical fixture) tokenised by the script produces a token count matching the documented `tiktoken:cl100k_base` count for that fixture — proves the tokenizer is identity-pinned and not silently substituted by an alternate model that would produce a different token count and a misleading footprint number (coverage-codex R4-F03).
  - The pinned tokenizer binary or library is not installed on the runtime PATH (or the documented `tiktoken:cl100k_base` model file cannot be loaded) — the script halts non-zero with the `footprint-tokenizer-missing:` named diagnostic naming the tokenizer identifier and the resolution path it attempted, before any `!cat` resolution begins; no fallback to a non-pinned tokenizer (test-coverage-claude R6-F01 — the structure.md-enumerated diagnostic surface is reachable in the missing-tokenizer case).
  - The script invoked against a skill name that does not exist under `skills/` (e.g., a typo or removed skill — input asks for `using-qrspi-x` or `removed-skill`) halts non-zero with the `footprint-skill-not-found:` named diagnostic naming the missing skill identifier, before any `!cat` resolution begins; no silent zero-footprint emission for the missing skill (test-coverage-claude R6-F01 — the structure.md-enumerated diagnostic surface is reachable in the missing-skill case).
  - The captured stdout is written to `docs/qrspi/2026-06-04-v073-release/g9-footprint-report.md` (G9 Acceptance bullet 7, final clause).
- **cross_task_consumers:** none
  - **Search proof:** `grep -rn -- 'measure-active-footprint\|footprint-tokenizer-missing\|footprint-snippet\|footprint-skill-not-found' . --exclude-dir=.git --exclude-dir=docs`
  - The proof pattern matches any reference under the repo (outside `.git/` and `docs/`) to either the new script path or any of its four named diagnostics (`footprint-tokenizer-missing:`, `footprint-snippet-unresolvable:`, `footprint-snippet-cycle:`, `footprint-skill-not-found:`). A zero-match result demonstrates no skill body, agent body, script, or test file outside this task's `Target files` set references the new script or its diagnostic surface — the script is a standalone measurement tool with no in-plan consumers. T38 (`tests/lint/test-skill-trim-audit.bats`) depends on T36 (the trim sweep that produces the footprint-evidence target) and not on T37; T38 does not invoke the script. The reviewer re-runs the command from the repo root and treats any non-zero hit as a contract defect requiring the field to be re-shaped to a path list with per-file dispositions.
- **Author Note (defer-to-upstream):** security-claude R05-F02, security-codex R6-F03, and security-codex R7-F04 request a new `footprint-path-traversal:` named diagnostic and an additional guard in the `!cat` resolution loop, rejecting references whose resolved path escapes the repository root (absolute paths, `../` traversals); structure.md § Interfaces — `scripts/measure-active-footprint.sh` enumerates the script's named-diagnostic set as exactly `footprint-tokenizer-missing:`, `footprint-snippet-unresolvable:`, `footprint-snippet-cycle:`, and `footprint-skill-not-found:` (no path-boundary diagnostic), and the `!cat` resolution semantics block in the same § Interfaces entry contracts only the unresolvable-target and cycle-detection guards. Adding a new named diagnostic and a new resolution-loop guard is a scope expansion of structure.md's contracted interface, not a plan-side test-expectation addition. Re-opening requires a Structure-phase amendment per `skills/plan/owns-defers.md` § Upstream-contract deferrals.
