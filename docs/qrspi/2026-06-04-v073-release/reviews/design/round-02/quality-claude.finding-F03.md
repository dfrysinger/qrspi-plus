---
finding_id: R2-F03
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/design.md:L726
  - docs/qrspi/2026-06-04-v073-release/design.md:L778-L779
artifact: design
round: 2
reviewer: quality-claude
---

G5 contains an internal contradiction about who owns the `GIT_AUTHOR_NAME=qrspi-<agent>` author-marker injection into subagent commits.

**G5 solution (L726–L727):** "Subagent commits carry the `qrspi-<agent-name>` author marker, injected by the dispatch chain (`scripts/dispatch-agent.sh` sets `GIT_AUTHOR_NAME=qrspi-<agent>` / `GIT_AUTHOR_EMAIL=bot@qrspi.local` via env wrapped around subagent git commands; mechanism detail deferred to Plan)."

**G5 acceptance (L789):** "scripts/dispatch-agent.sh (or its subagent-invocation chain) injects `GIT_AUTHOR_NAME=qrspi-<agent>` such that subagent commits in a synthetic fixture round carry the marker. Bats coverage by inspecting `git log --format='%an'`…" — this acceptance criterion is listed under G5, asserting G5 owns the injecting feature.

**G5 dependencies (L778–L779):** "The marker injection is **part of CD-2's review-prep / dispatch-agent chain**; sequencing CD-2 before G5 ensures the marker is available before the observability check fires."

These three statements conflict. The solution and acceptance criteria place the injection as a G5 deliverable. The dependency statement says CD-2 provides it. CD-2's solution (L436–L462) describes dispatch-agent gaining a "high-level entry mode" for review rounds — it makes no mention of `GIT_AUTHOR_NAME` injection. A plan-author reading this will not know which task to implement the injection in: CD-2 (per the dependency statement) or G5 (per the solution block and acceptance criteria). Under the current wording, both task authors might defer it to the other, or both might implement it, causing a conflict.

Fix: Remove the phrase "The marker injection is part of CD-2's review-prep / dispatch-agent chain" from G5's dependency section. Replace with a precise dependency statement: "CD-2 must land first so `scripts/dispatch-agent.sh`'s high-level mode is in place; G5 then adds the `GIT_AUTHOR_NAME` injection to that script." This makes G5 the clear owner and CD-2 the sequencing dependency.

