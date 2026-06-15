---
finding_id: F02
severity: blocker
change_type: correctness
reviewer: integration-claude
referenced_files:
  - scripts/orchestration-boundary-check.sh
  - scripts/validate-stage-commit-parents.sh
  - skills/implement/SKILL.md
  - tests/unit/test-orchestration-boundary-check.bats
---

# F02 — Implement-phase wave-1 sidecar: filename and format mismatch between OBC (T19) and stage-merge wrap (T19c/T20a)

## Summary

For `--phase implement`, the OBC script reads `reviews/implement/wave-state/wave-1.txt` parsed as `integration_base: <SHA>` (YAML colon form). But the only writer in the merged tree — `scripts/validate-stage-commit-parents.sh` driven by `skills/implement/SKILL.md`'s Wave Dispatch fence — writes `reviews/implement/wave-state/W{N}.sidecar` parsed as `integration_base=<SHA>` (key=value form). The filename, the path-glob, AND the separator all differ. Consequence: the OBC step in `skills/implement/SKILL.md` § Step N writes `wave-1-sidecar-missing:` under `## Dispatch defects` on every real Implement-phase run, which halts unconditionally per the autopilot branch table.

## Evidence

**OBC — expects `wave-1.txt` with YAML-colon shape.** `scripts/orchestration-boundary-check.sh:158-176`:

```bash
sidecar="$artifact_dir/reviews/implement/wave-state/wave-1.txt"
if [ ! -r "$sidecar" ]; then
  add_defect "wave-1-sidecar-missing: expected wave-1 sidecar at $sidecar"
...
raw="$(awk -F'[[:space:]]*:[[:space:]]*' '$1=="integration_base"{print $2; exit}' "$sidecar" ...)"
```

Pinned by `tests/unit/test-orchestration-boundary-check.bats:240-246`:

```bash
mkdir -p reviews/implement/wave-state
printf 'integration_base: %s\ntask_tips:\n' "$PHASE_BASE_SHA" \
  > reviews/implement/wave-state/wave-1.txt
```

**Stage-merge wrap — writes `W{N}.sidecar` with key=value shape.** `scripts/validate-stage-commit-parents.sh:104-175`:

```bash
wave_state_dir="$repo_root/reviews/implement/wave-state"
...
sidecar="$wave_state_dir/$wave_id.sidecar"
...
printf 'integration_base=%s\n' "$base"
printf 'task_tip_shas=%s\n' "$tips_value"
```

Implement SKILL drives that wrap with `--wave-id W{N}` per `skills/implement/SKILL.md:162-171`:

```sh
scripts/validate-stage-commit-parents.sh --capture --wave-id W{N} \
    --task-branch qrspi/{slug}/task-AA ...
```

so the file on disk after Wave 1 is `reviews/implement/wave-state/W1.sidecar`, not `wave-1.txt`.

**Implement SKILL invokes the OBC at phase end.** `skills/implement/SKILL.md:470`:

> run `scripts/orchestration-boundary-check.sh --phase implement --artifact-dir "<ABS_ARTIFACT_DIR>"`

The script then immediately hits the `[ ! -r "$sidecar" ]` branch and records `wave-1-sidecar-missing:` under `## Dispatch defects`.

## Why this is a blocker

Three independent gaps stack:

1. **Filename:** `wave-1.txt` vs `W1.sidecar`.
2. **Separator:** OBC's awk is `-F'[[:space:]]*:[[:space:]]*'` matching `integration_base:`. T19c writes `integration_base=` (equals sign). Even if the filename matched, the awk match would miss and the value would be empty → `wave-1-sidecar-malformed:`.
3. **Wave-1 vs Wave-N coupling:** Even if both sides agreed on `W1.sidecar`/equals, the OBC only ever reads Wave 1's file — but `--capture` is only invoked when a wave needs a stage commit. A phase whose Wave 1 is fan-out only (no stage commit) produces no `W1.sidecar` at all; subsequent waves' sidecars live at `W2.sidecar`, `W3.sidecar`, etc. and are never consulted.

Per `skills/implement/SKILL.md` § Batch Gate autopilot mode branch 2 (line 483): "**Dispatch defects (`## Dispatch defects` non-empty).** Halt unconditionally (same halt file). No auto-revert, no operator override, no skip-and-continue."

So Implement's phase-end gate halts every real run; Integrate cannot be reached. This composes with F01 to break two of the three phase boundaries the OBC was added to monitor.

## Suggested resolution

Either side can move; the contract is what matters. Options ordered by minimum-change:

1. **Add a dedicated Implement-phase phase-base writer to `skills/implement/SKILL.md`.** Mirror the Integrate/Test § Phase Start pattern: as the first orchestrator action of the Implement phase, write `reviews/implement/phase-base.txt` as a bare SHA, and either (a) widen OBC to also accept that file under `--phase implement` (preferred — keeps T19c's sidecar schema unchanged) or (b) repoint `--phase implement` to read the new `phase-base.txt` instead of the wave-state sidecar (drops the dependency on T19c's runtime output entirely).
2. **Bridge in the wrap:** have `validate-stage-commit-parents.sh --capture` also emit a `wave-1.txt` in the OBC's expected shape when `--wave-id W1`. Carries the schema-divergence forward, but is a one-line addition.
3. **Reshape the sidecar to OBC's contract:** change T19c to write `integration_base: <sha>` to `wave-1.txt` for Wave 1. Risk: T19c's existing schema (`task_tip_shas`, validate-mode parser) is already shipped and pinned by its own bats — touching it broadens blast radius.

## Detection gap

`tests/unit/test-orchestration-boundary-check.bats` exercises the OBC against synthetic `wave-1.txt` fixtures; `tests/unit/test-validate-stage-commit-parents.bats` exercises T19c against synthetic `W{N}.sidecar` fixtures. No test reads `validate-stage-commit-parents.sh --capture`'s real output and feeds it to `orchestration-boundary-check.sh --phase implement`. A small end-to-end bats that runs `--capture --wave-id W1 ...` then `orchestration-boundary-check.sh --phase implement` and asserts `## Dispatch defects` is empty would have surfaced both the filename and the separator mismatch.
