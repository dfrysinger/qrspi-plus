---
reviewer: spec-codex
task: 1
round: 1
finding: F01
severity: blocking
change_type: scope
status: pending
model: gpt-5.3-codex
timestamp: 2026-05-28T18:32:00Z
agent_id: t01-r1-spec-codex
persistence_note: Codex agents under copilot-task-tool transport return findings in chat only — orchestrator manually persists per audit-trail discipline. See GH issue #213.
referenced_files:
  - tasks/task-01.md
  - tests/unit/test-run-third-party-llm.bats
---

## Task test coverage does not satisfy the "every C0 byte" requirement

**Spec requirement:** `tasks/task-01.md` requires that EVERY C0 byte (0x00-0x1F) in header value and header name be covered, and explicitly says extended coverage should pin each of the 33 control bytes (`tasks/task-01.md` lines 1370, 1372, 1373 in the dispatch prompt context — i.e. test expectation bullets that say "Every C0 control byte (0x00 through 0x1F) supplied as a header value causes the script to exit").

**Observed tests:** `tests/unit/test-run-third-party-llm.bats` only tests a subset for C0:
- Value-side C0 tests cover SOH, VT, ESC, US (test file lines 1089-1123)
- Name-side C0 tests cover SOH and CR (test file lines 1129-1145)
- LF and NUL are tested separately (test file lines 1183-1242), but most C0 bytes remain unpinned

**Why this fails spec (per Codex's reading):** The acceptance language is universal ("every C0 control byte"), but the suite only samples a few bytes, so the required exhaustive coverage is not met.

**Orchestrator counter-reading (for triage at apply-fix):** The implementation uses `LC_ALL=C tr -d '\040-\176'` which is regex-pattern-based — it deletes printable-ASCII bytes and treats every other byte (including all 32 C0 bytes) uniformly. Pinning 4 representative C0 bytes is structurally equivalent to pinning all 32 because the implementation does not have per-byte branches that could regress one byte without regressing the others. The test-writer treated "every" as "any from the equivalence class" with representative coverage.

The triage question for the human reviewer: is the spec's "every" intended as literal-exhaustive (32 separate tests) or as universal-quantified-over-an-equivalence-class (representative coverage acceptable)?
