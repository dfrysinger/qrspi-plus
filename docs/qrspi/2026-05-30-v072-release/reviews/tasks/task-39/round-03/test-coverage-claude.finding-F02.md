---
reviewer: test-coverage-claude
finding_id: F02
severity: medium
change_type: correctness
references:
  - tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats#L309-L321
  - docs/qrspi/2026-05-30-v072-release/tasks/task-39.md#L51
  - docs/qrspi/2026-05-30-v072-release/tasks/task-39.md#L66
---

# F02 — Caller-reference grep excludes `docs/`, so it cannot verify "callers/docs/references are updated"

## Observation

Task 39's Definition of Done (line 51) and Test Expectations (line 66)
require:

> `tools/render-skill.sh` and `tools/g4-section-anchor-refresh.sh` exist
> at their new paths; `scripts/render-skill.sh` and
> `scripts/g4-section-anchor-refresh.sh` no longer exist;
> **callers/docs/reference sites are updated**.

The two assertion tests in `test-cache-retirement-invariants.bats`
(lines 309–316, 318–321) execute:

```bash
grep -RF \
  --exclude-dir=build --exclude-dir=docs --exclude-dir=reviews \
  --exclude-dir=.git --exclude-dir=fixtures --exclude-dir=tests \
  'scripts/render-skill.sh' "$REPO_ROOT" || true
```

The `--exclude-dir=docs` and `--exclude-dir=tests` knobs mean the
assertion is structurally **incapable** of verifying the "docs are
updated" half of the spec. A stale `docs/qrspi/.../structure.md`
section that still names `scripts/render-skill.sh` will not trip this
test even though the spec says docs must be updated.

`tests/` exclusion is partially defensible (RED-test names may
legitimately reference the old path in @test strings), but `docs/`
exclusion has no such carve-out — any doc still referencing the old
path is a real regression that this test must catch.

## Impact

A future contributor who deletes the migration but forgets to update
docs/structure.md, docs/CONTRIBUTING.md, or any plan/goals doc will
pass this gate. The release ships with stale operator/contributor
guidance pointing at scripts/ paths that no longer exist.

## Suggested remediation

Drop `--exclude-dir=docs` and either:

1. Allow-list specific historical doc files that legitimately mention
   the old path (e.g., release notes recording the migration), OR
2. Tighten the grep to lines that *invoke* the old path (e.g.,
   `bash scripts/render-skill.sh`, `\$REPO_ROOT/scripts/render-skill.sh`),
   so historical narrative prose like "Task 39 moved
   scripts/render-skill.sh to tools/" doesn't trip the gate.

Option 2 is preferred: it preserves migration-history references while
catching live invocation sites. Example:

```bash
grep -RnE 'bash[[:space:]]+(\$\{?REPO_ROOT\}?/)?scripts/render-skill\.sh|source[[:space:]]+(\$\{?REPO_ROOT\}?/)?scripts/render-skill\.sh' \
  --exclude-dir=build --exclude-dir=reviews --exclude-dir=.git \
  --exclude-dir=fixtures --exclude-dir=tests \
  "$REPO_ROOT" || true
```
