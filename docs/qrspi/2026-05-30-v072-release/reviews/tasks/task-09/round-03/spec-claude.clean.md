---
reviewer: spec-claude
round: 3
task: 09
verdict: clean
---

# Spec Review — Task 09 Round 3 — CLEAN

All four R2 fix-cycle issues are addressed correctly and within scope. No new scope overreach detected.

## Issue A — JSON injection (HIGH, convergent security-claude F01 + security-codex F01)

**Required:** (1) Build manifest entry via `jq -n --arg` to prevent injection. (2) Add allowlist validators for `--reviewer-tag` and `--model`. (3) Add a positive JSON-shape assertion to the acceptance suite.

**Verified:**
- `scripts/run-codex-review.sh` lines 210–223: `--reviewer-tag` validator `^[a-z][a-z0-9_-]*$` added; exits 1 with clear diagnostic on mismatch. Matches recommended pattern exactly.
- `scripts/run-codex-review.sh` lines 226–238: `--model` validator `^[A-Za-z0-9][A-Za-z0-9._-]*$` added; exits 1 with clear diagnostic on mismatch. Matches recommended pattern exactly.
- `scripts/run-codex-review.sh` lines 611–617: `emit_dispatch_manifest_entry` replaced `printf -v entry '{"tag":"%s",...}'` with `jq -nc --arg tag … --arg host … --arg vendor "openai-codex" --arg model … '{tag:$tag, host:$host, vendor:$vendor, model:$model}'`. Defense-in-depth pair complete.
- AC9 (`[reviewer-model-audit AC9]`): new acceptance test asserts manifest is well-formed JSON, non-empty array of objects, each entry has **exactly** 4 keys (`tag`, `host`, `vendor`, `model`), and field values match dispatch arguments. Satisfies the fan-in's "add positive JSON-shape assertion" requirement (implemented as a new test rather than updating AC5 inline — outcome is equivalent and more thorough).
- AC10 (`[reviewer-model-audit AC10]`): rejection test with crafted `--reviewer-tag` containing `","` injection payload; asserts non-zero exit, stderr names `--reviewer-tag`, and no manifest written.
- AC11 (`[reviewer-model-audit AC11]`): symmetric rejection test for `--model`; asserts non-zero exit, stderr names `--model`, and no manifest written.

## Issue B — AC5 `|| true` swallowing exit codes (MEDIUM, silent-failure-codex F01)

**Required:** Capture exit code; gate on acceptable codes; if no stable exit-code contract, document acceptable values with explanatory comment.

**Verified:**
- `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`: `|| true` replaced with `|| exit_code=$?` (diff lines 97–98). The manifest-existence check is now load-bearing: a crash **before** the manifest write surfaces as `manifest file not written at $manifest (dispatch exit_code=$exit_code)` with the actual exit code exposed.
- Explanatory comment (diff lines 79–88) documents: no stable launch-failure exit-code contract exists today; if one is established, the block can tighten to an allowlist. This satisfies the fan-in's fallback path ("if no stable contract, document the acceptable codes inline with explanatory comment").
- The T09 invariant is correctly scoped: T09 requires the manifest to be written; a crash after the manifest write (but before codex launch) is out of T09 scope. The implementation correctly reflects this.

## Issue C — AC8 `grep` silently passes on missing files (MEDIUM, silent-failure-codex F02)

**Required:** Add `[ -f ... ]` preconditions before each grep in AC8.

**Verified:**
- `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` (diff lines 364–367): preconditions added verbatim as suggested:
  - `[ -f "$REPO_ROOT/agents/qrspi-finding-verifier.md" ] || { echo "AC8 precondition failed: agents/qrspi-finding-verifier.md missing"; return 1; }`
  - `[ -f "$REPO_ROOT/scripts/verifier-fan-in.sh" ] || { echo "AC8 precondition failed: scripts/verifier-fan-in.sh missing"; return 1; }`
- Both checks appear before the `grep -qF 'verified.md'` calls. ✓

## Issue D — AC7 Case 4 tautological (LOW, code-quality-claude F02)

**Required:** Drop Case 4 or convert to documentation comment (Option A recommended).

**Verified:**
- `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` (diff lines 326–348): Case 4 body removed; replaced by an explanatory comment noting the path is symmetric to Case 2 and a non-tautological case can be added when clean-sentinels are wired into real processing logic. Option A implemented. ✓

## Scope

- No T11/G3-scoped manifest fields introduced. Diff confirms manifest remains `{tag, host, vendor, model}` — the four-field T09 contract.
- Verifier fan-in keep logic unchanged (no changes to `scripts/verifier-fan-in.sh` in diff).
- New tests (AC9, AC10, AC11) are in T09 scope: AC9 pins the manifest shape mandated by the Issue A fix; AC10/AC11 exercise the validators required by Issue A.
- ID-hygiene defer (cq-codex F01 / cq-claude F01) correctly carried to v0.7.3 backlog per prior fan-in disposition; no new T09/T11/G3 token violations introduced.
- All modified files are in the T09 Target files list (`scripts/run-codex-review.sh`, `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`).
