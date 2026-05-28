---
finding_id: R2-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L11]
artifact: questions.md
round: 2
reviewer: quality-claude
---

Q5's sub-bullet enumeration leaks G2's candidate-shape considerations.

The question reads: "What patterns do public developer writeups describe for shell-side third-party LLM dispatch, including session-state propagation, API-key handling, and error fallback?" The three named considerations — session-state propagation, API-key handling, error fallback — are lifted directly from G2's "What we know so far" candidate-shape bullet ("session-state propagation, error handling, and API-key management") and the Medium-article framing in the same goal. A researcher reading only Q5 would infer the project is specifically evaluating a shell shim that needs those three properties, which is the G2 design space and not a neutral survey question.

Additionally, "shell-side third-party LLM dispatch" presupposes the shell-shim candidate that G2 explicitly says Design should weigh against an in-process wrapper alternative. The question forecloses half the design space.

Recommend rewriting as: "What patterns do public developer writeups describe for invoking third-party LLM endpoints from CLI-driven or agent harnesses, and what concerns recur across those writeups?" That keeps the surface neutral on shell-vs-in-process and lets the researcher surface the considerations organically rather than confirming the three the goal already named.
