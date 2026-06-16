### Fix-altitude rule (F-5)

When fixing an "X is under-specified" finding, prefer minimal additions that stay at the artifact's altitude. If the natural fix pulls content from the next pipeline step (Design content into Goals; Plan content into Design; Implementation choices into Plan), that's a signal to defer specification rather than over-specify here. Add a one-line "[X] pinned in <next step>" note instead of pinning X exhaustively now. Reviewers who flag missing detail at the next-step altitude are misapplying their review brief — decline the finding with a one-line explanation in the round notes.

Why: pulling next-step detail upward inflates the artifact, introduces internal contradictions (the natural-language detail at this altitude often contradicts the structured detail at the next altitude), and produces R7-R10-style self-induced review churn — reviewers in subsequent rounds correctly flag the over-specification, the fix removes it, the cycle repeats. Minimal additions converge in 1–2 rounds; maximal additions can take 5+.

Mirrors the skill-refactor design's "decline scope-extension findings" rule, applied to artifact-level reviews.

### Sweep-task findings — backstop

Sweep-task findings (`agents/qrspi-plan-reviewer.md` § Sweep-task detection, per `skills/plan/SKILL.md` § Sweep Task Contract) are ordinary Plan-review correctness findings. When the reviewer surfaces a missing or malformed `dependent_tests:` field on a sweep-shaped task, the orchestrator routes it through the standard Plan re-spec loop documented above — no new implementation gate, no new test-runner behavior, no per-task pause: the producing task spec is updated to carry a well-formed `dependent_tests:` field, the next Plan review round re-verifies, and the loop terminates clean per the standard convergence rule.
