# Structure R02 — apply-fix log

1 finding (real correctness):

- **quality-codex F01 (blocking)** — R01 fix over-committed by hardcoding the Implement wave-1 sidecar as the universal G5 phase-base. For `--phase integration` and `--phase test` this would over-scan the commit range (including prior-phase commits) and produce false G5 violations. Applied: rewrote the G5 File Map row and the orchestration-boundary-check.sh Interface block to delegate per-phase phase-base source resolution to Plan per design.md G5, while Structure commits to the shape (one recoverable anchor per phase). Implement phase keeps the wave-1 sidecar (true by G6 construction); integration/test phase anchors are recorded by their own SKILL at phase start. Diagram edge label clarified to "(per-phase source)".

quality-claude (clean — noted that quality-codex F01 covers the issue they would have filed). scope-claude clean. scope-codex clean.
