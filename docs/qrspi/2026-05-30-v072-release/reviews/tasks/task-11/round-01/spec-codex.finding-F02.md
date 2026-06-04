---
finding_id: R1-F02
reviewer: spec-codex
severity: med
change_type: scope
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats
---

# F02 — First-party dispatch acceptance test bypasses the dispatch path

**Spec expectation (task-11.md lines 45, 48):** "Exercise a first-party reviewer dispatch and inspect `.dispatch-manifest.json` for a `dispatch_spec` object … Acceptance coverage verifies the orchestrator-facing dispatch payload stays a prompt-file reference while the manifest records resolved host/vendor/model provenance."

**Implementation defect:** AC2 (tests/acceptance/v07-phase1/test-phase1-acceptance.bats lines 2311-2326) directly sources `scripts/run-codex-review.sh` via `QRSPI_SOURCE_ONLY=1` and invokes `emit_first_party_manifest_entry` as a function call. This exercises the manifest-emission helper in isolation; it does NOT drive the actual first-party dispatch path end-to-end.

**Coverage gaps:**
1. No assertion that the orchestrator-facing dispatch payload is the `DISPATCH_FILE=<PROMPT_FILE>` reference shape (or whatever the first-party spec-line form is). The spec calls this out explicitly: "Keep first-party orchestrator-facing dispatch payloads to the emitted spec line / `DISPATCH_FILE=<PROMPT_FILE>` reference shape."
2. No assertion that prompt-file assembly happens outside orchestrator tool-call arguments (the script writes the prompt file; the orchestrator only sees the reference).

**Fix sketch:** add an AC2-extended (or new AC4) that:
- Invokes the dispatch entry point that emits a first-party spec line (NOT the underlying helper directly).
- Captures stdout.
- Asserts stdout contains the `DISPATCH_FILE=<PROMPT_FILE>` reference (or whatever the first-party emission contract is).
- Reads the manifest and asserts the corresponding first-party entry exists with `dispatch_spec.prompt_file` pointing at the same file referenced on stdout.

**Disposition:** in scope for T11 — closes the spec's "acceptance coverage verifies orchestrator-facing dispatch payload stays a prompt-file reference" clause.
