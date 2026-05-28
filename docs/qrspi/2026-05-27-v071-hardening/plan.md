---
status: approved
phase_start_commit: null
test_writer_model: sonnet
---

# Implementation Plan: qrspi-plus v0.7.1 Hardening

## Project Environment

- **build_command:** none -- pure-script + markdown release; no build artifact produced.
- **dev_command:** none -- no smoke-check server or watch process required for this release; all test surfaces are covered by the existing Lint job and BATS-under-bash-3.2 job in CI.

## Overview

This plan covers a single Phase 1 for the v0.7.1 hardening release: 10 tasks across 8 vertical slices (G1-G7b), all landing together as one coordinated PR. G8 is closed as out of scope per Design DKR11 (the broader subagent-dispatch port is deferred to v0.8).

The 10 tasks follow a dependency chain shaped by three files that are co-modified across multiple slices. `skills/using-qrspi/SKILL.md` is touched by Task 7 (G6 transport prose), Task 8 (G7a cache-field removal), and Task 10 (G7b model-routing prose); those three must execute in that order. `scripts/run-third-party-llm.sh` is touched by Task 1 (G1 detection rewrite) and Task 8 (G7a cache-branch removal); Task 8 must follow Task 1. `tests/unit/test-run-third-party-llm.bats` is co-modified by Task 1 (coverage extension) and Task 8 (assertion removal); same ordering applies. `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` is co-modified by Task 7 (G6 E2E coverage) and Task 8 (G7a SPIKE and run_pin removal); Task 8 must follow Task 7.

**Dependency graph:**

- Tasks 1, 2, 3, 4, 5, 6, 9: no inter-task dependencies; may execute in any order or in parallel.
- Task 7 (G6 SKILL prose + acceptance test): requires Task 6 (host-detection functions must exist before the prose references them and before the acceptance test can exercise them).
- Task 8 (G7a cache retirement): requires Task 1 (co-modifies `run-third-party-llm.sh` and its test suite) and Task 7 (co-modifies `using-qrspi/SKILL.md` and the acceptance test).
- Task 10 (G7b model_routing table + SKILL prose): requires Task 8 (sequencing of `using-qrspi/SKILL.md`) and Task 9 (the structural lint test file created by Task 9 is extended by Task 10).
- Tasks 4 and 9 both touch `agents/qrspi-parallelize-reviewer.md` (Task 4: body prose; Task 9: YAML frontmatter `model:` line). Edits are line-disjoint and will not conflict. Parallelize should treat them as compatible same-wave candidates.

**Slice-to-task mapping:**

- Slice 1 (G1): Task 1
- Slice 2 (G2): Task 2
- Slice 3 (G3): Task 3
- Slice 4 (G4): Task 4
- Slice 5 (G5): Task 5
- Slice 6 (G6): Tasks 6 and 7
- Slice 7 (G7a): Task 8
- Slice 8 (G7b): Tasks 9 and 10

## Phase 1: v0.7.1 Hardening Release

Phase boundary and replan-gate criteria are defined in phasing.md; this Phase 1 section maps each replan-gate criterion to its observable acceptance form.

Ordering rationale: Tasks 1-6 and Task 9 have no blocking dependencies and may dispatch in any order or in parallel. Task 7 follows Task 6. Task 8 follows Tasks 1 and 7. Task 10 follows Tasks 8 and 9.

Task execution order (Parallelize will determine wave groupings):

- Task 1 -- G1: POSIX control-char detection rewrite
- Task 2 -- G2: gitignore scratch commit-message file
- Task 3 -- G3: fence-aware helper promoted to shared library
- Task 4 -- G4: Wave-grouped Branch Map presentation
- Task 5 -- G5: evergreen-lint carve-out removal
- Task 6 -- G6 (part 1): host-detection and Codex availability functions in dispatch helper
- Task 7 -- G6 (part 2): per-host dispatch transport prose in using-qrspi SKILL (depends on Task 6)
- Task 8 -- G7a: cache mechanism retirement (depends on Tasks 1 and 7)
- Task 9 -- G7b (part 1): agent model: field deletion with structural lint coverage
- Task 10 -- G7b (part 2): per-host model_routing table and Model Routing prose (depends on Tasks 8 and 9)

### Phase 1 Acceptance Criteria

Per-phase criteria that must be observable end-to-end at the phase boundary, independent of any single task. All eight trace directly to the replan-gate criteria in `phasing.md`.

- [ ] The existing CI suite (Lint job + BATS-under-bash-3.2 job) passes on the hardening branch with no regressions against the Phase 1 baseline. (G1-G7b -- replan-gate criterion 1)
- [ ] A full pipeline dry-run on a freshly installed copy of the hardening branch emits zero "model not available" warnings across all agent dispatches. (G7b -- replan-gate criterion 2)
- [ ] Codex reviewer dispatches succeed end-to-end on both Claude Code and Copilot CLI hosts using the host-appropriate transport. (G6 -- replan-gate criterion 3)
- [ ] The evergreen-lint scan runs across the full repo with all path carve-outs removed and reports zero violations. (G5 -- replan-gate criterion 4)
- [ ] The control-char detection in the third-party LLM dispatch script correctly triggers the die path on a raw LF byte input without a silent grep fallback under a BSD-grep environment. (G1 -- replan-gate criterion 5)
- [ ] A simulated implementer commit flow confirms the scratch commit-message file is absent from the staged index. (G2 -- replan-gate criterion 6)
- [ ] The fence-aware section-extraction helper exists as a dedicated function in the shared test-helper library, the inline duplicate is removed from the consuming unit suite, and unit coverage pins the helper's behavior including fenced-code blocks. (G3 -- replan-gate criterion 7)
- [ ] The Parallelize SKILL presents its Branch Map grouped per Wave, with reviewer-side guidance and worked-example artifacts updated to match. (G4 -- replan-gate criterion 8)

---

## Task Specs

### Task 1: Rewrite control-char detection to POSIX-clean function in third-party LLM dispatcher

- **Phase:** 1
- **Target files:** `scripts/run-third-party-llm.sh` (modify), `tests/unit/test-run-third-party-llm.bats` (modify)
- **Dependencies:** none
- **LOC estimate:** ~90
- **task_type:** code
- **model:** sonnet
- **goal_ids:** [G1]
- **Description:** The control-char detection routine inside the `openai-chat-completions` security pre-flight block is replaced by a dedicated internal helper function that is POSIX-clean and produces correct results on BSD grep (macOS system grep without PCRE). The replacement catches all 33 control bytes -- the 32 C0 characters (0x00-0x1F) plus DEL (0x7F) -- including LF, which the prior `grep -qP` pattern missed silently. The current `2>/dev/null` suppression that caused the detection to become a no-op when grep lacks `-P` support is eliminated. Every header name and every header value is screened before any network call; any control-character match causes the script to abort with the existing die-path diagnostic naming the offending provider and header. Extended test coverage pins each of the 33 control bytes as a die-path trigger and adds an explicit LF regression guard that would have caught the prior false-negative. The shell-pipeline transport path for Codex dispatch has no configurable `default_headers` surface and is therefore out of scope for this task. Dispatch order: test-writer first, implementer second (RED-verification gate between).
- **Test expectations:**
  - Every C0 control byte (0x00 through 0x1F) supplied as a header value causes the script to exit before reaching any network dispatch call
  - Every C0 control byte supplied as a header name causes the script to exit before reaching any network dispatch call
  - DEL (0x7F) in a header value causes the script to exit before any network dispatch
  - DEL (0x7F) in a header NAME (not just value) causes the script to exit before any network dispatch
  - LF (0x0A / 0x0a) in a header value causes the script to exit -- this is the explicit regression guard for the prior grep gap where LF was silently missed because it is grep's record delimiter
  - NUL (0x00) in a header value causes exit, not a silent skip or binary-mode false negative
  - An empty header name and an empty header value do not trigger the die path (no false positive on empty input)
  - A header containing only printable ASCII characters (0x20 through 0x7E) does not trigger the die path and allows execution to continue
  - A header value containing printable text immediately followed by a control byte (e.g., a value composed of printable ASCII then CR or LF then more printable text, representing a canonical header-injection payload) causes the script to exit before any network dispatch
  - A header NAME containing printable ASCII immediately followed by a control byte then more printable ASCII (canonical name-side injection payload like `Header-Name\r\nInjected`) causes the script to exit before any network dispatch
  - The `_control_char_check` helper is implemented without any `grep -P` invocation (structural code-pattern assertion)
  - The die message identifies the offending provider and header name, matching the existing message format

### Task 2: Add scratch commit-message filename to committed gitignore

- **Phase:** 1
- **Target files:** `.gitignore` (modify), `tests/unit/test-commit-hygiene-invariants.bats` (modify)
- **Dependencies:** none
- **LOC estimate:** ~40
- **task_type:** code
- **model:** sonnet
- **goal_ids:** [G2]
- **Description:** The scratch commit-message file used by the implementer-protocol commit procedure (`.qrspi-commit-msg.txt`) is added to the committed root `.gitignore`. This closes the structural gap where `git add -A` on a fresh clone or worktree stages the scratch file when it happens to exist on disk at staging time, since the prior protection relied on a per-clone `.git/info/exclude` entry that is not present on fresh clones or worktrees. Two new assertions are added to `tests/unit/test-commit-hygiene-invariants.bats`: one verifies the scratch filename appears in the committed `.gitignore`, and one verifies the scratch file is absent from the staged index in a simulated implementer commit flow. The existing `.git/info/exclude` invariant assertions in the same suite are not modified. Dispatch order: test-writer first, implementer second (RED-verification gate between).
- **Test expectations:**
  - The string `.qrspi-commit-msg.txt` appears verbatim in the content of the committed root `.gitignore` file
  - When a scratch commit-message file is present on disk and `git add -A` is executed in a simulated commit flow, the scratch file path does not appear in the resulting staged index
  - The fresh-clone simulation uses a temporary scratch git directory created via `mktemp -d` + `git init` with no `.git/info/exclude` entry for the scratch path; the test asserts the staged-index behavior independently of any per-clone exclude file
  - Existing commit-hygiene invariant assertions in the test suite continue to pass with no changes

### Task 3: Promote fence-aware section extractor to shared test-helper library

- **Phase:** 1
- **Target files:** `tests/helpers/skill-markdown.bash` (modify), `tests/unit/test-skill-md-content-patterns.bats` (modify), `tests/unit/test-helpers-skill-markdown.bats` (modify)
- **Dependencies:** none
- **LOC estimate:** ~110
- **task_type:** code
- **model:** sonnet
- **goal_ids:** [G3]
- **Description:** A new fence-aware section-extraction function (`extract_section_fence_aware`) is added to `tests/helpers/skill-markdown.bash` alongside the existing heading-anchored `extract_section`. The new function correctly handles heading-shaped lines inside code fences; emits a named diagnostic to stderr with a non-zero exit code when extraction is empty (both when the anchor heading is absent and when the anchor is present but no content lines follow); and produces output equivalent to the inline `extract_review_round` helper it replaces. The two call sites of the inline helper migrate to the new shared function and the inline definition is removed. Coverage in `tests/unit/test-helpers-skill-markdown.bats` pins the behavioral contract. Bash-3.2 portable. Dispatch order: test-writer first, implementer second (RED-verification gate between).
- **Test expectations:**
  - The new `extract_section_fence_aware` function returns content from the anchor line (inclusive) through the last line before the next out-of-fence section boundary
  - A `### ` or `## ` heading line that appears inside an open code fence is not treated as a section boundary and does not terminate the extraction
  - Exiting a code fence (closing triple-backtick line) restores heading-boundary detection for subsequent lines in the same extraction
  - When the target section extends to end-of-file with no subsequent section boundary, the function extracts content from the anchor line through the last line of the file
  - For both error paths, the function exits non-zero and emits a single stderr message. The message begins with the literal function-name prefix `extract_section_fence_aware:` (so callers can grep for it) and includes the anchor heading value passed by the caller. The two error paths are distinguishable by message body: the missing-anchor path's message body identifies that the anchor heading was not found; the empty-region path's message body identifies that the anchor was located but no content sat between it and the next heading.
  - A region containing only whitespace (blank lines, spaces, tabs) between anchor heading and next heading triggers the 'no content found' error path (treated as empty).
  - The anchor line itself is included in the function output (consistent with the prior `extract_review_round` contract)
  - Both migrated call sites in `test-skill-md-content-patterns.bats` produce output identical to the prior inline `extract_review_round` output for the same input files
  - Removing the inline `extract_review_round` definition from `test-skill-md-content-patterns.bats` causes no test failures in that suite
  - All pre-existing `extract_section` tests in `tests/unit/test-helpers-skill-markdown.bats` continue to pass with no changes

### Task 4: Reshape parallelize SKILL Branch Map into Wave-grouped sub-sections

- **Phase:** 1
- **Target files:** `skills/parallelize/SKILL.md` (modify), `agents/qrspi-parallelize-reviewer.md` (modify), `tests/unit/test-parallelize-vocab.bats` (modify)
- **Dependencies:** none
- **LOC estimate:** ~120
- **task_type:** code
- **model:** opus
- **goal_ids:** [G4]
- **Description:** The Branch Map content in `skills/parallelize/SKILL.md` is reorganized from a flat three-column table into `### Wave N` sub-sections, each containing a Task/Branch/Base mini-table restricted to the tasks belonging to that wave. This restructuring applies to the artifact specification section and to both the "Good" and "Bad" worked-example pairs in the skill. The now-redundant "Execution Order" prose section, which previously described wave groupings in a separate narrative, is removed from both the specification and the worked examples. `agents/qrspi-parallelize-reviewer.md` is updated so its Branch Map structural-rule assertions require `### Wave N` sub-section grouping rather than the former flat three-column layout; the existing symbolic-base vocabulary rule, row-completeness rule, and Dependency Analysis table rules are retained. `tests/unit/test-parallelize-vocab.bats` gains a new assertion pinning the `### Wave N` sub-section structural rule against the reviewer agent, and existing wave-vocabulary assertions are adapted to reference the new sub-section grouping shape. Dispatch order: test-writer first, implementer second (RED-verification gate between).
- **Test expectations:**
  - `skills/parallelize/SKILL.md` contains `### Wave N` sub-section headings (e.g. `### Wave 1`, `### Wave 2`) as the organizing structure for its Branch Map, with no flat three-column Branch Map table appearing outside a Wave sub-section
  - Each `### Wave N` sub-section contains a Markdown table with exactly three columns: Task, Branch, and Base
  - No `## Execution Order` heading or equivalent standalone wave-order prose block exists anywhere in the artifact specification or worked-example sections of the skill
  - The "Good" worked example in the skill shows Wave-grouped sub-sections and matches the updated specification shape
  - The "Bad" worked example in the skill illustrates the old flat layout (or another anti-pattern) without Wave sub-sections
  - `agents/qrspi-parallelize-reviewer.md` contains a structural rule that requires Branch Map content to be organized under `### Wave N` sub-section headings
  - The new assertion in `tests/unit/test-parallelize-vocab.bats` passes when the reviewer agent file contains the Wave sub-section structural rule and fails (RED) when it is absent
  - Existing symbolic-base-vocabulary and row-completeness assertions in the BATS suite continue to pass

### Task 5: Remove path-shaped exemption groups from evergreen-lint helper

- **Phase:** 1
- **Target files:** `tests/unit/test-evergreen-markdown.bats` (modify)
- **Dependencies:** none
- **LOC estimate:** ~40
- **task_type:** code
- **model:** sonnet
- **goal_ids:** [G5]
- **Description:** All five path-shaped exemption groups (six `case` patterns total) are deleted from the `_is_path_exempt()` function in `tests/unit/test-evergreen-markdown.bats`. The inline `<!-- evergreen-exempt -->` comment mechanism is retained as the sole remaining escape hatch; none of the five pre-existing violations that already carry inline markers are disturbed. After this change the evergreen scan covers its intended surface unconditionally: no directory tree is silently exempted by path. The carve-out removal is validated by the existing evergreen-lint job in CI, which is the design-stated test surface (Design DKR5).
- **Test expectations:**
  - The evergreen scan executed against all repo-tracked markdown files reports zero violations (the five pre-existing violations all carry `<!-- evergreen-exempt -->` inline markers and are suppressed without relying on path carve-outs)
  - The shell function `_is_path_exempt()` in `tests/unit/test-evergreen-markdown.bats` contains zero path-shaped `case` pattern branches after the modification; a structural grep assertion in `tests/unit/test-evergreen-markdown.bats` verifies the absence (fails RED on the current codebase with six branches present, passes GREEN after deletion)
  - The five existing `<!-- evergreen-exempt -->` inline markers remain intact in their original locations after the modification
  - No new violations are introduced by the removal of the carve-out groups (verified by running the scan after the edit)
  - The jargon scan (scoped to `skills/**` and `agents/**`) is unaffected and continues to report zero violations
  - The existing evergreen-lint job in CI reports zero violations after carve-out removal

### Task 6: Implement host-aware Codex availability detection in Codex dispatch helper

- **Phase:** 1
- **Target files:** `scripts/run-codex-review.sh` (modify), `tests/unit/test-host-detection.bats` (create)
- **Dependencies:** none
- **LOC estimate:** ~100
- **task_type:** code
- **model:** sonnet
- **goal_ids:** [G6]
- **Description:** Two new functions are added to `scripts/run-codex-review.sh`: a host-identification function (`detect_host`) that probes the `COPILOT_CLI` environment variable and emits either `copilot-cli` or `claude-code` to stdout (always returning exit code 0 -- a 2-branch probe per DKR6), and a per-host Codex availability check (`check_codex_available`) that returns success under Copilot CLI (where Codex is a natively routable model requiring no filesystem probe) and under Claude Code probes the companion-script glob path. Each dispatch-transport selection path emits a one-line trace marker to stderr at dispatch time: `[transport: shell-pipeline]` when the Claude Code shell-pipeline path is selected, and `[transport: task-tool]` when the Copilot CLI native task-tool path is selected. When the detected host disagrees with the `codex_reviews` config value, the dispatch surface emits a single line to stderr identifying the disagreement, then continues with the configured policy. The mismatch diagnostic does not change exit code or block dispatch. These two functions are the single shared host-probe implementation required by Design DKR10; Task 7 (SKILL prose) and Task 10 (model_routing prose) both reference this implementation. A new unit test file covers both functions under mocked environment signals. Both functions are bash-3.2 portable (no nameref, no `declare -A` outside functions, no `$'...'` ANSI-C strings); the CI bash-3.2 job is the enforcement surface. The transport-marker and mismatch-diagnostic assertions exercise the dispatch-surface helper in `scripts/run-codex-review.sh` (the code path that calls `detect_host` and `check_codex_available` and selects transport); structure.md does not assign this path an explicit function name. Dispatch order: test-writer first, implementer second (RED-verification gate between).
- **Test expectations:**
  - `detect_host` emits `copilot-cli` to stdout and exits 0 when `COPILOT_CLI=1` is present in the environment
  - `detect_host` emits `claude-code` to stdout and exits 0 when `COPILOT_CLI` is unset
  - `detect_host` emits `claude-code` to stdout and exits 0 when `COPILOT_CLI` is set to the empty string (`COPILOT_CLI=""`)
  - `detect_host` emits `claude-code` to stdout and exits 0 when `COPILOT_CLI` is set to a non-empty value other than `1` (e.g., `COPILOT_CLI=0`, `COPILOT_CLI=true`, `COPILOT_CLI=yes`)
  - The 2-branch probe accepts only the literal string `1` as the Copilot CLI signal per design DKR6; all other states (unset, empty, or any non-`1` value) default to Claude Code
  - When `COPILOT_CLI_BINARY_VERSION` is set (to any value) but `COPILOT_CLI` is not `=1`, `detect_host` emits `claude-code` to stdout -- `COPILOT_CLI_BINARY_VERSION` alone is not a host-detection trigger
  - `detect_host` output is determined solely by `COPILOT_CLI`'s value; the presence or absence of other environment variables does not affect the result.
  - `check_codex_available` returns exit code 0 (success) when called with `copilot-cli` as the host argument, without requiring any filesystem path to exist
  - `check_codex_available` returns exit code 0 (success) when called with `claude-code` and the companion-script glob resolves to at least one existing file path
  - `check_codex_available` returns a non-zero exit code when called with `claude-code` and the companion-script glob resolves to no file paths
  - `check_codex_available` called with an unrecognized host argument returns non-zero and emits a single-line diagnostic to stderr identifying the unsupported host value
  - Under a mocked mismatch between `detect_host` output and the `codex_reviews` config value, the dispatch surface emits a single line to stderr that names both the detected host value (e.g., `claude-code`) and the `codex_reviews` config value (e.g., `true`) so an operator can act on the disagreement. The mismatch is a warning signal only -- the mismatch warning does not override the dispatch exit code; the exit code propagated to the caller is the exit code returned by the underlying dispatch, and dispatch is not blocked.
  - When the dispatch surface selects the Claude Code shell-pipeline path (detected host = `claude-code`), `[transport: shell-pipeline]` appears exactly once in stderr and `[transport: task-tool]` is absent (asserted in `tests/unit/test-host-detection.bats`)
  - When the dispatch surface selects the Copilot CLI task-tool path (detected host = `copilot-cli`), `[transport: task-tool]` appears exactly once in stderr and `[transport: shell-pipeline]` is absent (asserted in `tests/unit/test-host-detection.bats`)
  - Neither function writes to stderr under normal (non-error) operation
  - When the dispatch-surface helper (correctly-routed, Codex available) invokes a mocked transport command that exits with a non-zero exit code, the dispatch surface propagates that same non-zero exit code to the caller -- no suppression, no log-and-continue.
  - When the dispatch-surface detects a mismatch (warning emitted) and then invokes a mocked transport that exits with a non-zero exit code, the dispatch surface propagates that same non-zero exit code to the caller. The mismatch warning path does not suppress dispatch failures.

### Task 7: Update using-qrspi skill with per-host Codex dispatch transport routing

- **Phase:** 1
- **Target files:** `skills/using-qrspi/SKILL.md` (modify), `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` (modify)
- **Dependencies:** Task 6
- **LOC estimate:** ~90
- **task_type:** code
- **model:** opus
- **goal_ids:** [G6]
- **Description:** The Codex detection section in `skills/using-qrspi/SKILL.md` is updated to name both dispatch transports explicitly with per-host conditional prose. Under Copilot CLI the dispatch uses the native task tool with `agent_type: code-review` and `model: gpt-5.3-codex`. Under Claude Code the dispatch uses the shell pipeline via `scripts/run-codex-review.sh`. The skill prose documents that when the detected host output disagrees with the `codex_reviews` config value, the dispatch surface (implemented in Task 6) emits a single-line diagnostic to stderr identifying the disagreement and continues with the configured policy; the mismatch diagnostic does not gate dispatch. The acceptance test gains end-to-end host-detection assertions exercising the dispatch surface under mocked conditions for each host path; each assertion verifies the transport-distinguishing trace marker emitted by the dispatch surface (per the trace markers added in Task 6) rather than only a success signal. Dispatch order: test-writer first, implementer second (RED-verification gate between).
- **Test expectations:**
  - `skills/using-qrspi/SKILL.md` Codex detection section contains conditional prose that explicitly names both the Copilot CLI task-tool transport and the Claude Code shell-pipeline transport
  - The SKILL prose specifies `agent_type: code-review` and `model: gpt-5.3-codex` as the parameters for Copilot CLI Codex dispatch
  - The SKILL prose names `scripts/run-codex-review.sh` as the Claude Code Codex dispatch mechanism
  - `skills/using-qrspi/SKILL.md` contains prose documenting that when the detected host disagrees with the `codex_reviews` config value, the dispatch surface emits a single-line diagnostic to stderr identifying the disagreement and continues with the configured policy; the mismatch diagnostic does not gate dispatch
  - With `COPILOT_CLI=1` set, the acceptance test asserts the dispatch surface emits the `[transport: task-tool]` marker to stderr exactly once and does not emit the `[transport: shell-pipeline]` marker (exercising a mocked Codex dispatch via the task tool wrapper)
  - With `COPILOT_CLI` unset and the shell pipeline via `scripts/run-codex-review.sh` mocked, the dispatch surface emits the `[transport: shell-pipeline]` marker to stderr exactly once and does not emit the `[transport: task-tool]` marker
  - When `check_codex_available` returns non-zero for the detected host, the dispatch surface emits a single-line diagnostic to stderr and propagates non-zero exit (no log-and-continue)
  - The acceptance test assertion for the Copilot CLI path passes when `COPILOT_CLI=1` is set and fails (RED) when it is absent
  - The acceptance test assertion for the Claude Code path passes when `COPILOT_CLI` is unset and fails (RED) when the Copilot CLI signal is active
  - For the Copilot CLI path: the mocked task-tool dispatch exits with code 0 and captured stdout contains a distinguishable marker string emitted by the mock transport (a value the mock produces and no other code path produces), proving the dispatch invoked the mock rather than falling back; exit code 0 alone is insufficient proof.
  - For the Claude Code path: the mocked `scripts/run-codex-review.sh` dispatch exits with code 0 and captured stdout contains a distinguishable marker string emitted by the mock transport (a value the mock produces and no other code path produces), proving the dispatch invoked the mock rather than falling back; exit code 0 alone is insufficient proof.
  - When the mocked transport command (correctly-routed, Codex available) exits with a non-zero exit code, the dispatch surface propagates that same non-zero exit code to the caller -- no suppression, no log-and-continue.
  - When the dispatch-surface detects a mismatch (warning emitted) and then invokes a mocked transport that exits with a non-zero exit code, the dispatch surface propagates that same non-zero exit code to the caller. The mismatch warning path does not suppress dispatch failures.

### Task 8: Retire prompt-cache mechanism from dispatcher, skill, and test infrastructure

- **Phase:** 1
- **Target files:** `scripts/g4-cache-probe.sh` (delete), `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` (delete), `tests/unit/test-cache-control-capability-gate.bats` (delete), `tests/unit/test-cache-hit-rate.bats` (delete), `skills/using-qrspi/SKILL.md` (modify), `scripts/run-third-party-llm.sh` (modify), `tests/unit/test-run-third-party-llm.bats` (modify), `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` (modify), `tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats` (create)
- **Dependencies:** Task 1, Task 7
- **LOC estimate:** ~150
- **task_type:** code
- **model:** opus
- **goal_ids:** [G7a]
- **Description:** The prompt-cache mechanism is fully retired: four files are deleted and cache-related content is removed from four modified files. Deleted: `scripts/g4-cache-probe.sh` (the cache-probe script), `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` (the stub spike report), `tests/unit/test-cache-control-capability-gate.bats` (the dual-flag capability-gate unit suite), and `tests/unit/test-cache-hit-rate.bats` (the path-conditional cache-hit-rate suite). Modified: `skills/using-qrspi/SKILL.md` loses `cache_control`, `supports_prompt_cache`, and `emit_cache_control_markers` from the providers block (both the YAML example values and their description bullets); `scripts/run-third-party-llm.sh` loses the `cache_control` marker emission branch from `_dispatch_openai_chat`; `tests/unit/test-run-third-party-llm.bats` loses the four cache-control truth-table assertions that duplicate the deleted capability-gate suite and gains grep-based absence assertions verifying that `cache_control`, `supports_prompt_cache`, and `emit_cache_control_markers` literal strings are absent from `scripts/run-third-party-llm.sh` after modification; `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` loses the `SPIKE` export pointing at the deleted spike report and the two `run_pin` invocations for the deleted unit suites; a new file `tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats` (following the naming pattern of the deleted `test-cache-control-capability-gate.bats`) greps `test-phase1-acceptance.bats` from outside and asserts that no `SPIKE` export and no `run_pin` invocations reference the deleted files, eliminating self-referential grep. The cache mechanism boundary closes atomically across all five surfaces; CI-green is the acceptance gate per Design DKR8. Dispatch order: test-writer first (authors the grep-based absence assertions for `tests/unit/test-run-third-party-llm.bats` and the absence invariants in `tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats`), implementer second (mechanical deletions and SKILL.md prose edits); RED-verification gate between confirms absence assertions fail against the pre-deletion tree. This task is no longer purely mechanical since R2 added net-new test assertions.
- **Test expectations:**
  - `scripts/g4-cache-probe.sh` does not exist in the repository after the task completes (filesystem absence)
  - `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` does not exist in the repository after the task completes (filesystem absence)
  - `tests/unit/test-cache-control-capability-gate.bats` does not exist in the repository after the task completes (filesystem absence)
  - `tests/unit/test-cache-hit-rate.bats` does not exist in the repository after the task completes (filesystem absence)
  - `skills/using-qrspi/SKILL.md` contains no references to `cache_control`, `supports_prompt_cache`, or `emit_cache_control_markers` after modification
  - A new automated assertion in `tests/unit/test-run-third-party-llm.bats` greps `skills/using-qrspi/SKILL.md` for `cache_control`, `supports_prompt_cache`, and `emit_cache_control_markers` and fails if any of the three literal strings is found
  - `scripts/run-third-party-llm.sh` contains no `cache_control` key emission logic after modification; a grep-based absence assertion in `tests/unit/test-run-third-party-llm.bats` verifies that the literal strings `cache_control`, `supports_prompt_cache`, and `emit_cache_control_markers` are absent from `scripts/run-third-party-llm.sh`
  - `tests/unit/test-run-third-party-llm.bats` contains no cache-control truth-table test blocks after modification
  - `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` contains no `SPIKE` variable export referencing the deleted spike file and no `run_pin` invocations referencing the deleted suite files after modification; `tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats` greps `test-phase1-acceptance.bats` from outside to verify these absence conditions, eliminating self-reference
  - After Task 8 modifications, `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` still contains the G6 host-detection acceptance assertions added by Task 7 (specifically, the `COPILOT_CLI=1` Copilot CLI path assertion and the `COPILOT_CLI` unset Claude Code path assertion)
  - The full CI suite (Lint job + BATS-under-bash-3.2 job) passes after all deletions and removals land with no regressions

**Manual Validation:**
- Pre-merge: `git diff --name-only HEAD~1` for the Task 8 commit lists no path under `docs/qrspi/2026-04-29-v0.4-bundle/` or `docs/superpowers/`. Operator-verified; BATS-level git introspection is impractical for this scope.

### Task 9: Remove model: field from all agent frontmatters with structural lint coverage

- **Phase:** 1
- **Target files:** `agents/qrspi-code-quality-reviewer.md` (modify), `agents/qrspi-code-simplifier.md` (modify), `agents/qrspi-design-reviewer.md` (modify), `agents/qrspi-design-scope-reviewer.md` (modify), `agents/qrspi-finding-verifier.md` (modify), `agents/qrspi-goal-traceability-reviewer.md` (modify), `agents/qrspi-goals-reviewer.md` (modify), `agents/qrspi-goals-scope-reviewer.md` (modify), `agents/qrspi-implement-gate-reviewer.md` (modify), `agents/qrspi-implementer-lightweight.md` (modify), `agents/qrspi-implementer.md` (modify), `agents/qrspi-integration-reviewer.md` (modify), `agents/qrspi-parallelize-reviewer.md` (modify), `agents/qrspi-parallelize-scope-reviewer.md` (modify), `agents/qrspi-phasing-reviewer.md` (modify), `agents/qrspi-phasing-scope-reviewer.md` (modify), `agents/qrspi-plan-goal-traceability-reviewer.md` (modify), `agents/qrspi-plan-reviewer.md` (modify), `agents/qrspi-plan-scope-reviewer.md` (modify), `agents/qrspi-plan-security-reviewer.md` (modify), `agents/qrspi-plan-silent-failure-hunter.md` (modify), `agents/qrspi-plan-spec-reviewer.md` (modify), `agents/qrspi-plan-test-coverage-reviewer.md` (modify), `agents/qrspi-questions-reviewer.md` (modify), `agents/qrspi-replan-analyzer.md` (modify), `agents/qrspi-replan-reviewer.md` (modify), `agents/qrspi-replan-scope-reviewer.md` (modify), `agents/qrspi-research-collator.md` (modify), `agents/qrspi-research-reviewer.md` (modify), `agents/qrspi-research-specialist.md` (modify), `agents/qrspi-scope-tagger.md` (modify), `agents/qrspi-security-integration-reviewer.md` (modify), `agents/qrspi-security-reviewer.md` (modify), `agents/qrspi-silent-failure-hunter.md` (modify), `agents/qrspi-spec-reviewer.md` (modify), `agents/qrspi-structure-reviewer.md` (modify), `agents/qrspi-structure-scope-reviewer.md` (modify), `agents/qrspi-test-coverage-reviewer.md` (modify), `agents/qrspi-test-writer.md` (modify), `agents/qrspi-type-design-analyzer.md` (modify), `agents/qrspi-visual-fidelity-reviewer.md` (modify), `tests/unit/test-agent-frontmatter-no-model.bats` (create)
- **Dependencies:** none
- **LOC estimate:** ~90
- **Sizing exception:** schema migration -- 41 agent frontmatter files each receive an identical single-line `model:` key deletion; bundled for atomicity so the no-model-field invariant is established in one commit and the structural lint (written first in RED) can sweep all 41 files in a single pass.
- **task_type:** code
- **model:** opus
- **goal_ids:** [G7b]
- **Description:** The top-level `model:` YAML frontmatter key is deleted from all 41 `agents/qrspi-*.md` files. Tier-name references in dispatcher prose blocks (haiku, sonnet, opus, inherit) within each file are not modified; only the standalone `model:` key in the YAML front matter block is removed. A new structural lint test at `tests/unit/test-agent-frontmatter-no-model.bats` sweeps all files matching `agents/qrspi-*.md` and asserts that no frontmatter carries a top-level `model:` key. The test-writer writes this file in the RED phase (all 41 agents still carry the field, so the test fails); the implementer then removes the field from all 41 files to reach GREEN. The `skills:`, `description:`, `name`, and all other frontmatter fields are unmodified. Dispatch order: test-writer first, implementer second (RED-verification gate between).
- **Test expectations:**
  - `tests/unit/test-agent-frontmatter-no-model.bats` contains a test that sweeps every file matching `agents/qrspi-*.md` and fails if any frontmatter block carries a standalone top-level `model:` key
  - After all 41 agent files are modified, the structural lint test passes with zero violations reported
  - All other frontmatter keys (`skills:`, `description:`, `name:`, and any agent-specific keys) are unmodified
  - The structural lint test fails clearly in RED for each file that still carries a `model:` key, providing a useful per-file failure message

**Manual Validation:**
- Pre-merge: `git diff --stat HEAD~1 -- 'agents/qrspi-*.md'` for the Task 9 commit shows exactly 41 files changed, each with one line removed and zero lines added (verifies that only the `model:` frontmatter line was removed and no body prose was collaterally modified). Operator-verified; BATS-level git introspection is impractical for this scope (mirrors the Task 8 Manual Validation pattern).

### Task 10: Wire per-host model_routing resolution for agent tier names

- **Phase:** 1
- **Target files:** `docs/qrspi/2026-05-27-v071-hardening/config.md` (modify), `skills/using-qrspi/SKILL.md` (modify), `tests/unit/test-agent-frontmatter-no-model.bats` (modify)
- **Dependencies:** Task 8, Task 9
- **LOC estimate:** ~80
- **task_type:** code
- **model:** opus
- **goal_ids:** [G7b]
- **Description:** The `model_routing:` table in `docs/qrspi/2026-05-27-v071-hardening/config.md` is populated with per-host concrete model ID entries covering all four tier names (haiku, sonnet, opus, inherit) for both the `claude-code` and `copilot-cli` host values produced by the `detect_host` function from Task 6. The six versioned tier entries are: claude-code/haiku: `claude-haiku-4.5`; claude-code/sonnet: `claude-sonnet-4.6`; claude-code/opus: `claude-opus-4.7-high`; copilot-cli/haiku: `claude-haiku-4.5`; copilot-cli/sonnet: `claude-sonnet-4.6`; copilot-cli/opus: `claude-opus-4.7-high`. The `inherit` tier resolves to `claude-sonnet-4.6` for both hosts (matching Claude's resolver default for custom agents without explicit `model:`). Copilot CLI accepts fully-versioned Claude model IDs and routes them through its model proxy; using full IDs avoids the "model not available" warning that bare tier names trigger. `skills/using-qrspi/SKILL.md` gains a Model Routing section documenting how dispatcher prose resolves agent tier names against the `model_routing` table: the `detect_host` output selects the per-host column, and the tier name selects the row, yielding the concrete model ID for that dispatch. The structural lint test created in Task 9 is extended with assertions verifying that the `model_routing` table contains the exact required host/tier entries. Dispatch order: test-writer first, implementer second (RED-verification gate between).
- **Test expectations:**
  - `docs/qrspi/2026-05-27-v071-hardening/config.md` contains `claude-haiku-4.5` as the haiku-tier entry in the `model_routing` table for both the `claude-code` and `copilot-cli` host columns
  - `docs/qrspi/2026-05-27-v071-hardening/config.md` contains `claude-sonnet-4.6` as the sonnet-tier entry in the `model_routing` table for both the `claude-code` and `copilot-cli` host columns
  - `docs/qrspi/2026-05-27-v071-hardening/config.md` contains `claude-opus-4.7-high` as the opus-tier entry in the `model_routing` table for both the `claude-code` and `copilot-cli` host columns
  - `docs/qrspi/2026-05-27-v071-hardening/config.md` contains `claude-sonnet-4.6` as the inherit-tier entry in the `model_routing` table for both the `claude-code` and `copilot-cli` host columns
  - No entry in the `copilot-cli` column of the `model_routing:` table is a bare Claude tier short-form (the strings `haiku`, `sonnet`, or `opus` alone) that would trigger a Copilot CLI "model not available" warning
  - `skills/using-qrspi/SKILL.md` contains a Model Routing section that names `detect_host` output as the host-selection input and the `model_routing` table as the per-tier resolution source
  - The extended structural lint assertions in `tests/unit/test-agent-frontmatter-no-model.bats` fail in RED when the `model_routing` table is absent or missing a required host/tier entry, and pass GREEN when all required entries are present

**Manual Validation:**
- Fresh-install smoke check: a freshly installed copy of the plugin on Copilot CLI emits zero "model not available" warnings when an agent dispatch resolves through the `model_routing` table (Design Test Strategy labels this as manual).

---

