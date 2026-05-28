---
finding_id: R2-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L210]
artifact: plan
round: 2
reviewer: security-claude
---

T03's test expectations for host-shape validation include a carve-out phrase "unless explicitly allowed for a fixture," but the plan never specifies HOW the carve-out is activated.

The relevant test expectation reads: "a `base_url` resolving to a localhost/link-local/cloud-metadata address exits 1 with a named host-shape diagnostic (unless explicitly allowed for a fixture)." The parenthetical carve-out is load-bearing for testability — the BATS tests in T07 (`test-run-third-party-llm.bats`) need to call the dispatcher against a fixture HTTP server at localhost — but the plan gives no specification for how a caller activates the carve-out. An implementer could:

- Accept an undocumented environment variable (e.g., `ALLOW_LOCALHOST=1`) that disables all host-shape validation globally.
- Accept a `--allow-local` flag that bypasses SSRF protection for any caller that passes it.
- Simply widen "localhost" to "any RFC1918 address," inadvertently allowing cloud-metadata SSRFs to cloud-internal IP ranges (169.254.169.254, 100.64.x.x).

The risk is Server-Side Request Forgery: if the dispatcher can be pointed at `http://169.254.169.254/latest/meta-data/` via a malicious `base_url` in a crafted `config.md`, it will forward the API key env var resolution and the assembled prompt to the instance metadata service. The round-1 security-codex-F02 fix added the host-shape validation requirement but did not close this carve-out specification gap.

Required fix: The T03 description and/or test expectations must specify the concrete carve-out mechanism — for example, "the local-test carve-out is activated by a `QRSPI_ALLOW_LOCALHOST_BASE_URL=1` environment variable that is NOT set in production CI" — and the T07 test expectations must assert that the carve-out is off-by-default (a dispatcher invocation without the carve-out env var against a localhost provider exits 1) and that it covers ONLY 127.0.0.0/8, not 169.254.0.0/16 or other SSRF-capable ranges.
