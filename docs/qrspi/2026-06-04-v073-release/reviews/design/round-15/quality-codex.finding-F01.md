---
artifact: design
reviewer_tag: quality-codex
finding_id: quality-codex-F01
change_type: correctness
---

# G6 contradicts itself about whether validation introduces a new artifact

## Location

design.md G6 Why-this-approach L401 vs Solution L395 / Dependencies L404 / Acceptance L417.

## Finding

L401 says "No new artifacts" but L395 introduces a runtime sidecar; L404 calls it "new behavior" with "no prior runtime sidecar exists"; L417 requires sidecar acceptance coverage. Plan/Implement may misread the "no new artifacts" claim and skip sidecar lifecycle/cleanup work.

## Expected fix

Replace "No new artifacts" with "No new checked-in planning artifact — only a runtime sidecar under review-state (out of band of `parallelization.md`)".
