---
finding_id: R3-F07
severity: medium
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L15]
artifact: questions
round: 3
reviewer: quality-claude
---

Q9's framing still encodes G4's intent. The question asks "What mechanisms do agent frameworks use to reduce repeated context input across dispatches when the same long, stable files would otherwise be re-read every turn?" — "reduce repeated context input" and "long, stable files would otherwise be re-read every turn" together name both the cost amplifier and the desired remedy, which is exactly G4's job-to-be-done. The round-2 generalization removed the older candidate enumerations but left the goal-shaped premise in place. Strip the framing back to neutral context-management discovery — for example, "What mechanisms or patterns do agent frameworks use to manage large, stable inputs that recur across dispatches?" — so the researcher discovers the reduce-repeated-reads framing rather than receiving it pre-loaded.
