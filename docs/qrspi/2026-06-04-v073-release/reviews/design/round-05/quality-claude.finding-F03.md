---
finding_id: R5-F03
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-06-04-v073-release/design.md:L365-L380]
artifact: design
round: 5
reviewer: quality-claude
---

G5's `scripts/orchestration-boundary-check.sh` needs a phase-base SHA to bound the `git log <phase-base>..HEAD` commit range. G5 Dependencies says: "Resolved by reading the phase's stage-commit SHA written by the existing stage-commit mechanism (G6's surface). G5 depends on G6 producing a recoverable phase-base anchor."

However, G6 describes stage-commit parent SHA **validation** during Implement waves. G6 does not explicitly describe writing a phase-base anchor file that a subsequent phase (Integrate, Test) can read to establish its range start.

Fix: either (a) add a sentence in G6's Solution explicitly describing what anchor file it writes and where (e.g., `reviews/implement/phase-tip-commit.txt`) for G5 to consume; or (b) acknowledge in G5's Dependencies section that the phase-base anchor mechanism is deferred to Plan.

