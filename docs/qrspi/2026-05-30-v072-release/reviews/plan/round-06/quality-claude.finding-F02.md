---
reviewer: claude
role: plan-quality-reviewer
round: 6
artifact: plan.md
severity: low
change_type: clarity
finding_id: F02
---

# Finding F02 — Dependency Graph narrative misattributes T39 → T21 rationale

## Location

`plan.md` Dependency Graph section, **L110** (narrative summary paragraph after dep-graph items 1–4):

> "Slice 1.7 is otherwise independent of Slices 1.1–1.6 except that T39 depends on T25 for the defensive-copy site and on T21 for the renamed `scripts/dispatch-agent.sh` path under the `build/` allow-list and `!cat` resolver inspection."

## What's wrong

The narrative claims T39 depends on T21 "for the renamed `scripts/dispatch-agent.sh` path under the `build/` allow-list and `!cat` resolver inspection." But the rename of `run-codex-review.sh` → `dispatch-agent.sh` is **owned by T20** (see L66 task list and L1164 per-task spec header). T21 (G16 path-filter exfil hardening) only modifies the already-renamed file; it does not own the rename itself.

T39's actual round-05 motivation for the new T21 edge is documented in T39's own DoD and test expectation:

- **L2253** (T39 DoD): "The guard mirrors T21's `assert_path_under_repo_root <label> <abs-path>` shape from `scripts/dispatch-agent.sh` (see Task 21 Definition of done — both guards canonicalize with `realpath` / `readlink -f` and reject canonical targets outside canonical `$REPO_ROOT/`)."
- **L2268** (T39 test): "Mirrors T21's symlink-out-of-repo regression in `tests/unit/test-dispatch-agent.bats` so the two canonicalization surfaces use the same audit-friendly diagnostic phrase."

So the T39 → T21 edge exists so T39's symlink-escape guard can **mirror** T21's `assert_path_under_repo_root` shape and `resolves outside repository` diagnostic phrase across the two canonicalization surfaces. The narrative at L110 was not updated when round-05 added T21 to T39's deps and instead pattern-matches to the older "renamed dispatch path" rationale that would imply a T20 dep (which T21 already transitively brings).

This is a low-severity narrative-quality defect, not a deps-field defect: the deps field itself (`[Task 21, Task 25]` at L92 task list and L2210 per-task spec) is correct. The rationale prose just no longer matches.

## Fix

Replace the trailing clause of L110 so the rationale matches T39's own DoD/test:

> "...except that T39 depends on T25 for the defensive-copy site (`build/skills/_shared/prompt-prose-detection.md`) and on T21 so T39's `tools/build-plugin.mjs` symlink-escape guard can mirror T21's `assert_path_under_repo_root` shape and `resolves outside repository` diagnostic phrase across the two canonicalization surfaces (T39's `!cat`-target resolver and T21's `scripts/dispatch-agent.sh` path-filter). T21 transitively brings the T20 rename, so no separate T20 edge is needed."
