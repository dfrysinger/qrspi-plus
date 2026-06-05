---
finding_id: F01
reviewer: security-claude
model: claude-sonnet-4.6
round: 6
task: 11
severity: low
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh:913-927
---

# security-claude — task-11 round-06 — F01 (LOW)

**`_fp_tmp` (first-party prompt tmpfile) has no signal-cleanup trap.**

## Summary

The first-party dispatch path creates `_fp_tmp` via mktemp (FIX-A made this symlink-safe), but installs no INT/TERM trap to delete it on signal. The assembled prompt file can persist indefinitely, containing subject code and task definition of the artifact under review.

## Concrete attack scenario

1. Attacker has local account on the dispatch machine with `kill` permission on the dispatch process (e.g., same-user access, or world-writable process namespace).
2. Script enters the copilot-cli path at line 901, creates `_fp_dispatch_dir=$OUTPUT_DIR/.dispatch/` (via `mkdir -p`, inheriting ambient umask — commonly 022, so the directory is world-readable on many systems).
3. mktemp succeeds, `_fp_tmp` is set to `$_fp_dispatch_dir/$REVIEWER_TAG.prompt.tmp.XXXXXX`.
4. `compose_prompt > "$_fp_tmp"` begins (line 918) — this concatenates reviewer-protocol SKILL.md, additional skill SKILLs, the agent body, the emission override, and all `--subject-code` / `--artifact-body` files into `_fp_tmp`. For a large artifact, this runs for seconds.
5. Attacker sends SIGINT to the process during step 4 using `kill -INT <pid>`.
6. Script exits (SIGINT default action or shell exit on untrapped INT — the script has `set -u` but no INT trap at this scope). `_fp_tmp` is **not removed**.
7. Orphaned file `$OUTPUT_DIR/.dispatch/$REVIEWER_TAG.prompt.tmp.XXXXXX` persists. It contains the partially or fully assembled prompt, including the unredacted subject code of the artifact under review.
8. Attacker reads the file. For a security review, the subject code may contain pre-fix vulnerabilities, proprietary logic, or secrets.

## Why `_fp_tmp` is not self-cleaning

A subsequent dispatch run with the same `$REVIEWER_TAG` will `mv -f` a new `.tmp.XXXXXX` file to `$REVIEWER_TAG.prompt` (line 923) but will not touch any other `.tmp.XXXXXX` files — so the orphan persists until manual cleanup.

## Comparison to FIX-H

FIX-H applied exactly this fix to `_manifest_tmp` — adding `_manifest_tmp` as a script-level relay and including `rm -f "$_manifest_tmp"` in the INT/TERM/EXIT traps. The manifest JSON contains dispatch metadata (model, host, job IDs). The prompt tmpfile contains subject code, which is typically higher-sensitivity content. The mitigation pattern is already established in this script; `_fp_tmp` simply lacks the equivalent relay+trap wiring.

## Severity rationale

LOW — requires local access and process-kill permission; random mktemp suffix means the attacker must list the directory (needing read access to `.dispatch/`); the attack window is bounded to the execution of `compose_prompt`. Elevated slightly relative to `_manifest_tmp` (FIX-H was also rated LOW) because the content is subject code rather than JSON provenance metadata.

## Disposition note

**Pre-existing, not a R6 regression.** This gap existed before R6; FIX-A (R5) made `_fp_tmp` symlink-safe but didn't add signal cleanup. R6's FIX-H established the relay+trap pattern for `_manifest_tmp` and revealed the symmetric gap for `_fp_tmp`.

## Suggested fix

Mirror the `_manifest_tmp` pattern: declare `_fp_tmp=""` at script scope, set it after mktemp succeeds, install `trap 'rm -f "$_fp_tmp" 2>/dev/null || true' EXIT INT TERM` immediately after, and clear + disarm on every exit path (mv success, mv failure, compose_prompt failure).

## Note

Reviewer returned chat-only; orchestrator persisted this finding verbatim.
