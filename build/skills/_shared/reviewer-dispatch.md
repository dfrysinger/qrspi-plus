# Reviewer Dispatch (shared)

Verbatim reviewer-dispatch incantation. Single source of truth for orchestrator-side reviewer fan-out across every skill that runs a Review Round. Self-contained: do not chase cross-references for the dispatch contract — every rule the orchestrator must follow is below.

## Preamble (per-skill)

The consuming skill sets these shell variables before the dispatch:

- `$REVIEW_STEP` — canonical step name (e.g. `goals`, `design`, `plan`).
- `$REVIEW_ROUND` — zero-padded round number (e.g. `01`).
- `$REVIEW_OUTPUT_DIR` — absolute path to `<artifact-dir>/reviews/<step>/round-<NN>/`.
- `$REVIEW_ARTIFACT` — absolute path to the artifact under review.
- `$REVIEW_AGENTS` — comma-separated list of reviewer agent names for this step.

## Dispatch invocation

Run:

```sh
scripts/dispatch-agent.sh --step "$REVIEW_STEP" --round "$REVIEW_ROUND" \
  --output-dir "$REVIEW_OUTPUT_DIR" --artifact "$REVIEW_ARTIFACT" \
  --agents "$REVIEW_AGENTS"
```

`dispatch-agent` emits M lines on stdout — one per first-party reviewer; zero lines for a third-party-only batch. Each line has the form:

```
MODE=first_party TAG=<tag> SUBAGENT_TYPE=<agent-name> MODEL=<resolved-model> PROMPT_FILE=<absolute-path>
```

## Task-tool fan-out

For every emitted spec line, invoke the Task tool once. Parse the line as space-separated `KEY=VALUE` pairs; values contain no spaces. Pass:

- `subagent_type` = the `SUBAGENT_TYPE` value, verbatim.
- `model` = the `MODEL` value, verbatim.
- `prompt` = the literal string `"DISPATCH_FILE=<PROMPT_FILE-value>"` — a single-line env-var-style reference. The prompt argument has no other content.

**Invoke all M Task tool calls in parallel in one orchestrator response.** One Task call per spec line. The reviewer agent body's first instruction is to `Read` its `DISPATCH_FILE`. Do not pre-Read the file yourself; the dispatch context belongs in the subagent's window, not the orchestrator's.

**Iron law (orchestrator-side dispatch contract).** Invoke the Task tool exactly once per emitted spec line, with `SUBAGENT_TYPE`, `MODEL`, and `PROMPT_FILE` copied verbatim. Skipping a line, deduplicating across lines, modifying any value, or substituting a different subagent_type is a contract violation. The dispatch manifest at `$REVIEW_OUTPUT_DIR/.dispatch-manifest.json` records expected dispatches; the apply-fix step's "expected tag produced no output" diagnostic catches missed or mis-routed Task invocations.

## Capture each Task return value

Capture each Task return value to disk before draining. After each Task call returns, write the subagent's reply text (the full Task return string) to `$REVIEW_OUTPUT_DIR/.dispatch/<TAG>.raw` using the `create` tool. `<TAG>` is the `TAG` value from the corresponding spec line. This is mandatory regardless of whether the subagent appeared to write per-finding files itself.

Rationale: a subagent without working Write tools (read-only sandbox; missing `allowed-tools` entry; tool denial at runtime) emits findings via the `<<<FINDING-BOUNDARY>>>` stdout contract instead. `await-round.sh` recovers those findings via a universal stdout-fallback that reads `.dispatch/<TAG>.raw` and pipes it through `third-party-finding-splitter.sh`. Without the captured `.raw` file the fallback has nothing to work with and the round looks falsely clean.

## Drain and finalize

After all Task tool calls return AND all `.raw` captures are written, drain any third-party background dispatches and finalize the round:

```sh
scripts/await-round.sh --round-dir "$REVIEW_OUTPUT_DIR"
```

`await-round` is no-op-safe. First-party-only rounds still call it; it returns immediately after reading the manifest. It writes `$REVIEW_OUTPUT_DIR/.round-complete.json` and (for third-party dispatches OR any entry that produced no per-finding files but has a `.dispatch/<TAG>.raw` capture) materializes per-finding files via `third-party-finding-splitter.sh`. It does NOT echo captured subagent payloads.

Then read `$REVIEW_OUTPUT_DIR/.round-complete.json` and the per-finding files as needed for apply-fix. The raw per-reviewer prompt content (assembled by `dispatch-agent` into `PROMPT_FILE`) never enters the orchestrator's context — only the small spec lines plus the small `DISPATCH_FILE` references passed to Task.
