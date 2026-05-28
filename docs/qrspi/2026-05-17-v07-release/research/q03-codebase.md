---
status: draft
question_ids: [3]
research_type: codebase
---

# Q3: Call shape, error handling, and stdout/stderr contract of `scripts/run-codex-review.sh` and `scripts/codex-companion-bg.sh`, and consumer wiring

## Summary

**TL;DR:** `run-codex-review.sh` is a pure prompt-assembly wrapper: it validates flags, resolves files (repo-relative unless absolute), strips YAML frontmatter from the protocol/agent/skill bodies, emits a `AGENT-BODY-END (3-angle-bracket form)` boundary marker, appends a `## Dispatch parameters` block of `UNTRUSTED-ARTIFACT`-wrapped fields, and pipes the result to `codex-companion-bg.sh launch` on stdin (or prints to stdout under `--dry-run`). `codex-companion-bg.sh` has two subcommands: `launch` (reads prompt from stdin, forks the codex companion `task --background --json`, verifies the returned jobId via one internal status call with one retry, prints the verified jobId on stdout, exits 0 within ~5 s) and `await <jobId>` (polls status with 5 s/30 s backoff, falls back to `job.phase` and to on-disk state when needed, fetches result via a 5-step extraction chain, streams review markdown to stdout). Both scripts adhere to a numbered exit-code contract (0, 1, 10, 11, 13, 14, 15). Consumers — every step skill (`research`, `plan`, `implement`, `integrate`, `test`, `design`, `goals`, `questions`, `phasing`, `parallelize`, `structure`, `replan`) plus the shared `skills/_shared/codex/launch-await-pattern.md` template — capture the printed jobId from the Bash tool's stdout output (no shell command substitution) and later run `codex-companion-bg.sh await <jobId> > <output_file>` so finding text is redirected to disk and never enters main chat.

**Key findings:**
- `run-codex-review.sh` flag surface (`scripts/run-codex-review.sh:122-184`): `--agent-file`, `--reviewer-tag`, `--output-dir` (must be absolute, validated `:212-215`), `--round`, `--subject-code`/`--artifact-body` (mutually exclusive, repeatable, exactly one required `:217-232`), `--task-def`, `--companion NAME=PATH` (repeatable, name must match `[A-Za-z_][A-Za-z0-9_]*` `:146-149`), `--field NAME=VALUE` (plain scalar `:154-175`), `--diff-file`, `--scope-hint`, `--dry-run`.
- Path resolution: repo-relative paths resolve against `REPO_ROOT` derived from the script's own location (`:82-84`, overridable via `QRSPI_REPO_ROOT`); absolute paths are used verbatim (`:235-242`).
- Frontmatter handling: `strip_frontmatter` strips only the leading YAML block between the first two `^---$` lines, gated by `n<2` so body-level `---` rules survive (`:426-428`).
- Skills frontmatter loading: parses inline-list `skills: [a, b]` form from the agent file, loads each `skills/<name>/SKILL.md`; non-inline shapes exit 2 (`:281-311`); the hardcoded `reviewer-protocol` skill is always loaded and never double-loaded.
- Marker-injection guard: every orchestrator-supplied file body and inline scalar is scanned for the literal `AGENT-BODY-END (3-angle-bracket form)`; presence aborts with exit 1 to protect the agent-body carve-out (`:376-413`).
- Prompt composition (`compose_prompt`, `:508-538`): protocol body → additional skills → agent body → emission-override → `AGENT-BODY-END (3-angle-bracket form)` marker → dispatch-parameters block.
- Dispatch-parameters emission (`emit_dispatch_parameters`, `:442-502`): emits `<PRIMARY_FIELD>:` block(s), optional `task_definition:`, companion field groups (multiple paths under one field concatenate), plain scalar fields, then mandatory `round_subdir:`, `round:`, `reviewer_tag:`, optional `diff_file_path:` and `scope_hint:` (the latter wrapped in `UNTRUSTED-SCOPE-HINT-{START,END}` regardless of empty/non-empty value when the flag is set).
- `run-codex-review.sh` exit codes: 0 (success or `--dry-run` prompt on stdout), 1 (validation: missing flag, bad NAME, missing file, non-absolute `--output-dir`, mutually-exclusive primary fields, marker injection, etc.), 2 (unsupported `skills:` frontmatter shape), and any non-zero from `codex-companion-bg.sh launch` propagates verbatim (`:556`).
- `run-codex-review.sh` stdout: the assembled prompt under `--dry-run`; otherwise the verified jobId line emitted by `codex-companion-bg.sh launch`. Stderr: per-flag `error: …` diagnostics, all to `>&2` (`:117-120, :180-184, :213-251`).
- `codex-companion-bg.sh launch` (`scripts/codex-companion-bg.sh:292-369`): rejects extra args and TTY stdin (`:293-301`), captures stdin to a temp prompt-file (`:303-313`), runs codex companion `task --background --prompt-file <tmp> --json` with a 5 s timeout (`QRSPI_CODEX_LAUNCH_TIMEOUT_SECONDS`, `:51, :216-223`), parses jobId via `extract_json_field` (`:117-141, :186-199`), performs a single `verify_job_id` poll, retries the whole task call once on not-found/malformed/error (`:330-364`); on retry-success writes the stderr note `launch: first jobId failed verification, retried`; double-phantom exits 15 with no jobId on stdout.
- `codex-companion-bg.sh await` (`:839-987`): defaults — ceiling 1200 s (`QRSPI_CODEX_CEILING_SECONDS`), fast interval 5 s, slow interval 30 s, backoff after 120 s, all env-overridable (`:47-51`). Loops over `poll_status` (`:384-468`); on `completed:*` invokes `fetch_result` (`:491-551`); on `not-found` consults `disk_state_fallback` (`:623-832`).
- `poll_status` output strings: `running`, `completed:completed`, `completed:failed`, `completed:cancelled`, `not-found`, `malformed`, `error`; falls back from `job.status` to `job.phase` mapping (`finalizing|done|reviewing → completed:completed`, `starting|running|investigating|editing|verifying → running`, else malformed) and emits a one-shot `[codex-companion-bg] phase fallback active:` audit line to stderr (`:415-468`).
- `fetch_result` five-source chain (`:516-546`): `storedJob.result.rawOutput` → `storedJob.result.codex.stdout` → `storedJob.rendered` → `job.errorMessage` → `storedJob.errorMessage`. First non-empty wins; if all empty/absent, exit 14.
- `disk_state_fallback` (`:623-832`): reads at most two files (`state.json`, `jobs/<jobId>.json`) under `$CLAUDE_PLUGIN_DATA/state/<slug>-<sha256[:16]>/`, mirrors the same five-source extraction chain on the disk record; emits `await: recovered <jobId> from disk (broker reported not-found)` to stderr on success.
- `codex-companion-bg.sh` exit-code table (`:21-28`): 0 success, 1 generic/launch failures, 10 await ceiling hit, 11 await job-not-found, 13 status/result hard error or launch bad JSON, 14 malformed JSON from status/result, 15 LAUNCH_PHANTOM.
- Consumer pattern is captured in `skills/_shared/codex/launch-await-pattern.md`: capture the jobId from the Bash tool's stdout, paste it literally into the matching `await` call, redirect `await <jobId> > <output_file>` so review markdown never enters main chat; on non-zero exit codes the orchestrator (not the wrapper) writes ceiling/crash/infra-fail notes to the output file.
- Research-skill consumption splits Codex output further: after `codex-companion-bg.sh await <jobId> > /tmp/codex-stdout-<jobId>.txt` and exit 0, `scripts/codex-finding-splitter.sh` materializes per-finding files (`skills/research/SKILL.md:205-212`).
- `skills/implement/SKILL.md:1135` documents that the wrapper does NOT write the ceiling/crash/infra-fail notes itself — main-chat orchestration writes them into the per-round Codex file on non-zero exits before recording task status.

**Surprises:**
- The legacy `launch --prompt-file <path>` argument form is retired; `launch` accepts the prompt only on stdin (commit 21/22 of the #110 migration; `codex-companion-bg.sh:6-12, :293-301`). Passing any positional/flag argument exits 1.
- `extract_json_field` invokes `node -e` for JSON parsing (no `jq` dependency); `node -e`'s argv quirk (no script-path entry) is explicitly worked around with a leading `--` separator (`codex-companion-bg.sh:117-141`).
- A bug-fix gate guards `strip_frontmatter` from eating body-level `---` rules — the older `awk '/^---$/{n++; next} n>=2{print}'` form silently corrupted YAML mini-frontmatter inside SKILL.md examples; the fix gates `next` on `n<2` (`run-codex-review.sh:421-428`).
- The wrapper's `fetch_result` deliberately diverges from codex companion's `render.mjs:421-445` header-block formatting — for failed/cancelled jobs it emits just `errorMessage` verbatim rather than the `# <title>\nJob: …\nStatus: …` block (the `[CodexF1-resolved-by-comment]` note, `:526-540`).
- `disk_state_fallback` reproduces the broker's state-directory naming exactly (slug + `sha256(realpath(workspace))[:16]`) and performs two containment checks — string-prefix and `realpathSync` — against `$CLAUDE_PLUGIN_DATA` to defend against symlink escapes (`:645-708`).

**Caveats:** Only the two scripts plus the consuming skill files referenced above were read in full. The companion `codex-companion.mjs`, `scripts/codex-finding-splitter.sh`, `lib/state.mjs`, and `lib/render.mjs` were not opened — their behaviors are reflected only via the wrapper's documented assumptions and inline citations to them. Hook integrations (`hooks/lib/audit.sh`, `hooks/lib/protected.sh` matched the grep) were not investigated. Historical/spec/plan markdown that mentions the scripts was not read beyond what was needed to enumerate consumer patterns.

## Full findings

### 1. `scripts/run-codex-review.sh` — call shape

The wrapper is the single entrypoint for Codex reviewer dispatches across all step skills (header comment, `scripts/run-codex-review.sh:1-9`).

**CLI flags** (parsed at `:122-184`):
- `--agent-file <path>` (required) — agent markdown file; loaded by `strip_frontmatter` after YAML stripping.
- `--reviewer-tag <tag>` (required) — emitted as `reviewer_tag:` in dispatch params (`:490`).
- `--output-dir <abs>` (required) — must start with `/` (`:212-215`); emitted as `round_subdir:` (`:488`). Absolute-only enforcement is load-bearing for the agent-side Phase Routing fail-loud check that detects `/reviews/test/` in non-test dispatches (`:204-211`).
- `--round <N>` (required) — emitted as `round:` (`:489`).
- `--subject-code <path>` and `--artifact-body <path>` — mutually exclusive, exactly one required, both repeatable; chosen one becomes `PRIMARY_FIELD` and is emitted with one `UNTRUSTED-ARTIFACT` block per path under a single field header (`:217-232, :447-451`).
- `--task-def <path>` — optional; absence is "load-bearing" for test-phase reuse (comment `:18-20, :454-459`). When present, emits `task_definition:` followed by the wrapped body.
- `--companion NAME=PATH` — repeatable, generic; multiple paths under the same NAME concatenate under one field header (`:131-153, :463-478`). NAME must satisfy `[A-Za-z_][A-Za-z0-9_]*` (`:146-149`).
- `--field NAME=VALUE` — repeatable, plain (non-wrapped) scalar; emits `NAME: VALUE`. NAME validation same as companion; VALUE may be empty (`:154-175, :481-483`).
- `--diff-file <abs>` — optional; emitted as `diff_file_path: <path>` literal (no wrapping) when present (`:492-494`). File-existence check only (`:350-355`).
- `--scope-hint <string>` — optional. When the flag is omitted the line is omitted; when present (even with empty string), emits `scope_hint: <<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>VALUE<<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>` (`:496-501`).
- `--dry-run` — prints the assembled prompt to stdout instead of piping to `codex-companion-bg.sh` (`:178, :544-547`).

**Path resolution.** `REPO_ROOT` is derived from the script's directory via `cd "$SCRIPT_DIR/.." && pwd -P` and overridable via `QRSPI_REPO_ROOT` (`:82-84`). `resolve_path` returns the path verbatim if it starts with `/`, otherwise joins it under `REPO_ROOT` (`:235-242`). Every resolved path is checked for existence by `assert_file_exists` (`:244-251`).

**Skills frontmatter loading.** `extract_skill_names` (`:281-298`) accepts only the inline-list form `skills: [a, b, c]`; any other shape (block-list, scalar) exits 2 with a stderr error. The hardcoded `reviewer-protocol` skill is filtered out to avoid double-loading (`:315`). Each remaining named skill resolves to `skills/<name>/SKILL.md` and is validated for existence.

**Marker-injection guard.** The literal string `AGENT-BODY-END (3-angle-bracket form)` is reserved as the wrapper-private trust boundary marker (`:376`). Every orchestrator-supplied file (primary artifact, task-def, companions, diff-file) and inline scalar (`--scope-hint`, `--field VALUE`s) is scanned via `grep -F -q` or shell substring match; any match aborts with exit 1 (`:378-413`). Trusted body files (agent, reviewer-protocol, emission-override) are NOT scanned — their content IS the agent body the marker delimits.

**Prompt composition.** `compose_prompt` (`:508-538`) emits, in order:
1. `strip_frontmatter` of `skills/reviewer-protocol/SKILL.md`.
2. `---` separator.
3. For each additional skill from `skills:` frontmatter: `strip_frontmatter` of that SKILL.md plus a `---` separator.
4. `strip_frontmatter` of the agent file.
5. `---` separator.
6. `cat` of `skills/reviewer-protocol/codex-emission-override.md`. The override comes AFTER the agent body so it supersedes the agent body's "Use the Write tool" directive — Codex runs read-only and must emit findings to stdout (`skills/reviewer-protocol/SKILL.md:13`).
7. `AGENT-BODY-END (3-angle-bracket form)` marker on its own line.
8. `emit_dispatch_parameters` (`:442-502`), under a leading `## Dispatch parameters` heading.

**Frontmatter stripping correctness.** `strip_frontmatter` uses `awk '/^---$/ && n<2 {n++; next} n>=2 {print}'` (`:426-428`). The `n<2` gate prevents body-level `^---$` lines (horizontal rules and YAML mini-frontmatter inside fenced examples) from being eaten — the older `/^---$/{n++; next}` form silently corrupted them.

### 2. `scripts/run-codex-review.sh` — error handling and I/O contract

**Shell mode.** `set -u` only (`:69`); intentionally not `-e` and not `pipefail` (`:70-72`) so the wrapper surfaces its own validation errors with named diagnostics and tolerates trailing pipeline failure modes from `codex-companion-bg.sh`. The `require_value` helper makes `set -u` safe for value-taking flags at end-of-argv (`:113-120`).

**Validation errors (all exit 1, diagnostic to stderr):**
- Missing required flag (`require_flag`, `:190-197`): `error: --<name> required`.
- Non-absolute `--output-dir`: `error: --output-dir must be absolute (got: …)` (`:213-215`).
- Neither or both of `--subject-code` / `--artifact-body` (`:217-225`).
- Malformed `--companion` or `--field` NAME=PATH/VALUE (`:131-150, :154-175`).
- Missing file (`assert_file_exists`, `:244-251`): `error: <label> not found: <path>`.
- Missing `--diff-file`: `error: diff-file not found: <path>` (`:351-354`).
- Marker-injection match in any orchestrator-supplied input: `error: <label> contains the wrapper-private marker 'AGENT-BODY-END (3-angle-bracket form)' …` (`:378-392`).
- Codex companion launcher missing or non-executable: `error: codex-companion-bg.sh not executable at <path>` (`:550-553`).

**Frontmatter-shape error (exit 2):** Unsupported `skills:` form (`:285-298, :307-311`): `error: skills: frontmatter must use inline-list form 'skills: [a, b, c]' …`.

**stdout / stderr contract:**
- `--dry-run`: assembled prompt → stdout; nothing else (`:544-547`).
- Normal mode: the assembled prompt is piped to `codex-companion-bg.sh launch`. The launcher's stdout (the verified jobId line) becomes the wrapper's stdout; exit status of the launcher is propagated via `exit "$?"` (`:555-556`).
- All wrapper-level errors are emitted to stderr (`>&2`). The wrapper itself emits nothing to stdout outside `--dry-run` and the pipeline pass-through.

### 3. `scripts/codex-companion-bg.sh launch` — call shape and error handling

**Invocation:** Reads the prompt from stdin only. Any positional/flag argument is rejected (`scripts/codex-companion-bg.sh:293-296`): `launch: unrecognised argument: <arg> (path-arg form retired; pipe prompt on stdin)`. A TTY stdin is rejected (`:298-301`): `launch: stdin must not be a TTY …`. Stdin is captured to a temp file via `mktemp -t codex-companion-bg-stdin.XXXXXX`; empty stdin aborts with `launch: stdin was empty` (`:303-313`).

**Companion resolution** (`resolve_codex_companion`, `:57-84`): explicit `$CODEX_COMPANION` env var wins if it exists and is readable/executable; otherwise globs `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs`, sorts with `sort -V`, picks newest. No silent fallback to a hardcoded path; misconfig → return 1 with a stderr diagnostic.

**Launch flow** (`launch_subcommand`, `:292-369`):
1. `run_task_once` (`:208-244`) spawns `node <companion> task --background --prompt-file <tmpfile> --json` under `spawn_with_timeout` with budget `QRSPI_CODEX_LAUNCH_TIMEOUT_SECONDS` (default 5 s, `:51`). On timeout: stderr `launch: companion did not return within <N>s (job-create hung)`, exit 1 from helper. On non-zero rc: stderr-passthrough plus `launch: companion 'task --background' exited <rc>`. On success: extract jobId via `parse_launch_output` → `extract_json_field "$stdout_text" "jobId"`; empty or missing jobId returns 1 with a stderr message.
2. `verify_job_id` (`:260-278`) does one `poll_status` and treats `running` / `completed:*` as verified; `not-found`, `malformed`, and `error` all force a retry.
3. On retry-success: writes stderr note `launch: first jobId failed verification, retried`, then prints the second jobId.
4. Double-phantom (both attempts return not-found/malformed/error from verify): exit 15 (`LAUNCH_PHANTOM`) with stderr `launch: both jobId attempts failed verification (LAUNCH_PHANTOM)` and NO jobId on stdout (`:39, :366-369`).

**Stdout contract:** exactly one line, the verified jobId, on success. Nothing else (`:340, :361`).

**Stderr contract:** error diagnostics; on retry-success a one-shot note; on phantom an explicit `LAUNCH_PHANTOM` line. The phase-fallback line from `poll_status` may also appear here (see §5).

### 4. `scripts/codex-companion-bg.sh await <jobId>` — call shape and error handling

**Invocation** (`await_subcommand`, `:839-987`): single positional `<jobId>` argument. Supports `--` separator before positional. Rejects unknown flags and extra positionals (`:850-862`). Missing jobId → `await: jobId argument is required`, exit 1.

**Polling.** Loop iterates until ceiling or a terminal `poll_status` outcome:
- Fast interval `QRSPI_CODEX_POLL_INTERVAL_FAST=5` until elapsed ≥ `QRSPI_CODEX_POLL_BACKOFF_AFTER=120`, then slow interval `QRSPI_CODEX_POLL_INTERVAL_SLOW=30`. Ceiling: `QRSPI_CODEX_CEILING_SECONDS=1200`. All four are env-overridable (`:47-51, :876-912`).

**Outcome handling** (`:885-983`):
- `running` → sleep, loop.
- `completed:<terminal>` → call `fetch_result`; on success exit 0 with stdout markdown; on rc 11/14 propagate; on other rc map via `_status_to_exit_code "$terminal"` (completed→14, failed→13, cancelled→13, unknown→13).
- `not-found` → invoke `disk_state_fallback "$job_id"`; map disk rc 0/13/14 verbatim; disk miss (rc 1 / other) falls through to exit 11 with stderr `await: job <id> not found by companion`.
- `malformed` → exit 14, stderr `await: malformed status JSON for job <id>`.
- `error` (or wildcard) → exit 13, stderr `await: hard error from status for job <id>`.
- Ceiling reached → exit 10 (no further stderr).

**Stdout contract:** Either the review markdown (success path) OR nothing (ceiling, not-found, malformed, hard-error). On exit 0 the markdown comes from `fetch_result` (`:491-551`) or the disk-recovery path (`:780-798`). Trust boundary: `rawOutput` and `errorMessage` are emitted verbatim — no ANSI stripping (`:609-612`).

**fetch_result** (`:491-551`) five-source chain, first non-empty wins:
1. `storedJob.result.rawOutput`
2. `storedJob.result.codex.stdout`
3. `storedJob.rendered`
4. `job.errorMessage`
5. `storedJob.errorMessage`

If none yields a non-empty value → exit 14 with stderr `fetch_result: malformed result JSON or no extractable review text; got: <stdout>`. If the underlying companion `result` call exited non-zero and stderr matched `No (finished )?job found` → exit 11 with the broker's stderr passed through; otherwise exit 13.

**disk_state_fallback** (`:623-832`) — internal helper invoked only from the `not-found` branch:
- Hard-stops if `$CLAUDE_PLUGIN_DATA` is empty.
- Rejects jobId values containing `/`, `..`, leading `.`, or empty (`:632-640`).
- Resolves state directory via embedded `node -e` that mirrors `lib/state.mjs:29-43`: `path.join(CLAUDE_PLUGIN_DATA, 'state', '<slug>-<sha256(realpath(workspaceRoot))[:16]>')` with workspace root from `git rev-parse --show-toplevel`. Two containment checks (string-prefix + `realpathSync`) ensure the resolved dir stays under `$CLAUDE_PLUGIN_DATA` (`:644-708`).
- Reads at most two files: `state.json` (membership in `jobs[]`) and `jobs/<jobId>.json`.
- Applies the same five-source extraction chain to the disk record; on success emits `await: recovered <jobId> from disk (broker reported not-found)` to stderr and the payload to stdout, returns 0 (`:780-798, :587-589`).
- Unknown/future status → exit 14 with `await: disk record at … reported unknown status <s>; treating as malformed (exit 14)`.
- Per-job JSON unparseable → exit 11 with `await: disk record at … has malformed status field`.

**Stderr surface for `await`:** the phase-fallback one-shot note from `poll_status` (`[codex-companion-bg] phase fallback active: <phase> → <lifecycle>`, `:440-443`), the disk-recovery note from `disk_state_fallback` (`:587-589`), and the named diagnostic line at terminal-failure exits.

### 5. `poll_status` output normalization

`poll_status` (`scripts/codex-companion-bg.sh:384-468`) is the single source of truth for status-string normalization. Exit-code/output mapping (stdout strings, never the function's return):

| `node <companion> status … --json` rc | stderr match | stdout `job.status` | stdout `job.phase` | poll_status emits |
| --- | --- | --- | --- | --- |
| ≠0 | matches `No (finished )?job found` | — | — | `not-found\n` |
| ≠0 | other | — | — | `error\n` (stderr passed through) |
| 0 | — | `queued` or `running` | — | `running\n` |
| 0 | — | `completed` | — | `completed:completed\n` |
| 0 | — | `failed` | — | `completed:failed\n` |
| 0 | — | `cancelled` | — | `completed:cancelled\n` |
| 0 | — | other | — | `malformed\n` |
| 0 | — | absent (extract rc 1) | `finalizing`/`done`/`reviewing` | `completed:completed\n` + one-shot stderr audit |
| 0 | — | absent | `starting`/`running`/`investigating`/`editing`/`verifying` | `running\n` + one-shot stderr audit |
| 0 | — | absent | absent or unmapped | `malformed\n` (stdout passed through) |

The audit line `[codex-companion-bg] phase fallback active: <phase> → <lifecycle>` is emitted only on the first phase-fallback hit per wrapper process (`CODEX_PHASE_FALLBACK_LOGGED` guard, `:45, :440-444`). Callers must parse only stdout + exit code; the stderr surface is explicitly excluded from the public contract (`:438-439`).

### 6. Exit-code reference (both scripts)

`scripts/run-codex-review.sh:64-67`:
- `0` — success (or jobId from launch on stdout if not `--dry-run`).
- `1` — missing required flag, file not found, marker injection, validation error.
- `2` — unsupported `skills:` frontmatter shape (awk-parser exit, propagated `:307-311`).
- Any non-zero from `codex-companion-bg.sh launch` passes through.

`scripts/codex-companion-bg.sh:21-28`:
- `0` — success.
- `1` — generic / launch failures (missing companion, bad args, empty stdin, validation).
- `10` — `await` ceiling hit (1200 s).
- `11` — `await`: job-not-found (broker says so AND disk fallback misses).
- `13` — `await`: status/result hard error, launch bad JSON, or disk-fallback failed/cancelled with errorMessage.
- `14` — `await`: malformed JSON from status/result, or `completed` with no extractable output, or unknown status from disk fallback.
- `15` — `launch`: `LAUNCH_PHANTOM` — both jobId verification attempts failed.

### 7. Consumer wiring — how main chat / dispatching skills consume the output

The consumption pattern lives in `skills/_shared/codex/launch-await-pattern.md` and is embedded by every step skill via `!`cat ${CLAUDE_SKILL_DIR}/../_shared/codex/launch-await-pattern.md`` (`launch-await-pattern.md:45`). Two framing variants:

- **Single-template form** (`launch-await-pattern.md:27-33`): one `<output_file>` plus one stdin-piped prompt at the top level of the framing block.
- **Multi-template form** (`:35-43`): a `<codex_dispatches>` element with one or more `<dispatch>` children, each with its own `<output_file>` and stdin-piped prompt; jobIds are recorded under each dispatch's `label` (orchestrator notes, not shell variables).

**jobId capture.** The orchestrator captures the verified jobId line from the Bash tool's stdout output of the `run-codex-review.sh` call (or the multi-dispatch one-shot pipeline `… | scripts/codex-companion-bg.sh launch`). Shell command substitution (`$()` / backticks) and process substitution are explicitly forbidden per Daniel's CLAUDE.md (`launch-await-pattern.md:25`).

**Await + redirect.** After the matching Claude reviewer returns, the orchestrator runs the await with stdout redirected directly to the per-round Codex file: `scripts/codex-companion-bg.sh await <jobId> > <output_file>` (`:33`). This is the core "no finding text in main chat" invariant — the markdown stream goes straight to disk; main chat does not read the Codex per-round file until apply-fix time.

**Non-zero exit handling — orchestrator-driven, not wrapper-driven.** The shared pattern enumerates the action per exit code (`launch-await-pattern.md:33, :43`):
- `0` — file contains markdown findings.
- `10` — write an explicit ceiling note (e.g., `Codex review: 20-min ceiling hit, no findings produced`) to the per-round Codex file; do NOT silently retry.
- `11` — write a crash note to the per-round Codex file and surface to the user before proceeding.
- `13`, `14` — write an infrastructure-failure note and surface to the user; do NOT retry blindly.
- `15` — not enumerated in the shared pattern as of this read (LAUNCH_PHANTOM surfaces at launch, before the await loop).

`skills/implement/SKILL.md:1135` confirms: "the per-reviewer per-round Codex file … holds the verbatim Codex stdout on exit-0; per the shared launch-await pattern, on non-zero exit codes (10 ceiling-hit / 11 crash / 13|14 infra-fail) the **orchestrator** (main chat — not the wrapper) writes the corresponding explicit ceiling/crash/infra-fail note into the same per-round Codex file before recording Status."

**Per-skill consumption specifics:**
- **Research** (`skills/research/SKILL.md:187-212`): redirects to `/tmp/codex-stdout-<jobId>.txt`, then on exit 0 runs `scripts/codex-finding-splitter.sh /tmp/codex-stdout-<jobId>.txt reviews/research/round-NN/ quality-codex` to split into per-finding files. Either failure path yields zero output for the tag; the round directory schema guard catches it in step 2.
- **Implement** (`skills/implement/SKILL.md:898-1013, :1135, :1225-1243`): emits multiple parallel reviewer dispatches via `run-codex-review.sh` per round, awaits each into `/tmp/codex-stdout-<jobId>.txt`, then the apply-fix step reads each referenced Codex file at dispatch time and merges findings with the Claude reviewer findings.
- **Reviewer-protocol** (`skills/reviewer-protocol/SKILL.md:13`): is the source of truth for the dispatch-params field names that `run-codex-review.sh` emits (`subject_code`, `artifact_body`, `task_definition`, `round_subdir`, `round`, `reviewer_tag`, `diff_file_path`, `scope_hint`, `companion_*`).
- **Research-isolation skill** (`skills/research-isolation/SKILL.md`): formalizes the trust-boundary semantics of the `AGENT-BODY-END (3-angle-bracket form)` marker that `run-codex-review.sh:536` emits — research agents apply their Pre-Flight Isolation Check only to text after this marker.

**Direct calls to `codex-companion-bg.sh launch`.** Some skills assemble the prompt inline (the original pattern, retained as documentation in `launch-await-pattern.md:12-21`) and pipe directly to `scripts/codex-companion-bg.sh launch`. This is the same wrapper that `run-codex-review.sh` itself pipes to at `:555`, so the contract is identical: stdin = prompt, stdout = verified jobId line, exit 0 within ~5 s; on non-zero, abort that dispatch and write a launch-failure note.
