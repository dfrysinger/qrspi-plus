---
finding_id: R3-F01
reviewer: security-claude
verifier_score: 85
verdict: KEEP
---

Verified: T03 L216 SSRF list omits IPv6 loopback `::1`. Real bypass via `http://[::1]/...`. Add to "rejected even with carve-out" list (with carve-out applying same as 127.0.0.1 when env var set per instructions).
