---
reviewer: security-claude
phase: integrate
round: 02
findings: 0
---

# Cross-task security integration review — no findings

No blocker/high/medium cross-task security vulnerabilities identified in
the merged code for v0.7.3 Phase 1 round-02 (stage-W7 tip `28dee59`
on `qrspi/v0.7.3/main`). The two round-01 integration fixes (F01,
F02) were re-traced against the surfaces they touch; the original six
cross-task security surfaces from round-01 were re-confirmed against
the broadened diff and remain clean.

## Round-02 focus surfaces

### A. Fix-F01 — `phase-base.txt` now bare SHA (Integrate / Test SKILLs)

`skills/integrate/SKILL.md` and `skills/test/SKILL.md` § Phase Start
now emit:

```sh
printf '%s\n' "$(git rev-parse HEAD)" > .../reviews/<phase>/phase-base.txt
```

instead of the previous `printf 'integration_base_sha=%s\n' ...` form.
Reader contract: `scripts/orchestration-boundary-check.sh:180-194`
strips whitespace (`tr -d '[:space:]'`) and validates against
`SHA_REGEX='^[0-9a-f]{7,64}$'` (obc:51) BEFORE any `git` invocation
consumes the value (commit walk at obc:240+).

Cross-task injection analysis:

- **Input source.** The SHA is produced locally by `git rev-parse HEAD`
  on the orchestrator's worktree — never a user-supplied or
  network-supplied string. No new input channel is created by the
  format change.
- **Smaller parse surface, not larger.** The previous key=value form
  required the reader to consume `integration_base_sha=<sha>` after
  whitespace-strip. The new bare form has strictly fewer parse states.
  The 7..64-char lowercase-hex regex is unchanged and unchanged in
  position (still runs before any git command reads the value), so the
  fix monotonically reduces attack surface rather than expanding it.
- **No new injection sink reached.** Even a hypothetical adversarial
  `phase-base.txt` (e.g. operator commits a poisoned file) still has
  to pass `SHA_REGEX`. The regex output is then fed only to
  `git log <sha>..HEAD` / `git rev-list <sha>..HEAD` (obc commit-walk
  block), which are SHA-shape-safe sinks. No shell metacharacters
  survive the regex.
- **No symmetry gap with the writer.** Both Integrate and Test SKILLs
  apply the same bare-SHA format; the OBC `integration|test` branch
  reads them identically. No cross-task disagreement remains.

**No finding.** F01's chosen direction (move writers to bare SHA) is
the smaller-blast-radius option and introduces no injection path the
previous key=value form prevented.

### B. Fix-F02 — `validate-stage-commit-parents.sh --seed-wave-1-obc`

New mode at `scripts/validate-stage-commit-parents.sh:196-204`. The
Implement SKILL orchestrator invokes it as the first action of Wave 1
when Wave 1 is fan-out only (no stage commit), to seed
`reviews/implement/wave-state/wave-1.txt` so the OBC's implement-phase
batch gate (obc:158-176) has the `integration_base:` line it reads.

Cross-task analysis against the six standard surfaces:

- **Access control / privilege escalation.** The mode writes ONLY to
  `<wave-state-dir>/wave-1.txt`, where `wave-state-dir` is derived
  from `--artifact-dir` (orchestrator-owned absolute path) or
  `--wave-state-dir` (same). No new role, scope, or capability is
  granted; no new auth gate is added or removed. The fan-out-only
  Wave 1 path was previously fail-safe (OBC fired
  `wave-1-sidecar-missing:` and halted); now it has a controlled seed.
  No path through `--seed-wave-1-obc` reaches a privileged operation
  the orchestrator could not already perform.
- **Input validation.** `--integration-base <SHA>` is validated by
  `validate_sha` (vscp:144-150) — identical regex
  `^[0-9a-f]{7,64}$` to the OBC reader — BEFORE `write_wave_1_obc`
  runs (vscp:201-202). Empty value rejected explicitly at vscp:197-200
  with the `--seed-wave-1-obc requires --integration-base <SHA>`
  diagnostic. No path lets a non-hex value reach the printf body or
  the OBC reader.
- **Injection across task boundary.** The orchestrator->script->OBC
  chain is: orchestrator computes `git rev-parse HEAD` (trusted local
  command) → passes as `--integration-base` (validated by
  `validate_sha`) → printf'd as `integration_base: <SHA>` into
  `wave-1.txt` (atomic mktemp+mv at vscp:170-186) → OBC re-validates
  with the same regex before any git invocation. Both ends validate;
  no "Task A trusted Task B to validate" gap exists.
- **Race / shared state.** `wave-state-dir` is wave-scoped under the
  orchestrator's artifact tree. The seed mode runs synchronously
  before Wave 1 fan-out begins; no concurrent reviewer is touching
  wave-1.txt at that point. The OBC consumer runs at phase end (after
  all waves complete). No TOCTOU window between any peer task and the
  seed write.
- **Atomicity.** `write_wave_1_obc` (vscp:164-187) uses
  `mkdir -p` + `mktemp` + atomic `mv`. A mid-write crash leaves either
  no file (OBC fires `wave-1-sidecar-missing:` and halts — fail-safe)
  or the complete file. No partial-content window observable by the
  OBC reader.
- **Data exposure.** The only field written is the integration-base
  SHA. SHAs are not sensitive in this repo's threat model (they're
  visible in any clone). No PII, credentials, or session state cross
  the boundary.

**No finding.**

### C. W1 dual-write inside `--capture`

`validate-stage-commit-parents.sh:264-266`: when `--capture` runs with
`--wave-id W1`, the script ALSO calls `write_wave_1_obc` after the
W1.sidecar mv completes. Two sequential atomic writes:

1. `W1.sidecar` (key=value schema, T19c's existing contract — unchanged)
2. `wave-1.txt` (YAML-colon schema, OBC's contract)

Atomicity / race analysis:

- **Each write is individually atomic** (mktemp + mv inside the same
  `wave-state-dir`, same filesystem).
- **Inter-write window.** Between the `mv` of W1.sidecar (vscp:250)
  and the `mv` of wave-1.txt (vscp:182), there is a brief window
  where W1.sidecar exists but wave-1.txt does not. The two consumers
  read these files at different lifecycle points and tolerate this:
  - `--validate` (vscp:270+) reads ONLY W{N}.sidecar, after the
    stage-merge commit lands. It does not read wave-1.txt.
  - OBC `--phase implement` (obc:158-176) reads ONLY wave-1.txt, at
    Implement phase end (after every wave is fully validated). It
    does not read W1.sidecar.
  Neither consumer races the writer. If the second write fails
  (capture-sidecar-write-error at vscp:179-186), the script exits 1
  before the caller's `git merge --no-ff` runs (per the `--capture`
  contract documented at vscp:67-78). Implement's wave dispatch fence
  surfaces the non-zero exit; the wave halts. No silent half-state
  reaches a downstream consumer.
- **No new shared state.** Both files live under the same
  orchestrator-owned `wave-state-dir`. No additional concurrency
  primitive or lock is needed beyond the existing mktemp+mv pattern
  that round-01 already cleared.
- **No new privilege boundary.** The dual-write does not cross a
  trust boundary that the single-write didn't already cross. Both
  files are produced by the same script invocation with the same
  caller-supplied paths.

**No finding** — the dual-write changes atomicity guarantees only
within the wave-state-dir and only along consumer paths that
fail-closed when the second file is missing.

## Six standard cross-task surfaces — re-traced

1. **Dispatch chain auth boundary.** No diff this round in
   `scripts/dispatch-agent.sh`, `scripts/dispatch-companion.sh`,
   `scripts/await-round.sh`, or `scripts/third-party-finding-splitter.sh`.
   Round-01 baseline holds: `_validate_output_dir` allowlist,
   `_validate_job_id`, REVIEWER_TAG allowlist, manifest-exec model
   with realpath confinement under `EXEC_ROOTS`.
2. **Prompt-injection markers.** No diff in `FORBIDDEN_MARKERS`
   coverage or in batch/single-mode emission paths. The two SKILL
   prose edits (F01) and the new script mode (F02) do not flow into
   any reviewer prompt as `--companion` or `--field` content.
3. **Third-party reviewer output as future-prompt input.** Unchanged;
   `splitter` path is untouched this round.
4. **SHA / phase-base validation across tasks.** This is the surface
   F01 and F02 both touch. Re-traced above (sections A, B, C): the
   bare-SHA writer + bare-SHA reader pair on the Integrate/Test side,
   and the seed-mode + dual-write pair on the Implement side, both
   preserve the SHA_REGEX-before-git-invocation invariant on every
   path that produces or consumes phase-base data.
5. **Privilege-escalation / shared-state composition.** Unchanged.
   `GIT_AUTHOR_NAME=qrspi-<agent>` gate (dispatch-agent.sh:910/1218)
   still runs only after `_validate_agent_name_charset`. The
   `wave-state-dir` writes added this round are in the orchestrator's
   own artifact tree, not in any cross-agent trust boundary.
6. **Network egress guards.** No diff in `dispatch-companion.sh`'s
   `_is_rejected_host` / `_is_loopback_only` / scheme guard / NUL
   pre-flight. Egress surface is unchanged.

## Per-task review acknowledgements

The Implement-phase per-task security reviewer findings for T19
(orchestration-boundary-check), T19c (validate-stage-commit-parents),
T21 (integrate SKILL), T22 (test SKILL) were each addressed in their
own per-task rounds; this review explicitly traced the
`validate-stage-commit-parents.sh ↔ orchestration-boundary-check.sh`
and `{integrate,test} SKILL ↔ orchestration-boundary-check.sh`
boundaries — the exact surfaces F01 and F02 reshaped — and found no
combination that defeats the per-task defenses.

## Confidence note

`scope_hint` was not supplied in this dispatch (round-02 broaden), so
this review covered the broader diff against `<base-branch>` with no
surface bias. The diff body is dominated by the v0.7.3 plugin
packaging move (marketplace.json / plugin.json / build/* /
CI workflows) and the AGENTS.md→CONTRIBUTING.md prose split; none of
that bulk touches an auth, injection, or shared-state surface. The
security-load-bearing changes are concentrated in
`scripts/validate-stage-commit-parents.sh`,
`scripts/orchestration-boundary-check.sh` (read-side, unchanged in
shape this round), and the two SKILL § Phase Start writers, all of
which were re-read in full.
