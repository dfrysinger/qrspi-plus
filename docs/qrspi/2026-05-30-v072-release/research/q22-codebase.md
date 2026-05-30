---
status: draft
question_ids: [22]
research_type: codebase
---

# Q22: Task-tool transport branch — reviewer model substitution semantics and observability

## Summary

**TL;DR:** The task-tool transport branch, introduced in v0.7.1 (DKR7), documents two explicit transport paths — Copilot CLI task-tool and Claude Code shell-pipeline — and enforces a **no-silent-substitution** policy when the configured CLI is absent. When Codex is unavailable and `codex_reviews: true`, the dispatch aborts with a non-zero exit code rather than substituting an alternative model. No frontmatter field, audit log, or dispatch-side annotation captures a "substituted model identity" because substitution is prohibited by design; the observability hooks that exist (transport trace markers to stderr, `model:` fields in review artifacts, per-task telemetry, `persistence_note:` in clean files) record which configured model ran, not a substitute.

**Key findings:**
- The "task-tool transport branch" is documented in `skills/using-qrspi/SKILL.md:411–416` (prose) and implemented in `scripts/run-codex-review.sh:640–648`. Two branches: `[transport: task-tool]` (Copilot CLI, uses `agent_type: code-review`, `model: gpt-5.3-codex`) and `[transport: shell-pipeline]` (Claude Code, uses `scripts/run-third-party-llm.sh`). Each branch emits its trace marker to stderr exactly once at the call site that selects it.
- When `check_codex_available` returns non-zero for the detected host AND `codex_reviews: true`, `scripts/run-codex-review.sh:630–632` emits `[codex-unavailable] check_codex_available exit=<N> for host=<host> — aborting Codex dispatch` to stderr and exits with the exact non-zero code from `check_codex_available`. No substitute model is invoked; no fallback runs.
- A `[mismatch]` warning fires on ANY availability-vs-config disagreement (`skills/using-qrspi/SKILL.md:416`, `scripts/run-codex-review.sh:620–622`) but is warning-only — it does not block dispatch and does not change the exit code. This is the only stderr annotation when the detected host and the config disagree on Codex availability but `codex_reviews` is false.
- The broader dispatcher (`scripts/run-third-party-llm.sh`) also enforces no-silent-substitution: when `model_routing:` is absent or the resolved model would be empty, the dispatcher halts and reports the missing entry rather than silently routing to the host CLI's own fallback (`skills/using-qrspi/SKILL.md:470, 488, 501, 526`). This closes the G7b/#204 silent-fallback class.
- Observability for the model that actually ran is captured via: (1) `[transport: task-tool]` / `[transport: shell-pipeline]` stderr markers in `scripts/run-codex-review.sh:641, 645`; (2) optional `model:` frontmatter field in some per-round review artifacts (e.g., clean files at `docs/qrspi/2026-05-27-v071-hardening/reviews/tasks/task-02/round-03/*.clean.md` carry `model: gpt-5.3-codex`); (3) `Model:` fields in the per-task review log artifact specified in `skills/implement/SKILL.md:1236, 1279, 1298`; (4) `routing_decision:` object in the per-task telemetry JSON (`skills/implement/SKILL.md:580`); (5) `persistence_note:` on Codex-transport clean files (`docs/.../task-02/round-03/*.clean.md`). None of these capture a "substituted model" — there is no substitute to capture.

**Surprises:** The system explicitly prohibits model substitution at every fallback point (absent `model_routing:`, absent `trusted_path:` agent-bundled default, Codex CLI unavailable) by halting and reporting rather than silently routing. This means the question's framing of "a substitute model used when the configured CLI is absent" does not match the actual design: there is no substitute path; absence causes abort, not fallback.

**Caveats:** The `model:` frontmatter field in `clean.md` review artifacts is not specified by the finding schema in `skills/reviewer-protocol/SKILL.md` (which lists five required finding fields but does not mandate a `model:` field on sentinels). The annotated clean files observed in the v0.7.1-hardening run appear to have been written by the orchestrator manually rather than by a schema-enforced contract. The reviewer-protocol SKILL.md does not document a required `model:` field on clean or finding files.

## Full findings

### Locations documenting the task-tool transport branch

**`skills/using-qrspi/SKILL.md:411–416`** (canonical prose)

This is the primary specification location. The section "**Per-host Codex dispatch transport routing**" names both transports:

- **Copilot CLI host (`COPILOT_CLI=1`):** Uses the native task tool. Dispatcher invokes the task tool with `agent_type: code-review` and `model: gpt-5.3-codex`. No shell pipeline involved — the task tool is the in-process transport. Emits `[transport: task-tool]` to stderr once at the call site.
- **Claude Code host (`COPILOT_CLI` unset):** Uses the shell-pipeline transport via `scripts/run-codex-review.sh`. Emits `[transport: shell-pipeline]` to stderr once at the call site.

**`scripts/run-codex-review.sh:640–648`** (implementation)

The actual dispatch branch:

```bash
if [[ "$_detected_host" == "copilot-cli" ]]; then
  echo "[transport: task-tool]" >&2
  ( set -o pipefail; compose_prompt | bash "$DISPATCHER" "${DISPATCHER_ARGS[@]}" )
  exit "$?"
else
  echo "[transport: shell-pipeline]" >&2
  ( set -o pipefail; compose_prompt | bash "$DISPATCHER" "${DISPATCHER_ARGS[@]}" )
  exit "$?"
fi
```

The two branches emit different trace markers but otherwise call the same dispatcher (`scripts/run-third-party-llm.sh`) with `--provider codex`. Transport selection within the dispatcher is config-driven from `config.md`'s `transport_type:` field under the `providers:` block (`codex-broker` or `openai-chat-completions`).

**`docs/qrspi/2026-05-27-v071-hardening/design.md:57–61`** (design decision DKR7)

Explicitly states: "Skill prose for Codex dispatches names BOTH transports explicitly." Model identifier `gpt-5.3-codex` is named as the Copilot CLI model routable via the task tool.

**`docs/qrspi/2026-05-27-v071-hardening/tasks/task-06.md:16, 30–31`** and **`task-07.md:16–27`** (task specifications)

Task-06 defines the implementation requirements for `detect_host` and `check_codex_available`. Task-07 defines the prose update to `skills/using-qrspi/SKILL.md`. Both task specs require the transport-distinguishing trace markers to appear in stderr and to be asserted in tests.

### Substitution semantics when the configured CLI is absent

**No substitute model is used.** The design's explicit policy, stated at multiple locations:

**`scripts/run-codex-review.sh:624–632`** (T7 short-circuit):

```bash
# check_codex_available short-circuit (T7): when Codex is unavailable but the
# run config requested Codex reviews, abort before invoking the transport.
if [[ "$_codex_available" == "false" && "$_codex_reviews" == "true" ]]; then
  echo "[codex-unavailable] check_codex_available exit=${_check_exit} for host=${_detected_host} — aborting Codex dispatch" >&2
  exit "$_check_exit"
fi
```

When `check_codex_available` returns non-zero (companion binary glob finds no files under `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs`), the shim emits a single-line `[codex-unavailable]` diagnostic and exits. No alternative model is dispatched. The exact non-zero exit code from `check_codex_available` is propagated unchanged.

**`scripts/run-codex-review.sh:142–191`** (`check_codex_available` function):

- `copilot-cli` host: always returns 0 (Codex is natively routable; no probe needed).
- `claude-code` host: probes the companion glob. Returns 0 if at least one matching `.mjs` file exists; returns 1 (non-zero) otherwise.

**`scripts/run-codex-review.sh:620–622`** (mismatch warning):

```bash
if [[ "$_codex_available" != "$_codex_reviews" ]]; then
  echo "[mismatch] detected host=${_detected_host} (codex available=${_codex_available}), codex_reviews config=${_codex_reviews}" >&2
fi
```

This fires on ANY availability-vs-config disagreement, including `codex_reviews: false` on a Copilot CLI host (where Codex is trivially available). It is warning-only and does not gate dispatch or change the exit code.

**`skills/using-qrspi/SKILL.md:416`** (prose for mismatch policy):

The skill documents that the mismatch diagnostic is warning-only and that the short-circuit (abort on unavailability + `codex_reviews: true`) is separate from the mismatch warning. These are independent mechanisms.

### Broader dispatcher no-silent-substitution policy

The universal dispatcher (`scripts/run-third-party-llm.sh`) branches on `transport_type:` from `config.md` (lines 674–682):

```bash
case "$TRANSPORT_TYPE" in
  openai-chat-completions)
    _dispatch_openai_chat ;;
  codex-broker)
    _dispatch_codex_broker ;;
  *)
    die "unknown transport_type '$TRANSPORT_TYPE' ..."
```

Any unknown transport exits 1 immediately; no model substitution occurs.

**`skills/using-qrspi/SKILL.md:470, 488, 501, 526`** document the G7b/#204 silent-fallback prohibition for the model-routing chain. All four entries state that the dispatcher "never falls back silently to the agent-bundled default and never passes the dispatch through to the host CLI's silent re-routing." When the model cannot be resolved (missing `model_routing:` block, empty agent-bundled default, absent `trusted_path:` match), the dispatcher **halts and reports** rather than substituting a model.

### Observability hooks that capture which model actually ran

**1. Transport trace markers (stderr) — `scripts/run-codex-review.sh:641, 645`**

`[transport: task-tool]` or `[transport: shell-pipeline]` is emitted to stderr exactly once per dispatch invocation. These indicate the selected transport path and (implicitly, via the documented model-per-branch contract) which model was requested. They do not appear in on-disk artifacts.

**2. `[codex-unavailable]` marker (stderr) — `scripts/run-codex-review.sh:631`**

Emitted when Codex is unavailable and `codex_reviews: true`. Identifies the host and the exit code from `check_codex_available`. Indicates an aborted Codex dispatch.

**3. `[mismatch]` marker (stderr) — `scripts/run-codex-review.sh:621`**

Emitted when the detected host's Codex availability disagrees with the `codex_reviews` config value. Identifies the detected host, availability result, and configured value. Does not indicate a substitute was used.

**4. `model:` field on some review artifact frontmatters (on-disk, not schema-required)**

In the v0.7.1-hardening run, per-round Codex `clean.md` files at `docs/qrspi/2026-05-27-v071-hardening/reviews/tasks/task-02/round-03/*.clean.md` carry `model: gpt-5.3-codex` in frontmatter. Similarly, `docs/qrspi/2026-05-27-v071-hardening/reviews/tasks/task-02/round-01/security-claude.clean.md` carries `model: claude-opus-4-5`. These are orchestrator-authored annotations. The reviewer-protocol finding schema (`skills/reviewer-protocol/SKILL.md:53–61`) mandates five fields on findings (`finding_id`, `severity`, `change_type`, `message`, `referenced_files`) but does NOT mandate a `model:` field on clean sentinels or finding files. The `model:` annotation in these artifacts is a practice observed in the v0.7.1 run but not formally required by the SKILL.

**5. `persistence_note:` field on Codex task-tool clean files (on-disk)**

Task-02 round-03 Codex clean files carry:
```
persistence_note: Codex agents under copilot-task-tool transport return findings in chat only — orchestrator manually persists per audit-trail discipline.
```
This documents that Codex findings via the task-tool transport are returned in main chat rather than written directly to disk, and that the orchestrator is responsible for materializing the on-disk record. This is an observability annotation about the transport behavior, not about model identity specifically.

**6. `Model:` fields in the per-task review log (on-disk, schema-specified for Claude-side logs)**

`skills/implement/SKILL.md:1236, 1279, 1298` specifies that the per-task review log written by the orchestrator to `<ABS_ARTIFACT_DIR>/reviews/tasks/task-NN/task-NN-review.md` MUST carry `**Model:** {actual model identifier, e.g., claude-opus-4-5}` for each reviewer section. The rule at line 1298 states "Model identifiers are actual — use the real model ID (e.g., `claude-opus-4-5`), not generic names." For skipped reviewers the field reads `**Model:** skipped`. For Codex subsections, the review log records a path reference to the per-reviewer per-round Codex file, not a model identifier inline.

**7. `routing_decision:` in per-task telemetry JSON (on-disk, schema-specified)**

`skills/implement/SKILL.md:580` specifies that every task emits `reviews/telemetry/round-NN/task-NN.json` containing a `routing_decision:` object naming `(role, provider, model, layer)` for the implementer dispatch, plus a `reviewer_routing_decisions:` array for reviewer dispatches.

### What is NOT captured

- There is no frontmatter field named `substituted_model`, `actual_model`, or `model_used` in the finding schema or clean sentinel schema.
- There is no audit log entry for "substitute model identity" because no substitution occurs — unavailability causes abort, not fallback.
- The `codex-finding-splitter.sh` script produces clean sentinels with only `reviewer:`, `round:`, and `findings: 0` fields (the splitter's `NO_FINDINGS` branch, `scripts/codex-finding-splitter.sh:42–51`). It does not inject a model field.
- The dispatch-side annotation for which model actually ran is the transport trace marker (`[transport: task-tool]` or `[transport: shell-pipeline]`) on stderr — this is ephemeral (not persisted to disk by any script), not a structured field in a log.
