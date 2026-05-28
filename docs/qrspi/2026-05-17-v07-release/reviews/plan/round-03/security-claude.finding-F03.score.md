---
finding_id: R3-F03
reviewer: security-claude
verifier_score: 75
verdict: KEEP
---

Verified: T33 L1026 prefix-match without normalization allows `docs/qrspi/../../../etc/shadow` bypass in naive bash impl. Add realpath requirement + traversal-fixture test expectation. Low severity, simple fix.
