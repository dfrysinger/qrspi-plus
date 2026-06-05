# Spec Reviewer (claude) — Task 39 / Round 1 — CLEAN

No findings. The implementation matches the task-39 spec on completeness,
scope, interpretation, test coverage, target-file alignment, and TDD evidence.

## Verification highlights

- **Resolver (tools/build-plugin.mjs)**: strict whole-line bare-relative
  grammar (L100-102), absolute/`..`/realpath canonicalization with the
  T21-mirroring `resolves outside repository` diagnostic (L113-145),
  transitive expansion + cycle detection with full cycle printed
  (L150-154), CR stripping (L156), `${CLAUDE_SKILL_DIR}` post-expansion
  guard (L193-201), pre-flight outside-root guard for .md sources to
  catch symlink-SKILL.md escapes (L250-269).
- **Build tree present** at `build/` with `agents/`, `scripts/`,
  `skills/`, `templates/`, `.claude-plugin/`, `LICENSE`, `README.md`,
  `AGENTS.md`. No `build/docs/`, `build/tools/`, `build/tests/`,
  `build/reviews/`, or `build/CONTRIBUTING.md` (verified by directory
  listing).
- **`tools/render-skill.sh`** and **`tools/g4-section-anchor-refresh.sh`**
  exist at the new paths; old `scripts/` paths confirmed absent by the
  paired bats invariants (test-cache-retirement-invariants.bats
  L297-306).
- **marketplace.json**: `source: "./build"`, `version: "0.7.2"` (diff
  L9-12).
- **plugin.json**: `version: "0.7.2"` (diff L24-25).
- **CI workflow**: single workflow; `bats -r tests` recursive (ci.yml
  L60-65); build-sync gate runs `node tools/build-plugin.mjs` followed
  by `git diff --exit-code build/ .claude-plugin/marketplace.json`
  (ci.yml L67-83); no Actions auto-commit step. Lint + ban-list both
  walk `tests/` recursively now (ci.yml L40-44, L49-53).
- **CONTRIBUTING.md**: documents the edit→build→add→commit→push
  workflow, the two PR-blocking failure modes, the committed-`build/`
  rationale (atomic source/build diffs, one-revert rollback, git blame
  across the seam), and the `scripts/` (runtime) vs `tools/` (dev-time)
  split.

## Transparency-note adjudications (per dispatch context)

1. **`--exclude-dir=tests` added to two greps in
   test-cache-retirement-invariants.bats L314, L319** — Legitimate
   test-bug fix, not assertion weakening. The bats file itself contains
   the literal strings `scripts/render-skill.sh` and
   `scripts/g4-section-anchor-refresh.sh` in adjacent `@test` names and
   in negative-existence assertions on the same legacy paths
   (L297-306). Without the `tests/` exclusion the grep would
   self-trigger on its own bytes regardless of source-tree state. The
   remaining grep surface (`scripts/`, `agents/`, `skills/`,
   `templates/`, `.claude-plugin/`, root markdown) is the runtime/source
   surface the assertion is meant to police. The test comment
   (L309-313) was updated to document the additional exclusion and the
   reason. Approved.

2. **Pre-built `build/` tree (133 files) committed atomically with
   source** — Matches spec direction. Task-39 Overview frames this as
   "turns the source repo into a committed `build/` install artifact";
   marketplace.json's `source` field flips to `./build`; CONTRIBUTING's
   new "Why `build/` is committed" section codifies the
   atomic-source/build-diff invariant. Approved.

## Advisory observation (non-blocking)

The resolver uses an exclusion-based strip list (`STRIP_TOPLEVEL`,
build-plugin.mjs L60-76) rather than a strict include whitelist. This
ships `build/PROVENANCE.md`, which is not in the task's enumerated
"fixed runtime include list" but is reasonable authorship metadata
adjacent to LICENSE/README and is not dev-only. The task spec language
combines a descriptive runtime list with an explicit dev-only
omission list ("omitting dev-only paths including docs/, tools/,
tests/, and review/work artifacts"); the strip-list implementation
satisfies the omission half and includes everything else, which is a
defensible reading. Not flagged as a finding.
