---
reviewer: security-claude
task: 1
round: 2
finding: F01
severity: medium
change_type: correctness
status: pending
model: claude-sonnet-4.6
persistence_note: Claude returned findings inline. Orchestrator manually persisted.
referenced_files:
  - scripts/run-third-party-llm.sh
---

## API Key Value Never Validated for Control Characters Before Use in `Authorization` Header

**Category:** Injection — CRLF / Header-Injection
**Lines:** 622–630 (key resolution), 298–299 / 307–308 (curl Authorization header)

**Description:** The `_control_char_check` pre-flight validates every `default_headers` name and value from `config.md`. However, the API key retrieved from the environment variable (`_API_KEY`) is placed verbatim into a curl `-H` argument as `"Authorization: Bearer $_API_KEY"` — **without any control-character check**.

The stated security property from the done report is: *"Every header name and every header value is screened before any network call."* The `Authorization` header value is a header value, and it is not screened.

**Attack scenario:**
1. CI/CD runner env compromised (malicious pre-step, leaked secrets-manager write, rogue dependency).
2. Attacker sets `MY_API_KEY="sk-good-token\r\nX-Injected-Header: attacker-value"`
3. Dispatcher passes verbatim to curl: `-H "Authorization: Bearer sk-good-token\r\nX-Injected-Header: attacker-value"`
4. On curl < 7.54.0 (pre-2017 CRLF-stripping hardening), or future HTTP library substitution that doesn't strip embedded newlines, injected header is transmitted to upstream LLM provider.

Even on modern curl this relies on curl's *implicit* protection rather than the script's own explicit sanitization — silent dependency on curl version behaviour.

**Mitigation:** Run `_control_char_check` on `_API_KEY` immediately after the empty-string check (line 629), before any network dispatch:
```bash
_control_char_check "Authorization" "Bearer $_API_KEY"
```
Or a dedicated check:
```bash
_control_char_check "api_key_env/${API_KEY_ENV}" "$_API_KEY"
```

**T1 scope assessment:** This IS in scope for T1. The task's stated property is "every header name and every header value is screened" — the API key path is a header value path that was overlooked. Closing this gap is consistent with T1's hardening intent.
