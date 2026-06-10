# Reviewer Dispatch (shared)

With `$REVIEW_STEP`, `$REVIEW_ROUND`, `$REVIEW_OUTPUT_DIR`, `$REVIEW_ARTIFACT`, and `$REVIEW_AGENTS` set by the per-skill preamble above, run:

```sh
scripts/dispatch-agent.sh --step "$REVIEW_STEP" --round "$REVIEW_ROUND" \
  --output-dir "$REVIEW_OUTPUT_DIR" --artifact "$REVIEW_ARTIFACT" \
  --agents "$REVIEW_AGENTS"
```

`dispatch-agent` emits M lines on stdout (one per first-party reviewer; zero lines for a third-party-only batch). Each line has the form:

```
MODE=first_party TAG=<tag> SUBAGENT_TYPE=<agent-name> MODEL=<resolved-model> PROMPT_FILE=<absolute-path>
```

**For every emitted spec line, invoke the Task tool with these arguments (parse the line as space-separated `KEY=VALUE` pairs; values contain no spaces):**

- `subagent_type` = the `SUBAGENT_TYPE` value, verbatim
- `model` = the `MODEL` value, verbatim
- `prompt` = the literal string `"DISPATCH_FILE=<PROMPT_FILE-value>"` — a single-line env-var-style reference; the prompt argument has no other content

**Invoke all M Task tool calls in parallel in one orchestrator response** (one Task call per spec line). The reviewer agent body's first instruction is to `Read` its `DISPATCH_FILE` — do not pre-Read the file yourself; the dispatch context belongs in the subagent's window, not the orchestrator's.

**Iron law (orchestrator-side dispatch contract):** invoke the Task tool exactly once per emitted spec line, with `SUBAGENT_TYPE`, `MODEL`, and `PROMPT_FILE` copied verbatim. Skipping a line, deduplicating across lines, modifying any value, or substituting a different subagent_type is a contract violation. The dispatch manifest (`$REVIEW_OUTPUT_DIR/.dispatch-manifest.json`) records expected dispatches; the apply-fix step's "expected tag produced no output" diagnostic catches missed or mis-routed Task invocations.

**Capture each Task return value to disk before draining.** After each Task call returns, write the subagent's reply text (the full Task return string) to `$REVIEW_OUTPUT_DIR/.dispatch/<TAG>.raw` using the `create` tool, where `<TAG>` is the `TAG` value from the corresponding spec line. This is mandatory regardless of whether the subagent appeared to write per-finding files itself. Rationale: when a subagent cannot use the Write tool (read-only sandbox; missing `allowed-tools` entry; tool denial at runtime) it emits findings via the `<<<FINDING-BOUNDARY>>>` stdout contract instead. `await-round.sh` recovers those findings via a universal stdout-fallback that reads `.dispatch/<TAG>.raw` and pipes it through `third-party-finding-splitter.sh`; without the captured `.raw` file the fallback has nothing to work with and the round looks (incorrectly) clean.

After all Task tool calls return AND all `.raw` captures are written (Task tool is synchronous; first-party subagents with working Write tools have already written their per-finding files by this point), drain any third-party background dispatches and finalize the round:

```sh
scripts/await-round.sh --round-dir "$REVIEW_OUTPUT_DIR"
```

`await-round` is no-op-safe — first-party-only rounds still call it; it returns immediately after reading the manifest. It writes a small `$REVIEW_OUTPUT_DIR/.round-complete.json` summary and (for third-party dispatches OR any entry that produced no per-finding files but has a `.dispatch/<TAG>.raw` capture) materializes per-finding files via `third-party-finding-splitter.sh`. It does NOT echo captured subagent payloads (CD-1 #4 output-bound contract).

Then read `$REVIEW_OUTPUT_DIR/.round-complete.json` and the per-finding files as needed for apply-fix. The raw per-reviewer prompt content (assembled by dispatch-agent into `PROMPT_FILE`) never enters the orchestrator's context — only the small spec lines + the small `DISPATCH_FILE` references passed to Task.
