---
status: draft
question_ids: [5, 6]
research_type: codebase
---

# Q5 + Q6: codex-companion wrapper shape and CODEX_COMPANION wiring

## Summary

**TL;DR:** `scripts/codex-companion-bg.sh` is a 752-line bash wrapper exposing two subcommands (`launch`, `await`) over `node <codex-companion.mjs> task|status|result --json`, with eight distinct exit codes (0/1/10/11/12/13/14) and an internal `resolve_codex_companion` that prefers `$CODEX_COMPANION` else globs `${HOME}/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs` (sort -V, newest wins). The `CODEX_COMPANION` env var is referenced by name only inside that wrapper file plus its bats test; every skill call site invokes the wrapper indirectly and never sets or reads `CODEX_COMPANION` itself.

**Key findings:**
- Two subcommands, single dispatcher in `main()` at scripts/codex-companion-bg.sh:741-748; usage block at scripts/codex-companion-bg.sh:733-738.
- Exit codes are documented (scripts/codex-companion-bg.sh:12-18) and exercised by bats: 0 success; 1 generic/launch fail; 10 ceiling; 11 job-not-found; 12 audit-integrity; 13 status/result hard error; 14 malformed JSON.
- Companion resolution at scripts/codex-companion-bg.sh:47-74 — explicit `$CODEX_COMPANION` wins; else portable glob; never silent fallback to a hardcoded path.
- The wrapper invokes `node "$companion" task --background --prompt-file <p> --json` (scripts/codex-companion-bg.sh:438), `node "$companion" status <id> --json` (scripts/codex-companion-bg.sh:487), `node "$companion" result <id> --json` (scripts/codex-companion-bg.sh:551), and reads `.jobId`, `.job.status`, and a 5-link fallback chain rooted at `storedJob.result.rawOutput` from those outputs.
- Audit dir is resolved exclusively from `.qrspi/state.json` `artifact_dir` field (scripts/codex-companion-bg.sh:119-161); env-var overrides for audit paths are explicitly ignored (scripts/codex-companion-bg.sh:34-41).
- `CODEX_COMPANION` (the bareword) is referenced in exactly two source files: scripts/codex-companion-bg.sh and tests/unit/test-codex-companion-bg.bats. Skills, hooks, and other tests reference only `scripts/codex-companion-bg.sh` (the wrapper) or the literal glob path used for *availability detection*, not the env var.
- Test seam: tests/unit/test-codex-companion-bg.bats (724 lines, ~30 @test cases) plus tests/fixtures/stub-codex-companion.mjs (a stub wired in via `export CODEX_COMPANION="$STUB"` at tests/unit/test-codex-companion-bg.bats:29).
- Caller availability assumption is uniform: every skill checks `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs` for presence at config-time (skills/goals/SKILL.md:141; skills/using-qrspi/SKILL.md:427), records `codex_reviews: true|false` in `config.md`, and only invokes `scripts/codex-companion-bg.sh` when that flag is true. Callers neither set nor verify `CODEX_COMPANION` themselves.

**Surprises:** The default companion-resolution glob inside the wrapper *is* portable already (scripts/codex-companion-bg.sh:58); however, goals.md G5 (docs/qrspi/2026-04-29-v0.4-bundle/goals.md:99-117) describes the wrapper as still hardcoding `/Users/dfrysinger/.claude/plugins/cache/openai-codex/codex/1.0.4/scripts/codex-companion.mjs` — that hardcode is not present in the current source.

**Caveats:** Scope was qrspi-plus only — I did not enumerate references inside the bundled codex companion source itself (under the plugin cache) since that is the external dependency, not part of the repo.

## Full findings

### Q5: scripts/codex-companion-bg.sh — interface, dependency surface, test seams

#### Subcommands and exit codes

- Header docblock declares the contract: scripts/codex-companion-bg.sh:1-22.
- `launch --prompt-file <path>` — scripts/codex-companion-bg.sh:399-466. Required arg parsing at scripts/codex-companion-bg.sh:401-425; calls `resolve_codex_companion` (scripts/codex-companion-bg.sh:428); spawns `node <companion> task --background --prompt-file <p> --json` under a 5s wall-clock timeout (scripts/codex-companion-bg.sh:436-438; budget env `QRSPI_CODEX_LAUNCH_TIMEOUT_SECONDS`, default 5, scripts/codex-companion-bg.sh:32). On success, prints exactly the parsed jobId on stdout (scripts/codex-companion-bg.sh:464).
- `await <jobId>` — scripts/codex-companion-bg.sh:609-728. Required arg validation scripts/codex-companion-bg.sh:610-614; companion resolved scripts/codex-companion-bg.sh:617; on resolve failure emits an `infrastructure-failure` audit row and exits 1 (scripts/codex-companion-bg.sh:618-628). Polling loop at scripts/codex-companion-bg.sh:640-713; ceiling break scripts/codex-companion-bg.sh:645-649; terminal handler scripts/codex-companion-bg.sh:670-693; audit row on every exit path scripts/codex-companion-bg.sh:715-725.
- Subcommand dispatch — scripts/codex-companion-bg.sh:741-748; unknown subcommand exits 1 with stderr (scripts/codex-companion-bg.sh:744-747).
- Exit code map (declared scripts/codex-companion-bg.sh:12-18; produced by code paths):
  - `0` — success: launch jobId print (scripts/codex-companion-bg.sh:465); await terminal-success (scripts/codex-companion-bg.sh:683, 727).
  - `1` — generic / launch failure: missing arg, unreadable prompt, mktemp fail, timeout, bad-JSON, wrapper internal (e.g., scripts/codex-companion-bg.sh:419-424, 442-444, 461-462; await infrastructure-failure scripts/codex-companion-bg.sh:627; bad subcommand scripts/codex-companion-bg.sh:746).
  - `10` — await ceiling: scripts/codex-companion-bg.sh:646-648, 727 via `final_rc=10`.
  - `11` — job-not-found: scripts/codex-companion-bg.sh:687, 695-697.
  - `12` — audit-log integrity (resolve/perm/lock/append): scripts/codex-companion-bg.sh:124, 140, 145, 154, 158, 191, 198, 224, 240, 263, 278, 286, 294, 624, 723.
  - `13` — status/result hard error or launch JSON parse error in result path: scripts/codex-companion-bg.sh:564, 689, 708.
  - `14` — malformed status/result JSON: scripts/codex-companion-bg.sh:604, 688, 702.

#### Dependency surface (what it invokes; what it reads from invocation output)

External binaries / interpreters invoked:
- `node "$companion" task --background --prompt-file "$prompt_file" --json` — scripts/codex-companion-bg.sh:438. Reads `jobId` from top-level stdout JSON (scripts/codex-companion-bg.sh:382-395; via `extract_json_field` at scripts/codex-companion-bg.sh:313-337).
- `node "$companion" status "$job_id" --json` — scripts/codex-companion-bg.sh:487. Reads `.job.status` at scripts/codex-companion-bg.sh:509; expects values `queued|running|completed|failed|cancelled` (scripts/codex-companion-bg.sh:515-521); detects job-not-found by stderr regex `'No (finished )?job found'` (scripts/codex-companion-bg.sh:498).
- `node "$companion" result "$job_id" --json` — scripts/codex-companion-bg.sh:551. Walks five JSON paths in order (scripts/codex-companion-bg.sh:545-605):
  1. `storedJob.result.rawOutput` (scripts/codex-companion-bg.sh:571)
  2. `storedJob.result.codex.stdout` (scripts/codex-companion-bg.sh:574)
  3. `storedJob.rendered` (scripts/codex-companion-bg.sh:577)
  4. `job.errorMessage` (scripts/codex-companion-bg.sh:595)
  5. `storedJob.errorMessage` (scripts/codex-companion-bg.sh:598)
- `node -e <inline-script> -- <path>` — scripts/codex-companion-bg.sh:315-337 (`extract_json_field` parses JSON via stdin and walks dotted path).
- `jq` — scripts/codex-companion-bg.sh:132 (parse `.qrspi/state.json` `artifact_dir`), scripts/codex-companion-bg.sh:233-238 (encode audit JSONL row).
- `realpath` — scripts/codex-companion-bg.sh:152 (canonicalize artifact_dir).
- `stat` (BSD `-f %m` / GNU `-c %Y`) — scripts/codex-companion-bg.sh:81 (lock-mtime epoch for stale-reap).
- `date -u +%Y-%m-%dT%H:%M:%SZ` and `date +%s` — scripts/codex-companion-bg.sh:87, 96.
- Shell builtins / standard utils: `mktemp`, `mkdir`, `rmdir`, `chmod`, `printf`, `cat`, `grep`, `kill`, `wait`, `sleep`, `wc -c`, `sort -V`, `tail -n1`.

State files read:
- `.qrspi/state.json` — scripts/codex-companion-bg.sh:41 declares relative path `QRSPI_STATE_FILE_REL`; consumed at scripts/codex-companion-bg.sh:120-141 to extract `artifact_dir`.

State files written:
- `<artifact_dir>/.qrspi/audit-codex-review.jsonl` — scripts/codex-companion-bg.sh:39, 182, 284 (one JSONL row per await invocation; fields `job_id, elapsed_seconds, completion_status, timestamp` per scripts/codex-companion-bg.sh:238).
- `<artifact_dir>/.qrspi/audit-codex-review.lock` — mkdir-lock, scripts/codex-companion-bg.sh:40, 183, 207-228, 293-296.

Tunables (env-overridable defaults at scripts/codex-companion-bg.sh:28-32): `QRSPI_CODEX_POLL_INTERVAL_FAST=5`, `QRSPI_CODEX_POLL_INTERVAL_SLOW=30`, `QRSPI_CODEX_POLL_BACKOFF_AFTER=120`, `QRSPI_CODEX_CEILING_SECONDS=1200`, `QRSPI_CODEX_LAUNCH_TIMEOUT_SECONDS=5`. Audit-path env vars (`QRSPI_AUDIT_DIR`, `QRSPI_AUDIT_FILE`, `QRSPI_AUDIT_LOCK_DIR`) explicitly NOT honored (scripts/codex-companion-bg.sh:34-41).

#### Test seams

- tests/unit/test-codex-companion-bg.bats — primary harness; ~30 @test cases covering launch (tests/unit/test-codex-companion-bg.bats:69-134), await happy path (tests/unit/test-codex-companion-bg.bats:138-182), polling cadence (tests/unit/test-codex-companion-bg.bats:186-209), ceiling (tests/unit/test-codex-companion-bg.bats:213-233), malformed/job-not-found (tests/unit/test-codex-companion-bg.bats:237-282), audit-write failure (tests/unit/test-codex-companion-bg.bats:286-305), 100-writer concurrency (tests/unit/test-codex-companion-bg.bats:309-346), `CODEX_COMPANION` unset glob fallback (tests/unit/test-codex-companion-bg.bats:350-357), failed/cancelled fallback chain (tests/unit/test-codex-companion-bg.bats:361-431), infrastructure-failure path (tests/unit/test-codex-companion-bg.bats:435-442), stub JSON-shape sanity (tests/unit/test-codex-companion-bg.bats:446-471), PIPE_BUF guard (tests/unit/test-codex-companion-bg.bats:475-566), stale-lockdir reap (tests/unit/test-codex-companion-bg.bats:570-598), audit-path lockdown (tests/unit/test-codex-companion-bg.bats:607-723).
- tests/fixtures/stub-codex-companion.mjs — JSON-shape-faithful stub of the real codex-companion (header tests/fixtures/stub-codex-companion.mjs:1-26 documents the mirrored paths). Wired in via `export CODEX_COMPANION="$STUB"` at tests/unit/test-codex-companion-bg.bats:29.
- tests/unit/test-using-qrspi.bats:39, 167-173 — cross-references the wrapper as the writer of `audit-codex-review.jsonl` to enforce documentation parity.
- tests/acceptance/test-meta.bats:104, 214 — registers `test-codex-companion-bg.bats` in the unit-test inventory and counts it toward AC8 (29-file presence) and AC7 (798-test count).

### Q6: CODEX_COMPANION wiring

#### Every reference to CODEX_COMPANION across the repo

| file:line | context | role |
|---|---|---|
| scripts/codex-companion-bg.sh:44 | `# Companion path resolution: explicit $CODEX_COMPANION wins; else glob...` | comment / contract doc |
| scripts/codex-companion-bg.sh:48 | `if [ -n "${CODEX_COMPANION:-}" ]; then` | resolver: env-var read |
| scripts/codex-companion-bg.sh:49 | `if [ -x "$CODEX_COMPANION" ] || [ -r "$CODEX_COMPANION" ]; then` | resolver: validate target is executable/readable |
| scripts/codex-companion-bg.sh:50 | `printf '%s\n' "$CODEX_COMPANION"` | resolver: emit chosen path |
| scripts/codex-companion-bg.sh:53-54 | `printf 'codex-companion-bg: CODEX_COMPANION="%s" is not readable\n' "$CODEX_COMPANION" >&2` | resolver: error message |
| scripts/codex-companion-bg.sh:66 | `printf '... and CODEX_COMPANION is unset\n' ...` | resolver: error when both env unset and glob empty |
| tests/unit/test-codex-companion-bg.bats:9 | `#   C3  CODEX_COMPANION resolves portably (glob-of-versions; not pinned)` | test-suite constraint comment |
| tests/unit/test-codex-companion-bg.bats:29 | `export CODEX_COMPANION="$STUB"` | test setup: wire wrapper to stub |
| tests/unit/test-codex-companion-bg.bats:91 | `CODEX_COMPANION="$TEST_ROOT/companion-record.mjs" run "$WRAPPER" launch ...` | per-test override (argv recorder) |
| tests/unit/test-codex-companion-bg.bats:348 | `# ── CODEX_COMPANION default resolution (constraint C3) ────────────` | test-section header |
| tests/unit/test-codex-companion-bg.bats:350-351 | `@test "CODEX_COMPANION unset: ... missing → nonzero with stderr"` / `unset CODEX_COMPANION` | test: missing companion path |
| tests/unit/test-codex-companion-bg.bats:436 | `unset CODEX_COMPANION` | test: missing-companion → infrastructure-failure audit row |
| docs/qrspi/2026-04-29-v0.4-bundle/questions.md:12 | `... where is `CODEX_COMPANION` referenced ...` | this question prompt itself |
| docs/qrspi/2026-04-29-v0.4-bundle/goals.md:99 | `### G5 — Make `CODEX_COMPANION` resolution portable (#55)` | goals doc heading |
| docs/qrspi/2026-04-29-v0.4-bundle/goals.md:105 | `... default value of `CODEX_COMPANION`. Other operators ...` | goals doc body |
| docs/qrspi/2026-04-29-v0.4-bundle/goals.md:109 | `... without setting `CODEX_COMPANION` explicitly silently fails ...` | goals doc body |
| docs/qrspi/2026-04-29-v0.4-bundle/goals.md:116 | `... require callers to set `CODEX_COMPANION`, exit nonzero ...` | goals doc design candidate |
| docs/qrspi/2026-04-29-v0.4-bundle/reviews/questions-review.md:47 | `... Q6 about `CODEX_COMPANION` wiring ...` | review doc |
| tests/fixtures/stub-codex-companion.mjs:26 | `// stub via CODEX_COMPANION):` | stub header comment |

The bareword `CODEX_COMPANION` does not appear in any `skills/**/SKILL.md`, any `hooks/**`, any `templates/**`, the README, or any acceptance test other than the one indirectly via test-codex-companion-bg.bats lookup.

#### How callers resolve the value

- Inside the wrapper itself: scripts/codex-companion-bg.sh:47-74. Precedence is (1) explicit env, with executability/readability check; (2) portable glob `${HOME}/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs` (scripts/codex-companion-bg.sh:58) selected by `sort -V | tail -n1` (scripts/codex-companion-bg.sh:72); (3) hard error with stderr if both fail.
- Skill call sites do not resolve `CODEX_COMPANION`. They only call `scripts/codex-companion-bg.sh launch` / `await` (e.g. skills/integrate/SKILL.md:92, skills/parallelize/SKILL.md:171, skills/goals/SKILL.md:266, skills/plan/SKILL.md:245, skills/design/SKILL.md:144, skills/research/SKILL.md:123, skills/structure/SKILL.md:160, skills/phasing/SKILL.md:129, skills/questions/SKILL.md:82, skills/test/SKILL.md:102-113, skills/implement/templates/per-task-orchestrator.md:138-139). The wrapper does the resolution internally.
- Tests resolve via explicit export: tests/unit/test-codex-companion-bg.bats:29 (suite default to stub) and tests/unit/test-codex-companion-bg.bats:91 (per-test override).
- Availability *probe* used by skills is independent of the env var: skills/using-qrspi/SKILL.md:427 and skills/goals/SKILL.md:141 glob `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs` directly to gate the Codex-reviews question, then persist `codex_reviews: true|false` to `config.md`.

#### Caller assumptions about availability

- Skill detection is done at Goals time, not at each call site: skills/goals/SKILL.md:141 (`only ask if the Codex companion is available — glob for ~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs — skip silently if not found`). Result is cached as `codex_reviews: true` in `config.md`.
- All Codex-using skills assume that when `codex_reviews=true`, the wrapper will succeed in resolving the companion. They do not re-probe — they call the wrapper directly (e.g., skills/parallelize/SKILL.md:171-172, skills/design/SKILL.md:144-145, skills/plan/SKILL.md:245-246, skills/research/SKILL.md:123-124, skills/structure/SKILL.md:160-161, skills/phasing/SKILL.md:129-130, skills/questions/SKILL.md:82-83, skills/test/SKILL.md:102-113, skills/integrate/SKILL.md:92-93, skills/implement/templates/per-task-orchestrator.md:138-139).
- Skills assume the wrapper prints exactly one line (the jobId) on stdout from `launch` (skills/parallelize/SKILL.md:171, skills/integrate/SKILL.md:92, etc.: `prints the jobId to stdout as a single line and exits 0 within ~5 seconds`).
- Skills assume `await` exit codes 0/10/11/12 are the only ones to dispatch on (e.g. skills/parallelize/SKILL.md:172, skills/goals/SKILL.md:267, skills/plan/SKILL.md:246, skills/design/SKILL.md:145, etc.). Exit codes 13 and 14 (status/result hard error / malformed JSON) defined by the wrapper at scripts/codex-companion-bg.sh:17-18 are NOT explicitly enumerated in any skill's await-handling block — those skills handle them via the implicit "non-zero, non-{10,11,12}" fall-through path (which means "do not append stdout to review log" by negation but with no explicit branch).
- The hook layer makes one assumption: `audit-codex-review.jsonl` is written by `scripts/codex-companion-bg.sh` and is therefore protected from non-hook writes — hooks/lib/protected.sh:61, hooks/lib/protected.sh:71 (regex `audit-codex-review\.jsonl`), hooks/lib/audit.sh:319 (mirror-the-contract comment).
- No call site sets `CODEX_COMPANION` before invoking the wrapper. Operator-level configuration (setting `CODEX_COMPANION` in the shell environment) is the only path the wrapper supports for explicit override, and skills do not document that path to users — they rely entirely on the glob default.

## Files surveyed

- scripts/codex-companion-bg.sh
- tests/unit/test-codex-companion-bg.bats
- tests/fixtures/stub-codex-companion.mjs
- tests/unit/test-using-qrspi.bats
- tests/acceptance/test-meta.bats
- hooks/lib/audit.sh
- hooks/lib/protected.sh
- skills/using-qrspi/SKILL.md
- skills/goals/SKILL.md
- skills/questions/SKILL.md
- skills/research/SKILL.md
- skills/design/SKILL.md
- skills/phasing/SKILL.md
- skills/structure/SKILL.md
- skills/plan/SKILL.md
- skills/parallelize/SKILL.md
- skills/integrate/SKILL.md
- skills/test/SKILL.md
- skills/implement/templates/per-task-orchestrator.md
- docs/prompt-design-guide.md
- docs/qrspi/2026-04-29-v0.4-bundle/goals.md
- docs/qrspi/2026-04-29-v0.4-bundle/questions.md
- docs/qrspi/2026-04-29-v0.4-bundle/reviews/questions-review.md
