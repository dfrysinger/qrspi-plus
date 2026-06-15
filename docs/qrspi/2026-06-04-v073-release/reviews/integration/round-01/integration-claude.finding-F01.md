---
finding_id: F01
severity: blocker
change_type: correctness
reviewer: integration-claude
referenced_files:
  - scripts/orchestration-boundary-check.sh
  - skills/integrate/SKILL.md
  - skills/test/SKILL.md
  - tests/unit/test-orchestration-boundary-check.bats
---

# F01 — `phase-base.txt` format mismatch between OBC script (T19) and Integrate/Test SKILLs (T21/T22)

## Summary

The Phase-End OBC script and the Integrate/Test SKILLs that write its input file disagree on the on-disk format of `reviews/<phase>/phase-base.txt`. As shipped, the OBC step will fire a `sha-format-invalid:` **dispatch defect** on every real Integrate and Test phase, which (per each SKILL's autopilot branch table) **halts the phase unconditionally** with `HALT-orchestration-boundary-undeterminable.md`.

## Evidence

**OBC script — expects bare SHA only.** `scripts/orchestration-boundary-check.sh` reads the file by stripping all whitespace and then validating against `^[0-9a-f]{7,64}$`:

`scripts/orchestration-boundary-check.sh:180-194`
```bash
pbfile="$artifact_dir/reviews/$phase/phase-base.txt"
...
raw="$(tr -d '[:space:]' < "$pbfile" 2>/dev/null || true)"
if [ -z "$raw" ]; then
  add_defect "phase-base-malformed: empty phase-base.txt at $pbfile"
elif ! is_well_formed_sha "$raw"; then
  add_defect "sha-format-invalid: phase-base value '$raw' in $pbfile is not a well-formed git object name (lowercase hex, 7-64 chars)"
```

The OBC unit tests pin exactly this contract — bare SHA:

`tests/unit/test-orchestration-boundary-check.bats:63-65, 230`
```bash
mkdir -p reviews/integration
printf '%s\n' "$PHASE_BASE_SHA" > reviews/integration/phase-base.txt
```

**Integrate SKILL — writes key=value form.** `skills/integrate/SKILL.md` § Phase Start (lines 92–96):

```sh
mkdir -p "<ABS_ARTIFACT_DIR>/reviews/integration"
printf 'integration_base_sha=%s\n' "$(git -C "<repo>" rev-parse HEAD)" \
  > "<ABS_ARTIFACT_DIR>/reviews/integration/phase-base.txt"
```

**Test SKILL — same defect.** `skills/test/SKILL.md` Process Step 1 (line 90):

> `mkdir -p "<ABS_ARTIFACT_DIR>/reviews/test" && printf 'integration_base_sha=%s\n' "$(git rev-parse HEAD)" > "<ABS_ARTIFACT_DIR>/reviews/test/phase-base.txt"`

## Why this is a blocker

`tr -d '[:space:]'` reduces the file contents to the literal string `integration_base_sha=<SHA>` — never lowercase-hex-only. The SHA-shape regex fails on the `integration_base_sha=` prefix, so `add_defect "sha-format-invalid: …"` always fires under `## Dispatch defects`.

Per `skills/integrate/SKILL.md` § Batch Gate autopilot branch (lines 200–202) and `skills/implement/SKILL.md` § Batch Gate autopilot branch 2 (lines 478, 483), a non-empty `## Dispatch defects` section **halts unconditionally** — no auto-revert, no skip-and-continue. The Test SKILL inherits the same halt contract via its own OBC step. The user's Integrate-CI gate cannot be reached on a real autopilot run.

## Suggested resolution

Pick a single contract — the OBC script's bare-SHA shape is already pinned in tests, so the cheap fix is to update the two SKILL `printf` lines:

```sh
printf '%s\n' "$(git -C "<repo>" rev-parse HEAD)" > .../reviews/integration/phase-base.txt
printf '%s\n' "$(git rev-parse HEAD)"            > .../reviews/test/phase-base.txt
```

Alternatively, broaden the OBC parser to also accept `integration_base_sha=<SHA>` (and add a unit-test row), but the prose-side fix is smaller and avoids two parse paths.

## Detection gap

The unit tests for the OBC script use bare-SHA fixtures; the SKILL prose was never exercised against the script in an end-to-end test. A lint or bats-level test that round-trips the actual phase-base.txt prose from `skills/integrate/SKILL.md` and `skills/test/SKILL.md` through `scripts/orchestration-boundary-check.sh` would have caught this. (Same shape as the T24 lint, but covering the SKILL→script contract rather than the SKILL→SKILL contract.)
