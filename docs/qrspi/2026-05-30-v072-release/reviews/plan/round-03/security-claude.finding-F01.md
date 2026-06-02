---
finding_id: F01
reviewer: security-claude
round: 3
artifact: plan.md
change_type: correctness
severity: high
task_refs: [T11]
---

# F01 — T11 dispatch-manifest provenance has no spoofing-resistance test expectations

## Summary

Task 11 introduces `dispatch_spec.{subagent_type,host,vendor,model,prompt_file}` in
`.dispatch-manifest.json` so reviewer dispatch is "auditable end-to-end." That framing
is **load-bearing for security** — downstream verifier and post-hoc auditors will rely on
these fields to decide which model produced which finding. But the task's Test
Expectations cover only **presence**, **append-safety**, and **well-formedness of JSON**.
They do not require that the values be authentic, trusted-sourced, or
unspoofable by the very dispatch input the manifest is supposed to audit.

## Specific gaps in T11 Test Expectations (lines 713–718)

1. **No "trusted-source" test.** The four expectations exercise dispatch and inspect
   the manifest. None pins where each field MUST be sourced from (e.g. resolver
   output / process-controlled environment) vs where it MAY come from caller-supplied
   CLI flags or prompt-file content. If `--vendor=foo` (or any analogous flag) is
   accepted from the dispatch caller and written straight into the manifest, a hostile
   prompt or upstream agent can label its own dispatch as a different vendor/model in
   the audit log. The plan never says "values must come from the same resolver that
   actually selected the dispatch" or "values are validated against the
   `model_routing:` resolved tuple."

2. **No enum / format validation.** `vendor` and `host` have a known closed set
   (Copilot CLI / Claude Code / future Codex CLI / `openai-codex` / `anthropic` / etc.
   per T19 and T16). The DoD does not require rejecting out-of-enum values, nor does
   the test list a malformed-host/vendor rejection case. An attacker who controls any
   input that flows into these fields can write arbitrary strings (`"unknown"`,
   `"trusted-source"`, `"approved"`) into the audit trail.

3. **No JSON-injection / control-character test.** Manifest writes are required to be
   "atomic and append-safe," but the task does not pin escape semantics. If
   `subagent_type` or `prompt_file` can carry a quote, backslash, or newline (path with
   `"` or `\n` in it is unusual but possible on some filesystems and trivially possible
   in a deliberate fixture), the implementer's first instinct may be string
   concatenation rather than a JSON encoder. There is no fixture that includes
   metacharacter-bearing values and verifies the resulting manifest still parses as a
   single well-formed JSON document with the literal value preserved. Without this
   test, the implementation can silently produce invalid JSON or fields that escape
   their own context.

4. **No `prompt_file` canonicalization gate.** T21 adds canonicalization
   (`assert_path_under_repo_root`) **only** to `dispatch-agent.sh`. T11 modifies
   `scripts/run-codex-review.sh` (the pre-rename script) and writes `prompt_file`
   into the manifest. The plan's dependency chain is T11 → T20 (rename) → T21
   (hardening); after T21 lands, the path that the dispatch script accepts will be
   canonicalized. But T11's DoD/Test Expectations should still pin that the value
   written into `dispatch_spec.prompt_file` is the **canonicalized** path (the one
   the script will actually read), not the raw caller-supplied lexical path. Today,
   the only assertion is "manifest contains a `prompt_file` field" — a path
   that's been rejected by T21's guard or a symlink that was rewritten to its
   realpath could still appear in the manifest under whatever string the caller
   passed, making the audit trail unreliable.

## Why this matters at plan level

The release Phase 1 Acceptance Criteria block (line 22) commits to fail-loud
behavior on "misrouted `model_routing` entries" and "the path-filter exfil guard."
The dispatch manifest is the only after-the-fact instrument the verifier and human
auditors have for spotting that an entry **did** route correctly. If a reviewer
agent (especially a third-party one) can rewrite its own `dispatch_spec` block, the
release's audit story collapses silently — no fail-loud surface fires. The
implementer will build exactly what T11 specifies; today T11 specifies "field
appears" and nothing about authenticity.

## Recommended remediation (do not require any specific wording)

Add to T11 Test Expectations:

- A fixture proving each `dispatch_spec` field is read from the resolver / locked
  environment, not from a flag the dispatch caller controls — or, if any field is
  caller-controlled by design, a fixture proving that field is validated against
  the resolved-tuple before write and rejected (non-zero exit, no manifest
  append) on mismatch.
- A vendor/host enum-validation fixture rejecting out-of-set values with a
  diagnostic.
- A metacharacter-bearing-value fixture verifying the manifest remains valid JSON
  and the literal value round-trips through a JSON parser.
- A `prompt_file` fixture proving the manifest records the canonical (post-realpath)
  path, not the raw caller string, when those differ.

## Files / sections to update

- `plan.md` Task 11 → **Test expectations** block (currently lines 713–718).
- `plan.md` Task 11 → **Definition of done** (currently lines 707–711) — add
  explicit "values are sourced from <resolver/locked-env>" and "JSON escape
  invariant" bullets so the implementer knows the intent.
