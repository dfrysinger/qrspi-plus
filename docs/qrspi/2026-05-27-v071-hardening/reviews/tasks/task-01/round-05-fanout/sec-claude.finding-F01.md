---
finding: F01
reviewer: sec-claude
round: 5
task: 1
severity: medium
category: incomplete-validation / injection-bypass
file: scripts/run-third-party-llm.sh
lines: 218-220
---

# F01 — C1 control bytes (0x80–0x9F) not screened — header injection bypass on C1-aware HTTP stacks

## What the code does

```bash
# scripts/run-third-party-llm.sh  lines 218-220
_cc_count=$(printf '%s' "$_cc_hname$_cc_hval" \
  | LC_ALL=C tr -d '\040-\176\200-\377' \
  | wc -c \
  | tr -d ' \t')
```

The `tr -d` range `\200-\377` (octal = 0x80–0xFF decimal) **deletes all
non-ASCII bytes before counting**.  Only C0 (0x00–0x1F) and DEL (0x7F) can
survive to be counted.  C1 control bytes (0x80–0x9F) are discarded without
any detection.

## What goes wrong

C1 control characters include several bytes that HTTP implementations and
upstream proxies may treat as line terminators or header-field delimiters:

| Byte | Name | Risk in HTTP context |
|------|------|----------------------|
| 0x85 | NEL (Next Line) | Treated as a newline by Unicode-aware parsers; used in CRLF-injection in some Java HTTP stacks |
| 0x8D | RI (Reverse Index) | Used in some EBCDIC/Latin-1 environments as a carriage-return equivalent |
| 0x8F | SS3 | Terminates header in some legacy ANSI parsers |

### Concrete attack scenario

1. An attacker writes a malicious `config.md` (e.g., via a compromised
   config-management system, a supply-chain substitution, or a path traversal
   in an upstream component that writes provider configs).
2. The attacker sets a `default_headers` value to:

   ```
   X-Auth: Bearer safe-token\x85X-Injected: evil-value
   ```

3. `_control_char_check` receives `_cc_hval = "Bearer safe-token\x85X-Injected: evil-value"`.
4. The `tr -d '\040-\176\200-\377'` stage **deletes 0x85** (it falls in the
   `\200-\377` range) before counting — `_cc_count` is `0`.
5. `[ "0" -eq 0 ]` is true; `die` is **not called**.
6. The header value is passed to curl verbatim.  If the upstream HTTP server,
   TLS termination proxy, or WAF parses 0x85 as a newline, the request is
   received as two separate header lines — header injection succeeds.

The same bypass applies to the API key screening at line 649:

```bash
_control_char_check "api_key_env/${API_KEY_ENV}" "$_API_KEY"
```

A C1 byte in an environment-variable value that holds the API key would
silently pass the screen.

## Scope note

The task specification explicitly excludes bytes 0x80–0xFF:

> "Non-ASCII bytes (0x80-0xFF) are outside spec scope and are not flagged."

This finding calls out that the scoping decision itself creates a bypass
vector for the header-injection threat model the task was designed to
address.  The choice is documented but the security consequence is not
explicitly acknowledged in the design material.

## Affected surfaces

- `_control_char_check` function (line 218–220) — every caller
- Header loop (line 614–620) — all `default_headers` entries
- API key screening (line 649)

## Recommended fix

Narrow the non-ASCII deletion range to **exclude** the C1 block (0x80–0x9F),
so C1 bytes survive the `tr` pass and are counted:

```bash
# Delete printable-ASCII (0x20-0x7E) and high-byte-non-C1 range (0xA0-0xFF).
# C1 control bytes (0x80-0x9F) survive and are counted alongside C0/DEL.
_cc_count=$(printf '%s' "$_cc_hname$_cc_hval" \
  | LC_ALL=C tr -d '\040-\176\240-\377' \
  | wc -c \
  | tr -d ' \t')
```

`\240` is octal for 0xA0 (160 decimal = non-breaking space and above in
Latin-1), so the new deletion range `\240-\377` covers 0xA0–0xFF.  The
C1 block (0x80–0x9F = octal `\200-\237`) now survives to be counted.

If C1 bytes in header values are a legitimate use case (e.g., Latin-1
encoded custom header values), a separate allowlist gate could be added
after the C1 check.
