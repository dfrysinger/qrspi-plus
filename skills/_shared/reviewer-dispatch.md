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

## Subagent-dispatch fan-out

For every emitted spec line, issue one subagent dispatch. Parse the line as space-separated `KEY=VALUE` pairs; values contain no spaces. Pass:

- `subagent_type` = the `SUBAGENT_TYPE` value, verbatim.
- `model` = the `MODEL` value, verbatim.
- `prompt` = the literal string `"DISPATCH_FILE=<PROMPT_FILE-value>"` — a single-line env-var-style reference. The prompt argument has no other content.

**Issue all M subagent dispatches in parallel in one orchestrator response.** One dispatch per spec line. The reviewer agent body's first instruction is to `Read` its `DISPATCH_FILE`. Do not pre-Read the file yourself; the dispatch context belongs in the subagent's window, not the orchestrator's.

**Iron law (orchestrator-side dispatch contract).** Issue exactly one subagent dispatch per emitted spec line, with `SUBAGENT_TYPE`, `MODEL`, and `PROMPT_FILE` copied verbatim. Skipping a line, deduplicating across lines, modifying any value, or substituting a different subagent_type is a contract violation. The dispatch manifest at `$REVIEW_OUTPUT_DIR/.dispatch-manifest.json` records expected dispatches; the apply-fix step's "expected tag produced no output" diagnostic catches missed or mis-routed dispatches.

## Capture first-party reply text to disk before draining

Each first-party subagent's reply lives only in main-chat context — no script can recover it later. After each dispatch returns, write the full reply text to `$REVIEW_OUTPUT_DIR/.dispatch/<TAG>.raw` with the `create` tool, where `<TAG>` is the `TAG` from the corresponding spec line — even when the subagent appears to have written per-finding files itself.

When a subagent can't use the Write tool (read-only sandbox; missing `allowed-tools` entry; runtime tool denial) it emits findings via the `<<<FINDING-BOUNDARY>>>` stdout contract instead, and `await-round.sh`'s universal stdout-fallback recovers them by piping `.dispatch/<TAG>.raw` through `third-party-finding-splitter.sh`. Without the `.raw` capture the fallback has nothing to work with and the round looks falsely clean. Third-party dispatches skip this step — `dispatch-companion.sh` already captures their stdout to disk.

## Drain and finalize

After all subagent dispatches return AND all `.raw` captures are written, drain any third-party background dispatches and finalize the round:

```sh
scripts/await-round.sh --round-dir "$REVIEW_OUTPUT_DIR"
```

`await-round` is no-op-safe. First-party-only rounds still call it; it returns immediately after reading the manifest. It writes `$REVIEW_OUTPUT_DIR/.round-complete.json` and (for third-party dispatches OR any entry that produced no per-finding files but has a `.dispatch/<TAG>.raw` capture) materializes per-finding files via `third-party-finding-splitter.sh`. It does NOT echo captured subagent payloads.

Then read `$REVIEW_OUTPUT_DIR/.round-complete.json` and the per-finding files as needed for apply-fix. The raw per-reviewer prompt content (assembled by `dispatch-agent` into `PROMPT_FILE`) never enters the orchestrator's context — only the small spec lines plus the small `DISPATCH_FILE` references passed to Task.
