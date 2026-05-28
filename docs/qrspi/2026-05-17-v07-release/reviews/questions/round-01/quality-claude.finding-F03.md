---
finding_id: R1-F03
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md, docs/qrspi/2026-05-17-v07-release/goals.md:L91-L108]
artifact: questions
round: 1
reviewer: quality-claude
---

G5 (Dispatcher tolerance research) explicitly identifies "Replay or A/B validation" as the candidate methodology for determining which dispatcher/task combinations tolerate cheaper models, and names three current dispatcher classes (lightweight implementer for prose/doc/config tasks, research specialist and collator, general-purpose / Explore dispatches) whose current work shape needs to be characterized before tolerance can be assessed. The question set covers the policy schema (Q1, Q2), the call mechanism (Q3, Q4, Q5), and the test-writer sub-case (Q10, Q11), but does not surface either of the two research surfaces G5 needs:

1. **Current dispatcher inventory and work shape.** No question asks the codebase what dispatcher classes exist today, what tool grants they hold, what model defaults they carry, or what shape their bounded work actually takes. Q1 asks how model choice is *expressed*, not what each dispatcher actually *does*. Without this surface, Design cannot reason about which dispatchers are even candidates for cheap-model routing, much less which one tolerates which model.

2. **A/B replay methodology prior art.** No [web] question asks about published methodologies for A/B-comparing LLM coding-agent outputs (replay harnesses, golden-output comparison, blind grading rubrics). G5 names "replay or A/B validation" as the validation candidate; Research should surface prior art before Design picks a methodology.

Recommended fix: add two questions. A [codebase] question characterizing the current dispatcher set and the work shape of each (without naming the specific tolerance candidates already in goals — phrase as "what dispatcher classes exist in `skills/` and `agents/`, what is the input/output shape of each, and which subset has bounded prompts that lend themselves to mechanical replay?"). And a [web] question on A/B replay methodology prior art for LLM coding agents.

This is a `scope` change_type because the proposed fix adds two new commitments to the question set rather than rewording existing ones — the existing 25 questions do not cover the surface.
