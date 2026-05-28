---
finding_id: R3-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L216]
artifact: plan
round: 3
reviewer: security-claude
---

T03's SSRF host-shape rejection list omits the IPv6 loopback address `::1`, creating a bypass path even when `QRSPI_ALLOW_LOCALHOST_BASE_URL` is not set.

**What the spec says today.** T03's test expectation (plan.md L216) documents that even with the carve-out active, the following ranges remain rejected: link-local `169.254.0.0/16`, CGNAT `100.64.0.0/10`, RFC1918 ranges, IPv6 link-local `fe80::/10`, and IPv6 unique-local `fc00::/7`. The carve-out allows `127.0.0.0/8` (IPv4 loopback only). IPv6 loopback `::1` (equivalently `0:0:0:0:0:0:0:1`) appears in neither list.

**The gap.** Because `::1` is mentioned in neither the "always reject" list nor the "carve-out allows" list, an implementation can plausibly treat it as always allowed or as allowed when the carve-out is active. An implementation that does a string-prefix match for `127.` would miss `::1` on every code path. A `base_url` of `http://[::1]/v1/chat/completions` would then pass the SSRF guard and reach a local service even without the carve-out env var set.

**Fix.** Add `::1` (the IPv6 loopback) to the "rejected even when carve-out is active" list in T03's test expectation alongside `169.254.169.254`, `10.0.0.1`, `192.168.0.1`, and `100.64.0.1`. Then add a `[::1]` `base_url` fixture to T07's SSRF test expectations at plan.md L327, asserting the dispatcher exits 1 with the host-shape diagnostic and no outbound call, regardless of whether `QRSPI_ALLOW_LOCALHOST_BASE_URL` is set.
