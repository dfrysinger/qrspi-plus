---
finding_id: R4-F01
severity: low
change_type: correctness
referenced_files: [scripts/run-codex-review.sh]
artifact: task-06/scripts/run-codex-review.sh
round: 4
reviewer: sf-claude
persistence_note: orchestrator-persisted (reviewer chat-only fallback)
normalized_change_type: original was "incomplete-fix", normalized to "correctness" per closed enum
---

**Title:** sf.F02 partially resolves — internal compose_prompt failures silently yield exit-0 pipeline despite pipefail

**Location:** `scripts/run-codex-review.sh:483-497` (compose_prompt), 587-592 (dispatch subshell)

The R3 fix wraps both dispatch branches in `( set -o pipefail; compose_prompt | bash "$DISPATCHER" ... )`. With `pipefail` active, if `compose_prompt` exits non-zero, the pipeline exits non-zero and `exit "$?"` propagates the failure correctly.

**Remaining gap:** `compose_prompt` runs with `set -e` **off** (line 50–51: `# NOT -e`). Inside the function each step is a plain sequential command — `strip_frontmatter`, `cat`, `printf`, `emit_dispatch_parameters`. If any intermediate command fails (e.g., file becomes unreadable mid-composition — TOCTOU race, NFS timeout), bash does not abort the function. Execution falls through to `emit_dispatch_parameters`, which succeeds, so `compose_prompt`'s exit status is **0**.

With `pipefail` enabled in the outer subshell, a pipeline failure is detected; but `compose_prompt` exiting 0 means the pipeline exit status equals the dispatcher's exit code. If the dispatcher accepts a truncated prompt and exits 0, the overall dispatch returns 0 — a **silent failure carrying a malformed/partial prompt to the reviewer model**.

The new test `[r3-sf.F02]` is structural only: `grep -q 'set -o pipefail' "$WRAPPER"`.

**Fix:** Inside `compose_prompt`, either (a) use `set -e` locally via `( set -e; ... )`, or (b) check each step's exit status with explicit `|| { ...; exit 1; }`.
