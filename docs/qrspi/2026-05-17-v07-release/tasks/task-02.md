---
task: 2
status: approved
pipeline: full
task_type: code
model: sonnet
phase: 1
goal_ids: [G2]
dependencies: []
loc_estimate: 140
sizing_exception: reusable primitives
---

# Task 02: Extract shared prompt-utils library for vendor-agnostic dispatch

- **Phase:** 1
- **Target files:**
  - `scripts/lib/llm-prompt-utils.sh` (Create) — sourced shell library exposing prompt-composition helpers reused by every third-party-LLM dispatch site.
- **Dependencies:** none
- **LOC estimate:** ~140
- **Sizing exception:** reusable primitives
- **Description:** Creates `scripts/lib/llm-prompt-utils.sh` as a sourced bash library carrying the prompt-composition utilities previously inlined in `scripts/run-codex-review.sh`, refactored to be vendor-agnostic so both the new universal dispatcher (T03) and the retired codex shim (T04) source the same helpers. The library exposes the three prompt-composition helpers (frontmatter stripping, untrusted-data marker-collision guarding, dispatch-parameter emission) per the `scripts/lib/llm-prompt-utils.sh` interface contract documented in structure.md — function names, parameter shapes, and exit-code semantics are owned by structure.md and not duplicated here. The library is bash 3.2 portable (no `mapfile`, no `declare -A`, no `${var,,}`, no `coproc`, no `wait -n`), uses loud diagnostics on every failure path, and refuses to execute when invoked as a script rather than sourced (named diagnostic to stderr, exit 1).
- **Test expectations:**
  - `strip_frontmatter` on a file with a leading `---` frontmatter block emits only the body that follows the closing `---` marker.
  - `strip_frontmatter` on a file with no frontmatter emits the file body unchanged.
  - `guard_marker_injection` exits 0 on a file containing no untrusted-data sentinel markers and exits 1 with a named-marker stderr diagnostic when a collision is present.
  - `emit_dispatch_parameters` produces one `key=value` line per input pair in a stable order suitable for diffing across runs.
  - Sourcing the file under bash 3.2 succeeds and exports the three named functions.
  - Invoking the file as a script (rather than sourcing) prints a named diagnostic to stderr and exits 1.
