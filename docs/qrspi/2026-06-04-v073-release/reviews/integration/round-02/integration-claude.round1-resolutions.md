---
reviewer: integration-claude
round: 02
referenced_files:
  - scripts/orchestration-boundary-check.sh
  - scripts/validate-stage-commit-parents.sh
  - skills/integrate/SKILL.md
  - skills/test/SKILL.md
  - skills/implement/SKILL.md
  - tests/unit/test-orchestration-boundary-check.bats
round1_resolution:
  - id: F01
    status: resolved
    fix_commits: [c2e68c2, 69500e2]
  - id: F02
    status: resolved
    fix_commits: [08fd0a8, 28dee59]
---

# Round-01 finding resolutions (round-02 verification)

## F01 — `phase-base.txt` bare-SHA contract — **RESOLVED**

The Integrate and Test SKILLs no longer write the `integration_base_sha=<SHA>`
key=value form that the OBC parser would have rejected with
`sha-format-invalid:`. Both SKILLs now emit a single-line bare SHA — the exact
shape the OBC's `tr -d '[:space:]'` + `^[0-9a-f]{7,64}$` validation accepts.

**Verbatim evidence — `skills/integrate/SKILL.md:90-96`:**

> Write `reviews/integration/phase-base.txt` as the first orchestrator action
> of the integrate phase, before any subagent dispatch. Capture the integration
> branch's HEAD SHA and write it as the single-line bare-SHA file contents (no
> key=value prefix, no trailing structure — just the SHA + newline) …
>
> ```sh
> mkdir -p "<ABS_ARTIFACT_DIR>/reviews/integration"
> printf '%s\n' "$(git -C "<repo>" rev-parse HEAD)" \
>   > "<ABS_ARTIFACT_DIR>/reviews/integration/phase-base.txt"
> ```

**Verbatim evidence — `skills/test/SKILL.md:90`:**

> 1. **Phase-start: write `reviews/test/phase-base.txt`** — … write
>    `<ABS_ARTIFACT_DIR>/reviews/test/phase-base.txt` with single-line bare-SHA
>    contents (no key=value prefix — just the SHA + newline). … Shell:
>    `mkdir -p "<ABS_ARTIFACT_DIR>/reviews/test" && printf '%s\n' "$(git rev-parse HEAD)" > "<ABS_ARTIFACT_DIR>/reviews/test/phase-base.txt"`.

**Consumer side unchanged and consistent —
`scripts/orchestration-boundary-check.sh:179-194`:**

```bash
integration|test)
  pbfile="$artifact_dir/reviews/$phase/phase-base.txt"
  …
  raw="$(tr -d '[:space:]' < "$pbfile" 2>/dev/null || true)"
  …
  elif ! is_well_formed_sha "$raw"; then
    add_defect "sha-format-invalid: …"
```

`printf '%s\n' "$SHA"` → after `tr -d '[:space:]'` → `<SHA>` → matches
`^[0-9a-f]{7,64}$`. Round-trip clean. The Integrate / Test phase-end OBC
gates no longer fire `sha-format-invalid:` on every real run.

The T24 structural lint
(`scripts/structural-lints/check-integrate-test-skill-phase-base-write.sh`
+ `tests/lint/test-integrate-test-skill-phase-base-write.bats`) anchors the
write-verb + path pair into both SKILLs against future prose drift, partially
addressing F01's detection gap. (The lint matches on path + write verb only;
it does not lock the value-format contract, so a future drift back to the
key=value form would not be caught structurally — note for posterity, not a
new round-02 finding.)

## F02 — Implement wave-1 sidecar bridge — **RESOLVED**

The merge introduces a **two-channel bridge** in
`scripts/validate-stage-commit-parents.sh` that emits the OBC-shaped
`wave-1.txt` companion file the OBC `--phase implement` branch reads, in
addition to the original `W{N}.sidecar` schema. The Implement SKILL drives
both channels so both "Wave 1 with stage commit" and "Wave 1 fan-out only"
produce the file the OBC expects.

**Channel A — capture dual-write (Wave 1 with stage commit).**
`scripts/validate-stage-commit-parents.sh:256-266`:

```bash
# OBC bridge: when capturing Wave 1, ALSO write the OBC-shaped wave-1.txt
# companion alongside W1.sidecar …
if [ "$wave_id" = "W1" ]; then
  write_wave_1_obc "$base" "$wave_state_dir"
fi
```

The `write_wave_1_obc` helper (`scripts/validate-stage-commit-parents.sh:164-187`)
writes exactly the body the OBC parser expects:

```bash
printf 'integration_base: %s\n' "$base"
printf 'task_tips:\n'
…
mv "$tmp" "$dir/wave-1.txt"
```

— filename `wave-1.txt` (not `W1.sidecar`), separator `:` (YAML-colon, not
`=`), and the trailing `task_tips:` line that matches the pinned OBC
fixture.

**Channel B — seed-only mode (fan-out-only Wave 1, no stage commit).**
`scripts/validate-stage-commit-parents.sh:196-204`:

```bash
if [ "$mode" = seed-wave-1-obc ]; then
  if [ -z "$integration_base_arg" ]; then
    echo "--seed-wave-1-obc requires --integration-base <SHA>" >&2
    exit 2
  fi
  validate_sha "$integration_base_arg" "--integration-base argument"
  write_wave_1_obc "$integration_base_arg" "$wave_state_dir"
  exit 0
fi
```

— and the Implement SKILL invokes it explicitly for fan-out-only Wave 1,
closing the third gap F02 called out (no `--capture` → no W1 sidecar → OBC
halt).

**SKILL-side wiring evidence — `skills/implement/SKILL.md:162-181`:**

```sh
scripts/validate-stage-commit-parents.sh --capture --wave-id W{N} \
    --task-branch qrspi/{slug}/task-AA …
…
```

> When `--wave-id W1`, `--capture` ALSO dual-writes
> `reviews/implement/wave-state/wave-1.txt` (OBC-shaped YAML colon,
> `integration_base: <SHA>\ntask_tips:\n`) …
>
> **Wave 1 OBC seed (fan-out-only Wave 1).** When Wave 1 has NO stage
> commit … seed `wave-1.txt` from the current HEAD as a one-shot:
>
> ```
> scripts/validate-stage-commit-parents.sh --seed-wave-1-obc \
>     --integration-base "$(git rev-parse HEAD)" \
>     --artifact-dir "<ABS_ARTIFACT_DIR>"
> ```

**Consumer side unchanged and consistent —
`scripts/orchestration-boundary-check.sh:156-177`:**

```bash
implement)
  sidecar="$artifact_dir/reviews/implement/wave-state/wave-1.txt"
  …
  raw="$(awk -F'[[:space:]]*:[[:space:]]*' '$1=="integration_base"{print $2; exit}' "$sidecar" …)"
```

— path, filename, and separator all match `write_wave_1_obc`'s output.

**Wiring spot-checks:**

- `--seed-wave-1-obc` resolves `wave_state_dir` from `--artifact-dir`
  (`scripts/validate-stage-commit-parents.sh:126-135`), landing the file at
  `<artifact_dir>/reviews/implement/wave-state/wave-1.txt` — same path the
  OBC reads.
- The `--seed-wave-1-obc` mode is exempted from the `--wave-id`-required
  guard (`scripts/validate-stage-commit-parents.sh:121-124`), matching the
  SKILL invocation which omits `--wave-id`.
- The W{N}.sidecar schema (`integration_base=`, `task_tip_shas=`) used by
  the unchanged `--capture`/`--validate` parent-validation path stays
  isolated from the OBC bridge; T19c's existing bats fixtures continue to
  pin the original schema, and the new `wave-1.txt` companion is purely
  additive.

The Implement phase-end OBC gate no longer fires `wave-1-sidecar-missing:`
or `wave-1-sidecar-malformed:` on real runs.

## New round-02 findings

None at blocker/high/medium against the broadened diff. The known baseline
test-count drift (workflow count 1→2, agent count 41→42, marketplace
v0.7.2→v0.7.3 pin) is in the Integrate-CI fix scope and is excluded per
dispatch.
