---
finding_id: R2-F01
reviewer: security-claude
score: 92
verdict: keep
---

Cite +30 (L210), failure mode +25 (SSRF via undocumented carve-out; metadata service exposure), fix proposed +20 (explicit env-var; scope to 127.0.0.0/8 only), Plan OWNS +15, severity high matches +2.
