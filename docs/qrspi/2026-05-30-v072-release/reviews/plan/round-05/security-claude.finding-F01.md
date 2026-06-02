---
finding_id: F01
severity: high
change_type: scope
location: plan.md → ### Phase 1 Acceptance Criteria → bullet 2 ("Every fail-loud invariant in the release fires loud on a seeded regression input")
---

## AC #2 enumeration still omits T39's build-resolver path-canonicalization exfil guard (parallel to T21, explicitly created in T39 DoD)

### What the plan says

Phase 1 Acceptance Criterion #2 was extended in round-04 to enumerate four new fail-loud invariants (T16 `[second-reviewer-same-vendor]`, T19 `[second-reviewer-unavailable]`, T34 block-hash mismatch, T02 verifier-fan-in halt causes). The leading clause remains universal-quantified: *"Every fail-loud invariant in the release fires loud on a seeded regression input."*

The enumeration as it stands in round-05 covers:

1. splitter on adversarial Codex stdout (T20)
2. dispatch on misrouted `model_routing` entries (T16)
3. validation table on missing `model_routing:` (T17)
4. `_resolve-lib.sh` `tier: none` halt (T16)
5. `_resolve-lib.sh` `[second-reviewer-same-vendor]` halt (T16) — added round-04
6. `second-reviewer-available.sh` `[second-reviewer-unavailable]` halt (T19) — added round-04
7. `plan.md` post-approval split block-hash mismatch halt (T34) — added round-04
8. `scripts/verifier-fan-in.sh` halt causes for five documented malformations (T02) — added round-04
9. reviewer-protocol anti-fabrication output (T35)
10. path-filter exfil guard in `scripts/dispatch-agent.sh` (T21)

### Why this is a Plan-altitude security gap, not an Implement-altitude detail

A release-introduced fail-loud invariant of the **same security class as item 10 (T21)** is missing from the enumeration: **T39's `tools/build-plugin.mjs` path-canonicalization guard**, which Task 39 DoD line 2254 makes explicit (plan.md L2254):

> `tools/build-plugin.mjs` canonicalizes every `!cat` target path with `fs.realpathSync` (or equivalent) BEFORE reading the target's bytes, and fails non-zero with a `resolves outside repository` diagnostic when the canonical path is not lexically prefixed by the canonical `$REPO_ROOT/`. This closes a symlink-escape exfiltration surface where a checked-in `skills/<dir>/<name>.md` symlink could point at `/etc/passwd` or any other path outside the repo and have its contents inlined into a shipped `build/` file. **The guard mirrors T21's `assert_path_under_repo_root <label> <abs-path>` shape from `scripts/dispatch-agent.sh`** (see Task 21 Definition of done — both guards canonicalize with `realpath` / `readlink -f` and reject canonical targets outside canonical `$REPO_ROOT/`).

The plan body itself names the parallel to T21. T39 also carries a per-task regression test for it (plan.md L2269, "Symlink-escape regression"). Yet AC #2 enumerates T21's guard and not T39's, despite their being functionally equivalent fail-loud halts that defend the same exfil class (out-of-repo content inlined into a sanctioned channel).

### Why omission matters at the release boundary

`tools/build-plugin.mjs` is the supply-chain producer — its output `build/` is what every host (Claude Code, Copilot CLI, future Codex CLI) actually loads. A regression that drops `fs.realpathSync` canonicalization (e.g., a future refactor that switches to `path.resolve` only, or a perf-motivated rewrite that skips the boundary check on already-existing files) would:

- Allow any committed-in or maliciously-PR'd symlink under `skills/` whose `!cat` directive references it to inline arbitrary host-side content (`/etc/passwd`, `~/.ssh/`, dotfile secrets, sibling-repo source, etc.) into the shipped plugin tree.
- Ship green through CI because the build itself would still produce a `build/` tree and `git diff --exit-code` would still be empty against the (now-poisoned) committed `build/`.
- Land on every installed host's disk via the marketplace `qrspi` plugin source flip to `./build` (T39 DoD).

This is the same supply-chain exfil class as T21's `dispatch-agent.sh` guard (out-of-repo file content reaching a sanctioned LLM channel), one altitude up: T21 protects per-dispatch reads, T39 protects the build-time inline that defines the runtime contract of every host install.

The leading clause "Every fail-loud invariant in the release fires loud on a seeded regression input" applies, and the asymmetry with T21 (in) vs T39 (out) is internally inconsistent given the plan body's explicit "mirrors T21" rationale.

### What other release-introduced fail-loud invariants remain unenumerated (lower-severity, noted for completeness, not the load-bearing claim)

These are noted so the Plan author can decide whether they belong in AC #2 alongside T39's guard, or whether the gate is intentionally limited to security-critical and apply-fix-pipeline invariants:

- **T20 third-party-finding-splitter additional halt causes**: "missing flags, missing raw output, missing boundaries, or write errors" (plan.md L1203). "Adversarial Codex stdout" in AC #2 likely covers boundary malformation, but missing-flags and write-error failure modes are distinct orchestration halts.
- **T34 missing-header and malformed-header halts** (plan.md L1952–1953, distinct exact diagnostics from the mismatch case AC #2 already enumerates). The pre-G5 migration file and corrupted-header cases are separate halt causes.
- **T12/T13 `round-prepare.sh` SHA validation halts** (exit 10 partial commit provenance, exit 11 worktree HEAD mismatch, exit 12 unadvanced commit; plan.md L761, L827). Exit 11 in particular is review-integrity-relevant: a HEAD-mismatch halt prevents reviewing against the wrong tree.

These secondary items are tier-2; the T39 build-resolver canonicalization guard is the load-bearing security finding of this round.

### Suggested fix (Plan-altitude)

Extend AC #2's operative enumeration with one additional bullet for T39's guard. Suggested wording (mirrors the existing T21 phrasing for symmetry):

> ... and the path-filter exfil guard in `scripts/dispatch-agent.sh` each produce non-zero exit with a diagnostic, **plus `tools/build-plugin.mjs` rejects any `!cat` target whose canonical path resolves outside canonical `$REPO_ROOT/` with a `resolves outside repository` diagnostic before any byte of the target enters the `build/` tree,** never silent fallback.

This is a one-sentence extension that preserves the universal-quantified leading clause, makes the supply-chain build-time exfil surface visible at the release gate, and matches the per-task DoD that already exists. Without it, the round-04 fix's stated goal — making AC #2's universal claim match its enumeration — remains incomplete for the most security-critical invariant in the build pipeline.
