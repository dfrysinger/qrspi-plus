---
created: 2026-05-27
pipeline: full
codex_reviews: true
codex_dispatch_model: gpt-5.3-codex
codex_dispatch_transport: copilot-task-tool
route:
  - goals
  - questions
  - research
  - design
  - phasing
  - structure
  - plan
  - parallelize
  - implement
  - integrate
  - test
verifier_enabled: true
scope_tagger_enabled: true
visual_fidelity_required: false
---

# QRSPI Configuration — v0.7.1 hardening

**Source:** v0.7-milestone bookkeeping audit (2026-05-27). 6 genuine remaining
issues after closing 13 ghosts whose work shipped in PR #182 but whose tickets
were not auto-closed, plus the cross-CLI Codex auto-detection gap (#202) surfaced
at config-time during this run. Goals authoring then surfaced the v0.7 G4
cache-probe spike (#183) as unreachable infrastructure under Copilot CLI and the
silent fallback of all Claude short model names in agent frontmatter; #183 was
superseded by the broader G7a retirement filed as #205, and the model-field
regression was filed as G7b #204. Total scope: 8 issues.

Issues driving this run:

| # | Title | Class |
|---|---|---|
| #42 | F-23: parallelization.md should nest tasks under waves | UX/presentation |
| #175 | `.qrspi-commit-msg.txt` scratch file staged by `git add -A` | bug |
| #185 | T03 dispatcher: replace `grep -P` (PCRE) with portable form | bug |
| #186 | T17 evergreen-markdown scan: clean up pre-existing TBD/TODO violations | prose cleanup |
| #187 | T22 fence-tracking helper not migrated to shared skill-markdown helper | refactor |
| #202 | Cross-CLI Codex auto-detection: skill silently downgrades panel under Copilot/Codex CLI | bug (portability) |
| #204 | G7b: Remove Claude short model names from agent frontmatter (silent fallback under Copilot CLI) | bug (cost regression) |
| #205 | G7a: Retire G4 cache-control mechanism (markers + gate + spike + BATS suites) | cleanup |

**Workspace root:** `~/code/qrspi-plus-v0.7.1/` (fresh clone of `dfrysinger/qrspi-plus@main`,
deliberately outside `~/Library/CloudStorage/Dropbox/` to avoid the cross-agent `.git/`
sync hazard that wiped untracked work in the prior session). Artifacts live in-repo
under `docs/qrspi/2026-05-27-v071-hardening/`.

**Branch model:** `qrspi/v0.7.1-hardening/main` is this run's feature-main branch
(rebased onto `origin/main` at `b977466` during the goals-draft dual-review pass; originally forked from `542023e` before rebase pulled in #200 + #203). Implement will fork task worktrees as
`qrspi/v0.7.1-hardening/task-NN` siblings under the same namespace.

**Review configuration:** `pipeline: full` with `review_depth: deep` and
`review_mode: loop` (the latter two are written by Implement at phase start
per the using-qrspi config schema). User-selected for maximum-coverage plugin
stress test.

**Codex reviews:** ENABLED for this run. The qrspi-plus skill's built-in
auto-detection (`~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs`)
is Claude-Code-specific and returns `false` under Copilot CLI, but Copilot CLI
has Codex as a first-class model accessible via the `task` tool's `model:`
override. For this run, Codex reviewer-slot dispatches use a `code-review`
subagent with `model: gpt-5.3-codex` (the latest Codex generation) instead of
the companion script. Semantics are unchanged — independent GPT-5-class
reviewer running in parallel with the Claude reviewer per the QRSPI
fan-out protocol. The skill's detection gap itself is scoped into G7 of this
release (see goals.md).

**#183 superseded by G7a / #205.** Issue #183 (the v0.7 G4 cache-probe spike against
the live Anthropic API) is dropped from this release: goals.md G7a / #205 retires
the entire G4 cache-control mechanism (the spike script, its report, the dual-flag
gate, and the two BATS pins). No Anthropic-API spike execution is in v0.7.1 scope.
