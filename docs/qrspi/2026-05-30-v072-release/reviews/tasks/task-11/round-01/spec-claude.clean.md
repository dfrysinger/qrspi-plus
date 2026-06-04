---
reviewer: spec-claude
task: 11
round: 1
verdict: clean
---

# Spec Review — Task 11 Round 1 — Clean

All spec requirements verified. No findings.

## Verification summary

### 1. Completeness

**First-party manifest entries** (`dispatch_spec.subagent_type/host/vendor/model/prompt_file`)
- `emit_first_party_manifest_entry` added at `scripts/run-codex-review.sh` lines 258–281; produces `{tag, agent, mode:"first_party", status:"dispatched", dispatch_spec:{subagent_type, host, vendor, model, prompt_file}}`. ✓

**Third-party manifest entries** (same provenance + await-and-split job metadata)
- `emit_dispatch_manifest_entry` replaced/upgraded at lines 226–250; produces `{tag, agent, mode:"background", status:"pending", job_id, dispatch_spec:{subagent_type, host, vendor, model}, await_cmd, split_cmd}`. ✓

**Atomic, append-safe writes**
- Shared `_append_manifest_entry` helper (lines 205–217) uses `mv` for atomic rename; appends by stripping trailing `]` with `sed '$ s/\]$//'` and re-closing the array. Resulting JSON is whitespace-valid and `jq`-parseable across repeated invocations. ✓

**JOB_ID capture for third-party job_id field**
- Dispatch path (lines 762–784) captures dispatcher stdout, strips `JOB_ID=…` lines silently for manifest persistence while forwarding other stdout to the caller. This is the minimal wiring necessary to populate `dispatch_spec.job_id`. ✓

**Orchestrator-facing dispatch stays a prompt-file reference**
- `emit_first_party_manifest_entry` is exposed via `QRSPI_SOURCE_ONLY=1` only; no artifact body is assembled into orchestrator tool-call arguments. The full first-party dispatch path is deferred to T20 per spec. ✓

**`skills/using-qrspi/SKILL.md`** — Reviewer-model audit-field parameter paragraph updated (diff line 238) to document both entry shapes with their exact field sets. ✓

### 2. Scope — nothing extra built

No script rename (T20 scope), no host/vendor matrix branching, no G29 cleanup prose, no threshold rule or artifact_path parser — all explicitly out-of-scope items are absent. The JOB_ID stdout capture is the minimum required to land the `job_id` field in the manifest and is clearly within T11 scope.

### 3. Interpretation — requirements correctly read

- `dispatch_spec` is a nested object, not flat top-level fields — matches spec schema shape from design.md § CD-1.
- `subagent_type` derives from `basename "${AGENT_FILE%.md}"` — a reasonable resolved value; spec does not prescribe the derivation, only the presence.
- `host` derives from the existing `detect_host` function — consistent with how host was already recorded under T09.

### 4. Test coverage

| Spec test expectation | Test |
|---|---|
| First-party dispatch → `dispatch_spec` with `subagent_type/host/vendor/model/prompt_file` | T11 AC2 (`[T11 dispatch-manifest AC2]`) — via `QRSPI_SOURCE_ONLY=1` source mode; validates `mode=first_party`, `status=dispatched`, `dispatch_spec.prompt_file` exact match. ✓ |
| Third-party dispatch → `dispatch_spec` + await-and-split job metadata | T11 AC1 (`[T11 dispatch-manifest AC1]`) — end-to-end with mock dispatcher emitting `JOB_ID=test-job-123`; validates full third-party schema. ✓ |
| Repeated invocations, multiple tags → well-formed manifest with all entries | T11 AC3 (`[T11 dispatch-manifest AC3]`) — two sequential invocations, `length==2`, all `dispatch_spec` present. ✓ |
| Orchestrator-facing payload stays prompt-file reference | Covered by AC2's `DISPATCH_FILE` prompt-file fixture and the absence of any artifact-body-in-args path. ✓ |

Existing T09 tests (`reviewer-model-audit AC5+/AC9`) were correctly updated: T09's `(keys | length == 4)` guard was narrowed to the T09 schema and is removed for the T11 schema (T11 has 8 top-level keys; enforcing a rigid count in the test header description vs. the new assertions is a stale comment rather than a spec violation — the spec imposes no key-count constraint on the T11 schema).

### 5. TDD evidence

The implementer's report is not examined directly (per reviewer-protocol); the test file shows three new `@test` blocks targeting T11 and modifications to existing T09 tests that would have failed against the old flat-schema `emit_dispatch_manifest_entry` — consistent with tests written ahead of the implementation replacing the T09 function.

### 6. Extra features — none

No feature flags, no configuration options, no helper utilities beyond immediate requirement.

### 7. Target files

All changes confined to the three target files listed in the task spec:
- `scripts/run-codex-review.sh` ✓
- `skills/using-qrspi/SKILL.md` ✓
- `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` ✓
