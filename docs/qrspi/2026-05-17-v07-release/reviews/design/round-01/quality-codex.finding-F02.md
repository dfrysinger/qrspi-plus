---
finding_id: R1-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L28-L39]
artifact: design
round: 1
reviewer: quality-codex
---

The G1 routing schema contradicts itself on override order. It first says "later layers override earlier layers" after listing per-agent, per-task, per-run, and trusted-path layers, which implies per-run overrides per-task. A few lines later it states the actual precedence as `per-task > per-run > per-agent > built-in default`, with trusted-path short-circuiting separately.

Downstream Structure and Plan agents need a single precedence rule to implement. Rewrite the G1 recommendation so the list order and the explicit precedence agree, or remove the "later layers override earlier layers" sentence and make the precedence line the only normative rule.
