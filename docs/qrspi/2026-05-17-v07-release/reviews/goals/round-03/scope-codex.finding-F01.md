---
finding_id: R03-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/goals.md:L19, skills/goals/owns-defers.md:L12-L18]
artifact: goals
round: 03
reviewer: scope-codex
---

The Constraints section commits the evergreen-prose solution to "a lint or CI gate" and excludes per-PR human review. Goals may record environmental constraints and may list solution ideas as candidates under "What we know so far," but it defers detailed solution definitions and acceptance/test strategy to later artifacts. This line should be reframed as a problem-level constraint such as "evergreen-prose enforcement must be automated rather than relying only on manual review," leaving Design to decide whether the mechanism is BATS lint, CI, reviewer-side enforcement, or a layered approach.
