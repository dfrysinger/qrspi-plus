---
finding_id: R2-F02
severity: medium
change_type: correctness
referenced_files:
  - skills/plan/post-approval-split-contract.md
  - tests/unit/test-plan-post-approval-split.bats
reviewer_tag: security-claude
---

Block-hash audits plan.md source content only — task file body can be silently tampered. Case 2: "only the source block in plan.md is hashed — not the file body."

Attack: orchestrator crashes after split. Attacker modifies tasks/task-05.md body (keeping `# block-hash:` header intact), inserting malicious step. Orchestrator resumes → plan.md task-05 block unchanged → hash matches header → Case 2 safe-skip → Implementation sub-subagent receives tampered file and executes malicious step. Persistent attack: tampered file safe-skips on every re-run unless plan.md edited.

Contract framed as "audit contract" creates false inference of body integrity. Test suite implies false guarantee by omission (no body-changed/header-unchanged fixture).

Fix: add explicit `## Security Scope` subsection naming integrity boundary: hash attests to plan.md source-block provenance only. Optionally: add `# body-hash:` line covering body at write time for re-run verification. Near-term: add test asserting body-tamper case.
