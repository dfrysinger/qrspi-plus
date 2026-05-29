# Implementer DONE Report — Task 1 (GREEN)

**Task:** task-01
**Mode:** implement (GREEN phase, prewritten_red_tests signal)
**Worktree:** .worktrees/qrspi-plus-v071/task-01/
**Branch:** qrspi/v0.7.1-hardening/task-01
**Commit SHA:** f38344d26ca71ca4730e0e7237871156bd611e88
**Model:** claude-sonnet-4.6

## Production files modified

- scripts/run-third-party-llm.sh

## Changes made

1. Added `_control_char_check()` helper function (placed before `_dispatch_openai_chat`). POSIX-clean, no `grep -P`, uses `LC_ALL=C tr -d '\040-\176'` to delete printable ASCII bytes; anything remaining is a control character. `wc -c` counts bytes from the `tr` pipe so LF inside arguments is correctly counted even though command-substitution would strip trailing newlines. The function is a self-contained block starting at `_control_char_check()` on its own line, extractable by awk for isolated test harness use.

2. Replaced the old `grep -qP '[\x00-\x1f\x7f]' 2>/dev/null` loop with two new steps inside the `openai-chat-completions` security pre-flight block:
   - NUL raw-byte pre-flight scan: compares `wc -c` of the raw config file to `wc -c` after `tr -d '\000'`; any byte-count delta means NUL bytes are present and triggers `header-validation` die before awk parsing (NUL is stripped by bash variable assignment so it never reaches `HEADER_NAMES`/`HEADER_VALUES`).
   - Per-header loop: calls `_control_char_check "$_hname" "$_hval"` for each parsed header.

## Test outcomes

- Target tests: 16/16 [control-char-detect] tests PASS
- Pre-existing tests in same file: 23/23 PASS (zero regressions)
- Full bats output: 39/39 ok

## Test-writer design gaps addressed

- TE-5 (LF coverage path): LF cannot reach HEADER_VALUES through the awk-based YAML parser (LF terminates config.md lines). The LF test exercises `_control_char_check` directly via function extraction; the helper handles LF-containing string arguments correctly via the tr-from-pipe wc-c byte-count technique.
- TE-6 (NUL coverage path): NUL is stripped by bash variable assignment so it never reaches HEADER_VALUES. The NUL test writes raw NUL bytes into `config.md` and the implementation performs a raw-byte scan (`wc -c` delta on `tr -d '\000'`) on the config file BEFORE awk parsing.
