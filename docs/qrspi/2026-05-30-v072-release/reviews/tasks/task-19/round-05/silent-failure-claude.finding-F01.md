---
finding_id: R5-F01
reviewer_tag: silent-failure-claude
round: 5
severity: medium
change_type: additive-test
referenced_files: [tests/unit/test-routing-matrix-application.bats]
model: claude-sonnet-4.6
---

Success-path test silently discards stderr; broken halt-and-continue would be invisible.
test-routing-matrix-application.bats:654 — the new resolve_second_reviewer_vendor SUCCESS-path test redirects `2>/dev/null`, asserting exit 0 + one stdout line + stdout=openai-codex, but makes NO assertion that stderr is empty. resolve_second_reviewer_vendor is the single enforcement point for the primary-not-equal-second invariant; both halt branches follow `printf '...' >&2; return 1`. If a guard regresses to emit-and-continue (printf to stderr WITHOUT the matching return 1, or an accidental return 0 after the diagnostic) on this SUCCESS call site ('claude-code','anthropic-claude'), the test still passes (exit 0, 1 stdout line, value openai-codex) — the leaked stderr diagnostic is invisible. Existing halt-path tests exercise DIFFERENT call sites and cannot catch emit-and-continue on the success call site. Fix (test-only additive): capture stderr to a file and assert `[ "$stderr_lines" -eq 0 ]`.
