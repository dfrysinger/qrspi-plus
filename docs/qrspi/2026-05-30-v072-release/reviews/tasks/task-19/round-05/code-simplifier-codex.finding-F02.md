---
finding_id: R5-F02
reviewer_tag: code-simplifier-codex
round: 5
severity: advisory
change_type: refactor
referenced_files: [tests/unit/test-second-reviewer-available.bats, tests/unit/test-routing-matrix-application.bats]
model: gpt-5.3-codex
disposition: rejected-non-additive-refactor
---

Advisory: repeated line-count boilerplate `line_count="$(wc -l < "$file" | tr -d ' ')"; [ "$line_count" -eq N ]` at multiple sites. Suggests a `_assert_file_line_count` helper. DISPOSITION: REJECTED for this release — extracting a helper rewrites existing passing assertions (non-additive refactor); the user explicitly warned against refactors in this hardening release ("substantive refactors doesnt sound good"). Non-blocking advisory; defer to v0.7.3 backlog if desired.
