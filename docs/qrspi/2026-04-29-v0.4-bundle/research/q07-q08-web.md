---
status: draft
question_ids: [7, 8]
research_type: web
---

# Q7 + Q8: Upstream codex-companion JSON shape; portable helper-path resolution

## Summary

**TL;DR:** `codex-companion.mjs status --json` prints either a workspace-level snapshot `{workspaceRoot, config, sessionRuntime, running[], latestFinished, recent[], needsReview}` or a single-job snapshot `{workspaceRoot, job}` (with `waitTimedOut`, `timeoutMs` when `--wait`); `result --json` prints `{job, storedJob}` where `storedJob` includes the full per-job state file fields (status, threadId/turnId, result payload, rendered text, etc.). For Q8, the documented Claude Code pattern is the `${CLAUDE_PLUGIN_ROOT}` / `${CLAUDE_PLUGIN_DATA}` substitution variables, with documented limitations (no expansion in command markdown, not populated for SessionStart in some versions) that drive several alternative patterns (PATH lookup, npx-shipped binaries, data-dir installs, helper resolver scripts).

**Key findings:**
- `status --json` returns a different shape depending on whether a `[job-id]` positional is present.
- The single-job shape is `{workspaceRoot, job: <enrichedJob>}`, plus `waitTimedOut: bool` and `timeoutMs: number` if `--wait` was supplied.
- The workspace shape is `{workspaceRoot, config, sessionRuntime: {mode,label,detail,endpoint}, running: [...], latestFinished: <enrichedJob|null>, recent: [...], needsReview: bool}`.
- An `enrichedJob` adds `kindLabel`, `progressPreview` (string array, only for queued/running/failed), `elapsed`, `duration`, and `phase` to the persisted job record.
- `result --json` returns `{job, storedJob}`. `storedJob` is the JSON file written by `writeJobFile`/`runTrackedJob` with status, phase, threadId, turnId, completedAt, errorMessage (on failure), and `result` (the full execution payload) plus `rendered` (string).
- For Q8: `${CLAUDE_PLUGIN_ROOT}` is the documented Anthropic-supported pattern, expanded inline in hooks JSON, MCP/LSP configs, monitor commands, skill/agent content, and exported as an env var to hook subprocesses; `${CLAUDE_PLUGIN_DATA}` is the persistent sibling for installed deps.
- Documented gotchas: variable does NOT expand in command markdown files (issue 9354); not populated for SessionStart hooks in some versions (issue 27145); cache path can point to stale version after update (issue 15642); tradeoffs vs PATH lookup are version drift vs portability.

**Surprises:** `result --json` carries the full execution `result` payload AND the `rendered` text inside `storedJob`, so callers can choose either machine-readable or pre-rendered output without re-running the job.

**Caveats:** Source read locally from `/Users/dfrysinger/.claude/plugins/cache/openai-codex/codex/1.0.4/scripts/codex-companion.mjs` and its `lib/*.mjs` siblings — that is plugin version 1.0.4. Field naming may differ in other versions; upstream source on GitHub was not consulted. Q8 prior art summary draws on Anthropic docs and known issues; specific user-reported workarounds (helper resolver scripts in /tmp) are documented in issue threads but not formalized.

## Full findings

### Q7: codex-companion.mjs response shapes

Source: `/Users/dfrysinger/.claude/plugins/cache/openai-codex/codex/1.0.4/scripts/codex-companion.mjs` (1027 lines) and `lib/job-control.mjs`, `lib/tracked-jobs.mjs`, `lib/state.mjs`, `lib/codex.mjs`.

Pretty-printed JSON output is produced by `outputResult` (companion.mjs:88-94) using `JSON.stringify(value, null, 2)`. `outputCommandResult(payload, rendered, asJson)` (companion.mjs:96-98) selects `payload` when `asJson` is true.

#### `status --json`

Two shapes depending on whether a job reference positional is supplied.

**Shape A — workspace snapshot (no positional, e.g. `status --json` or `status --all --json`).** Built by `buildStatusSnapshot` (lib/job-control.mjs:213-240):

```
{
  "workspaceRoot": "<absolute path>",
  "config": { ...persisted config object loaded by getConfig(workspaceRoot)... },
  "sessionRuntime": {
    "mode": "shared" | "direct",
    "label": "shared session" | "direct startup",
    "detail": "<human description>",
    "endpoint": "<broker endpoint url> | null"
  },
  "running": [ <enrichedJob>, ... ],         // jobs with status "queued"|"running"
  "latestFinished": <enrichedJob> | null,    // most recent non-active job
  "recent": [ <enrichedJob>, ... ],          // other finished jobs (slice up to maxJobs unless --all)
  "needsReview": <boolean>                    // mirrors config.stopReviewGate
}
```

`config` keys observed in the codebase include `stopReviewGate` and `reviewName` (lib/job-control.mjs:238; lib/codex.mjs review handling) but the shape is whatever `getConfig` returns from state.json.

**Shape B — single-job snapshot (with positional, e.g. `status <job-id> --json`).** Built by `buildSingleJobSnapshot` (lib/job-control.mjs:242-254). When `--wait` is supplied, `waitForSingleJobSnapshot` (companion.mjs:315-331) augments it.

```
{
  "workspaceRoot": "<absolute path>",
  "job": <enrichedJob>,
  "waitTimedOut": <boolean>,   // ONLY when --wait was passed
  "timeoutMs": <number>        // ONLY when --wait was passed
}
```

**`enrichedJob` shape** (lib/job-control.mjs:161-181, applied on top of the base job record). Base persisted fields come from `runTrackedJob` (lib/tracked-jobs.mjs:142-204), `createCompanionJob` (companion.mjs:564-575), and `enqueueBackgroundTask` (companion.mjs:654-679):

```
{
  // Base persisted fields
  "id": "<prefix>-<generated>",          // e.g. "task-...", "review-...", "rescue-..."
  "kind": "task" | "review" | "rescue" | <other>,
  "kindLabel": "<human label>",
  "title": "<string>",
  "summary": "<string>",
  "workspaceRoot": "<absolute path>",
  "jobClass": "task" | "review",
  "createdAt": "<ISO8601>",
  "updatedAt": "<ISO8601>",
  "startedAt": "<ISO8601> | undefined",
  "completedAt": "<ISO8601> | null | undefined",
  "cancelledAt": "<ISO8601> | undefined",     // present only on cancel
  "status": "queued" | "running" | "completed" | "failed" | "cancelled",
  "phase": "queued"|"starting"|"investigating"|"reviewing"|"verifying"|
           "running"|"editing"|"finalizing"|"done"|"failed"|"cancelled",
  "pid": <number|null>,
  "threadId": "<string|null>",
  "turnId": "<string|null>",
  "logFile": "<absolute path|null>",
  "errorMessage": "<string>",                  // present on failed/cancelled
  "sessionId": "<claude session id>",          // present iff env was set at create time
  "request": { ... },                          // queued task records carry the original request

  // Fields added by enrichJob
  "progressPreview": [ "<log line>", ... ],    // [] unless status is queued|running|failed
  "elapsed": "<formatted duration>",
  "duration": "<formatted duration>" | null    // null while still running
}
```

The `phase` value is computed from progress events by `createJobProgressUpdater` (lib/tracked-jobs.mjs:70-115); when missing on legacy records, `inferLegacyJobPhase` (lib/job-control.mjs:109-159) substitutes one based on log-line heuristics.

#### `result --json`

Built by `handleResult` (companion.mjs:867-883):

```
{
  "job": <enrichedJob_subset>,   // The state.json index entry for the matched job (no enrichJob applied here)
  "storedJob": <jobFileContents | null>
}
```

`job` here is the resolved state.json record returned by `resolveResultJob` (lib/job-control.mjs:256-279), filtered to terminal statuses (`completed | failed | cancelled`). It is NOT passed through `enrichJob` for the result subcommand, so it lacks `progressPreview`/`elapsed`/`duration`. It contains the upserted index fields written via `upsertJob`.

`storedJob` is the per-job file written by `writeJobFile`/`readStoredJob` (lib/state.mjs:166-175; lib/job-control.mjs:183-189). On successful completion (lib/tracked-jobs.mjs:158-168) the file contains:

```
{
  // Spread of running record
  "id": "...", "kind": "...", "kindLabel": "...", "title": "...", "summary": "...",
  "workspaceRoot": "...", "jobClass": "...", "createdAt": "...", "sessionId": "...",
  "startedAt": "<ISO8601>",
  "phase": "starting" | "done" | "failed",
  "logFile": "<absolute path|null>",

  // Updated on completion
  "status": "completed" | "failed" | "cancelled",
  "threadId": "<string|null>",
  "turnId": "<string|null>",
  "pid": null,
  "completedAt": "<ISO8601>",
  "errorMessage": "<string>",                  // ONLY on failed/cancelled
  "cancelledAt": "<ISO8601>",                  // ONLY on cancelled (companion.mjs:946-960)
  "result": <executionPayload>,                // ONLY on success — full payload from executeReviewRun/executeTaskRun
  "rendered": "<string>"                       // ONLY on success — pre-rendered terminal output
}
```

The `result` field for review jobs (companion.mjs:372-403, 419-456) contains:
```
{
  "review": "<reviewName>",
  "target": <targetObject>,
  "threadId": "...", "sourceThreadId": "...",  // sourceThreadId only for native reviews
  "codex": { "status": <int>, "stderr": "...", "stdout": "...", "reasoning": "..." },
  "result": <parsedStructuredOutput>           // adversarial-review path only
}
```

For task jobs (companion.mjs:495-515) `result` contains:
```
{
  "status": <int>,
  "threadId": "...",
  "stdout": "<rawOutput>",
  "touchedFiles": [...],
  "reasoningSummary": "..."
}
```

When `result` is invoked without a positional but no finished jobs exist, the command throws (lib/job-control.mjs:278). When the matched reference is still active, an error is thrown directing the caller to use `status` (lib/job-control.mjs:269-272).

### Q8: Portable helper-path resolution patterns

#### Pattern 1 — `${CLAUDE_PLUGIN_ROOT}` substitution (Anthropic-documented)

Source: https://code.claude.com/docs/en/plugins-reference (section "Environment variables").

> "`${CLAUDE_PLUGIN_ROOT}`: the absolute path to your plugin's installation directory. Use this to reference scripts, binaries, and config files bundled with the plugin. This path changes when the plugin updates, so files you write here do not survive an update."

Expansion contexts (verbatim from docs): "substituted inline anywhere they appear in skill content, agent content, hook commands, monitor commands, and MCP or LSP server configs. Both are also exported as environment variables to hook processes and MCP or LSP server subprocesses."

Tradeoffs:
- Portable across install methods (marketplace, `claude --plugin-dir`, npm-distributed marketplace).
- Path string changes per version: `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/...`. State written there is wiped on update.
- Documented expansion gap: NOT expanded in slash-command markdown files. See https://github.com/anthropics/claude-code/issues/9354.
- Documented hook-event gap: `CLAUDE_PLUGIN_ROOT` not populated for `SessionStart` hooks in some versions. See https://github.com/anthropics/claude-code/issues/27145 and https://github.com/affaan-m/everything-claude-code/issues/256.
- Cache-staleness gap: after update, the env var can briefly point at a previous version directory in some configurations. See https://github.com/anthropics/claude-code/issues/15642.

#### Pattern 2 — `${CLAUDE_PLUGIN_DATA}` for persistent helpers/dependencies (Anthropic-documented)

Same source: code.claude.com/docs/en/plugins-reference.

> "`${CLAUDE_PLUGIN_DATA}`: a persistent directory for plugin state that survives updates. Use this for installed dependencies such as `node_modules` or Python virtual environments, generated code, caches, and any other files that should persist across plugin versions."

Tradeoffs:
- Survives plugin upgrades (resolves to `~/.claude/plugins/data/<plugin-id>/`).
- Requires a manifest-diff bootstrap step in a SessionStart hook to install/refresh — Anthropic's documented recipe diffs `${CLAUDE_PLUGIN_ROOT}/package.json` against `${CLAUDE_PLUGIN_DATA}/package.json` and runs `npm install` on mismatch.
- Adds first-run latency and creates a CI-relevant dependency on `npm` being on PATH at hook execution time.
- Removed automatically on uninstall (unless `--keep-data`).

#### Pattern 3 — PATH lookup of an externally installed binary

Pattern: hook/command invokes a tool by bare name (`codex`, `node`, `npm`) and relies on the operator's PATH.

Tradeoffs:
- Easiest to write; works identically across local-dev, plugin install, and CI.
- Version drift: per-project Node managers (mise, nvm, asdf) can return a different active version per directory, leading to "npm 10.x in terminal but my scripts behave like 8.x" mismatches (https://thelinuxcode.com/how-to-check-your-npm-version-and-confirm-its-the-right-one/).
- Unhandled "tool missing" cases must be detected and reported by the plugin itself (the codex-companion does this in `ensureCodexAvailable`).
- CI runners typically need an explicit setup step (`actions/setup-node`, `setup-python`) before the plugin's hooks fire.

#### Pattern 4 — npm "packageManager" field / Corepack pinning

Source: https://medium.com/@ademyalcin27/npm-supply-chain-quick-check-pinning-guide-3a76157e636d (and Node.js Corepack docs).

> "The packageManager field in package.json can instruct Corepack to always use a specific version on a project, which is useful for reproducibility as all developers using Corepack will use the same version."

Tradeoffs:
- Reproducible across developers and CI when Corepack is enabled.
- Only addresses the package-manager binary, not the helper script itself.
- Adds Corepack as a precondition; older Node versions disable it by default.

#### Pattern 5 — Self-contained packaged executable

Source: https://pnpm.io/installation — pnpm ships both `pnpm` (needs Node) and `@pnpm/exe` (Node bundled inside).

Tradeoffs:
- Eliminates runtime version drift entirely; binary is hermetic.
- Larger plugin payload; per-OS/arch artifacts; signing/notarization burden on macOS/Windows.
- Updates require redistribution rather than language-package update.

#### Pattern 6 — `node_modules/.bin` PATH augmentation via npm scripts

Source: https://www.keithcirkel.co.uk/how-to-use-npm-as-a-build-tool/ — npm scripts add `node_modules/.bin` to PATH.

Tradeoffs:
- Works only when the entry point is an npm script (`npm run helper`); not available when a hook directly executes a script.
- Couples invocation to `npm` being installed and `node_modules` being populated (drives Pattern 2 dependency).

#### Pattern 7 — Helper resolver script written to `/tmp`

Source: workaround referenced in https://github.com/anthropics/claude-code/issues/9354 and downstream community threads, due to `${CLAUDE_PLUGIN_ROOT}` not expanding in command markdown.

Pattern: a small script (often Python or shell) is generated under `/tmp/` that knows how to locate the plugin root by walking known cache paths (`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>`) and prints it.

Tradeoffs:
- Bypasses the markdown-expansion gap.
- `/tmp` cleanup, version race conditions on update, and discovery logic must handle multiple installed versions.
- Not formally specified — implementation differs across community plugins.

#### Pattern 8 — Distribution-package conflicts

Source: https://github.com/nodejs/node/issues/29798 — RPM-distributed Node vs `npm install -g` clobbering `/usr/lib/node_modules/`.

Tradeoffs:
- Affects Linux distro-packaged installs where helper binaries live in system paths the package manager will overwrite on upgrade.
- Argues for keeping helpers inside `${CLAUDE_PLUGIN_ROOT}` rather than relying on `npm install -g` placement.

## Sources

- /Users/dfrysinger/.claude/plugins/cache/openai-codex/codex/1.0.4/scripts/codex-companion.mjs
- /Users/dfrysinger/.claude/plugins/cache/openai-codex/codex/1.0.4/scripts/lib/job-control.mjs
- /Users/dfrysinger/.claude/plugins/cache/openai-codex/codex/1.0.4/scripts/lib/tracked-jobs.mjs
- /Users/dfrysinger/.claude/plugins/cache/openai-codex/codex/1.0.4/scripts/lib/state.mjs
- /Users/dfrysinger/.claude/plugins/cache/openai-codex/codex/1.0.4/scripts/lib/codex.mjs
- https://code.claude.com/docs/en/plugins-reference
- https://github.com/anthropics/claude-code/issues/9354
- https://github.com/anthropics/claude-code/issues/27145
- https://github.com/anthropics/claude-code/issues/15642
- https://github.com/affaan-m/everything-claude-code/issues/256
- https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/hook-development/SKILL.md
- https://medium.com/@ademyalcin27/npm-supply-chain-quick-check-pinning-guide-3a76157e636d
- https://pnpm.io/installation
- https://www.keithcirkel.co.uk/how-to-use-npm-as-a-build-tool/
- https://thelinuxcode.com/how-to-check-your-npm-version-and-confirm-its-the-right-one/
- https://github.com/nodejs/node/issues/29798
- https://nesbitt.io/2025/12/05/package-manager-tradeoffs.html
- https://mise.jdx.dev/getting-started.html
