---
reviewer: security-codex
task: 1
round: 2
finding: F01
severity: high
change_type: scope
status: pending-out-of-scope-pre-existing-security
model: gpt-5.3-codex
timestamp: 2026-05-28T19:00:00Z
agent_id: t01-r2-sec-codex
persistence_note: OpenAI-family transport returns chat-only; manually persisted. See GH #216.
referenced_files:
  - scripts/run-third-party-llm.sh
---

## SSRF filter can be bypassed via DNS resolution to internal IPs

**Locations:**
- `scripts/run-third-party-llm.sh:585-592` (host check call site)
- `scripts/run-third-party-llm.sh:120-165` (`_is_rejected_host` function — only checks literal host text)

**Severity:** High

**Why exploitable:** The code blocks private/loopback/link-local hosts only by inspecting the **hostname string** from `base_url`, but does not resolve DNS and validate the resolved IP(s). A public-looking hostname can still resolve to internal targets.

**Concrete attack scenario:** An attacker who can influence `config.md` sets:
- `base_url: https://api.attacker-controlled.example/v1`
- DNS for that hostname resolves to `169.254.169.254` (AWS IMDSv1 metadata), `127.0.0.1`, RFC1918, etc.

The lexical host-shape check passes (hostname is not a literal blocked IP), then `curl` connects to the internal address. This enables SSRF to metadata/internal services and can leak sensitive request data (including the `Authorization` header which carries the upstream API token).

**Remediation suggested by Codex:** Resolve hostname to all A/AAAA records before dispatch, and reject if **any** resolved IP is in blocked ranges. Use rebinding-safe behavior (resolve-then-connect-pinning) where possible.

**Orchestrator triage: PRE-EXISTING; OUT OF SCOPE for T1.**

`git log -L 120,165:scripts/run-third-party-llm.sh` traces `_is_rejected_host` to commit `a2edc7f` ("qrspi-plus T03: Create universal third-party-LLM dispatcher script") which predates T1's RED (`85d0b6e`) and GREEN (`f38344d`) commits. T1's diff at lines 585-595 only adds the `_control_char_check` call adjacent to the pre-existing host check; the `_is_rejected_host` logic itself is not modified by T1.

**Recommended disposition:**
1. Surface to user immediately (severity = high; pause-and-escalate per standing directive)
2. File standalone GH security issue with full reproduction (or security advisory if user prefers private)
3. Include in T1 done-report under "Pre-existing security findings observed during review (out of scope, escalated)"

**Threat-model context for the user:** The exploitability depends on `config.md` integrity. If `config.md` is under the same trust boundary as the dispatcher binary (e.g., committed to the qrspi-plus repo, edited only by maintainers), the attack surface is limited to maintainer-level threat. If `config.md` is ever loaded from a less-trusted source (CI artifact, runtime input, downloaded fixture), the SSRF risk is real and high-severity.
