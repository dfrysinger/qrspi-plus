---
finding_id: R6-F01
severity: medium
change_type: correctness
referenced_files:
  - structure.md (line 37, Slice 1.2 dispatch-agent.sh row)
  - structure.md (lines 270-296, §10 Dispatch manifest schema)
---

## Finding

Structure has an internal inconsistency between the Slice 1.2 File Map row for `scripts/dispatch-agent.sh` and Interface §10's dispatch manifest schema.

## Evidence

- **Line 37 (Slice 1.2 row):** "Add host/vendor/model metadata persistence into the dispatch manifest for later observability." (G20, G29)
- **§10 schema (~line 277):** `dispatch_spec` shows only `subagent_type`, `model`, `prompt_file` — no `host`, no `vendor` field.

The File Map row pins responsibility for persisting host/vendor/model metadata; the Interface schema declares only model. Plan/Implement implementing §10's JSON shape will produce manifests that omit host/vendor and fail the observability surface the row promises.

## Why this matters

The contract surface a planner consumes is the Interface schema, not the responsibility text in the File Map. An implementer reading §10 will not author host/vendor fields. Worse: the test row at line 96 (`test-routing-matrix-application.bats`) asserts "host-aware vendor routing" behavior — but the manifest schema gives no observability-side artifact to assert against.

## Suggested fix

Extend §10's `dispatch_spec` block with `host` and `vendor` fields in BOTH the first-party and background examples. Concrete shape (one possible form):

```json
"dispatch_spec": {
  "subagent_type": "qrspi-plan-reviewer",
  "host": "copilot-cli",      // detect_host output
  "vendor": "anthropic",       // first-party vendor identifier
  "model": "claude-sonnet-4.6",
  "prompt_file": "/abs/path/..."
}
```

Whatever the exact field names, they need to appear in §10 to match the Slice 1.2 row's persistence responsibility.

(Reviewer used `change_type: completeness` in chat-only return; orchestrator normalized to `correctness` per the 5-value enum schema — under-specified contract surface is a correctness gap, not a style/clarity/scope/intent gap.)

## Dispatch transport note

quality-codex (gpt-5.3-codex via code-review agent_type) returned this finding in chat-only output. Orchestrator hand-persisted per §3 verifier-round protocol's chat-only fallback handling.
