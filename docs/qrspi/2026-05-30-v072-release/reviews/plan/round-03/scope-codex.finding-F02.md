---
reviewer_tag: scope-codex
change_type: scope
severity: medium
artifact: plan.md
location: Task 40 → Scope / Definition of done / Test expectations
referenced_files: [plan.md]
---

# F02 — Plan includes concrete test-assertion code and parser mechanics

Task 40 includes explicit assertion/code forms and parser-level mechanics in Plan: e.g., `[[ "$body" != *...* ]]`, `[ -n "$body" ]`, `^@test "..." \{`, and column-0 `}` parsing requirements (plan.md:2302-2304, 2316-2319, 2327-2330). These are not plain-language expectations; they are concrete assertion syntax and implementation mechanics.

This crosses Plan boundaries defined in owns-defers: full assertion text/test code belongs to Implement-TDD (`skills/plan/owns-defers.md:21`), and algorithm/control-flow details belong to Implement (`skills/plan/owns-defers.md:22`).
