---
finding_id: R1-F01
severity: high
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/goals.md:L20, docs/qrspi/2026-05-17-v07-release/goals.md:L40]
artifact: goals
round: 1
reviewer: scope-claude
---

Goals.md contains two explicit out-of-scope decisions that the Goals OWNS/DEFERS contract eliminates from this artifact.

Per `skills/goals/owns-defers.md` DEFERS line 16: "Out-of-scope decisions → eliminated. What isn't a goal isn't in scope. Project-level scope clarifications (if any) belong to Design's Approach where solution scope is decided."

Two violations:

1. Constraints, last bullet (L20): "Porting QRSPI's main-chat orchestrator to a non-Anthropic foundation model is explicitly out of scope for this release; v0.7 routes specific dispatch sites to cheaper third-party LLMs, but does not relocate the orchestrator itself." This is a project-level scope carve-out that belongs to Design's Approach. If the cost-opt goals (G1/G2/G5) are correctly framed, the absence of an orchestrator-port goal already encodes the scope; the explicit negative statement is the DEFERS-violating residue.

2. G1 "What we know so far", last bullet (L40): "Budget tracking is explicitly out of scope. Token usage is tracked through provider dashboards outside QRSPI; the policy describes routing rules only." Same pattern — an explicit not-a-goal carve-out that belongs to Design's Approach (or simply to absence in the Goals set).

Resolution: delete both bullets. If the scope-clarification value is load-bearing for downstream readers, it can be re-introduced in design.md's Approach section where solution scope is decided. The Goals artifact should communicate scope by the goals it contains, not by listing the goals it excludes.

This is the cleanest DEFERS violation in the artifact — the phrase "explicitly out of scope" is the lexical drift signal that maps directly to the eliminated category in the rule set.
