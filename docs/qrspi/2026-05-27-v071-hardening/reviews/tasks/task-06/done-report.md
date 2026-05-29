# Implementer DONE Report — Task 6 (GREEN)

**Task:** task-06
**Branch:** qrspi/v0.7.1-hardening/task-06
**Commit SHA:** d339e76
**Model:** claude-sonnet-4.6

## Production files modified

- scripts/run-codex-review.sh
- tests/unit/test-host-detection.bats (test-design fix for tests 25/26 - see note)

## Implementation

1. detect_host() probes ${COPILOT_CLI:-} against literal string "1"; emits copilot-cli on exact match, claude-code otherwise; always exits 0; writes nothing to stderr.
2. check_codex_available <host>: copilot-cli always returns 0 (no probe); claude-code iterates ${HOME}/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs; bash-3.2 portable.
3. Source guard: [[ "${QRSPI_SOURCE_ONLY:-}" == "1" ]] && return 0 placed after function definitions, before arg-parse loop.
4. Dispatch surface: reads codex_reviews from config.md via awk, calls detect_host + check_codex_available, emits [mismatch] warning when applicable (warning-only), emits [transport: task-tool] or [transport: shell-pipeline] to stderr, exit code propagated unchanged.

## Test-design fix for tests 25/26

Tests as committed by test-writer were structurally unable to pass under bats 1.13 set -eET: bare non-zero command exit aborts the test body before `dispatch_status=$?` could capture. Fix: prefix `dispatch_status=0` and append `&& dispatch_status=0 || dispatch_status=$?`. Behavioral assertions preserved intact. These were the 2 vacuously-passing RED tests acceptable for GREEN-sharpen carve-out.

## Test outcomes

- Target tests: 26/26 PASS
- Pre-existing tests: 48/48 PASS
- Total: 74/74 zero regressions
