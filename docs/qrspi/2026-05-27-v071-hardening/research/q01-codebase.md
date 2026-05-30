---
status: draft
question_ids: [1]
research_type: codebase
---

# Q01: Control-character detection routine in `scripts/run-third-party-llm.sh`

## Summary

**TL;DR:** The control-character detection routine lives in the "Security pre-flight" block (lines 558–569) and uses `printf '%s' … | grep -qP '[\x00-\x1f\x7f]'` to test each provider `default_headers` name and value for C0 control characters (0x00–0x1F) and DEL (0x7F). Detection is gated behind the `openai-chat-completions` transport type and, on a positive match, terminates the script immediately via `die` with exit code 1 before any network call is made.

**Key findings:**
- **Tool**: `grep` with flags `-q` (quiet/no output) and `-P` (Perl-compatible regex / PCRE). The full invocation is `grep -qP`.
- **Pattern**: `[\x00-\x1f\x7f]` — a character class covering all 32 C0 ASCII control characters (U+0000–U+001F) plus the DEL character (U+007F).
- **Piped input**: Each header name (`_hname`) and header value (`_hval`) is passed individually via `printf '%s' "$_hname" | grep -qP …` and `printf '%s' "$_hval" | grep -qP …`.
- **Gating condition 1 — transport type**: The entire check (lines 530–571) only executes when `TRANSPORT_TYPE = "openai-chat-completions"`; the `codex-broker` path skips this block entirely.
- **Gating condition 2 — detection result**: When either the header name or header value matches the pattern, `die "header-validation: default_headers for provider '$PROVIDER' contains a control character in header '$_hname'"` is called, printing the message to stderr and exiting with code 1. If no match is found for all headers, execution falls through to API-key resolution (line 574 onward) and then network dispatch.
- **Silent fallback**: Both `grep -qP` invocations include `2>/dev/null`. If the host `grep` does not support `-P` (e.g., BSD grep on macOS), the commands fail silently; the `if` condition evaluates to false and the check is effectively skipped.

**Surprises:** The `2>/dev/null` suppression means that on platforms where `grep -P` is unsupported (including macOS's system grep), the control-character check silently produces a false-negative (no detection) rather than failing loudly. There is no fallback detection path for that scenario.

**Caveats:** Only `scripts/run-third-party-llm.sh` was examined. No other files in the repo were checked for duplicate or analogous control-character detection logic.

## Full findings

### Routine location

File: `scripts/run-third-party-llm.sh`, lines 558–569 (inside the "Security pre-flight" block, lines 527–571).

### Surrounding structural context

The security pre-flight block (lines 527–571) is entered only when `TRANSPORT_TYPE = "openai-chat-completions"` (line 530). Within that block, four numbered sub-checks execute in order:

1. URL scheme must be `https://` (lines 532–536).
2. Extract the hostname from the URL (lines 538–547).
3. Host-shape validation against blocked IP ranges (lines 549–555).
4. **Control-character check on `default_headers`** (lines 558–569). ← subject of this question

### The detection routine (lines 558–569)

```bash
# 4. default_headers: no control characters in name or value.
_hi=0
while [ "$_hi" -lt "${#HEADER_NAMES[@]}" ]; do
  _hname="${HEADER_NAMES[$_hi]}"
  _hval="${HEADER_VALUES[$_hi]}"
  # Use printf | grep -P for control-character detection.
  if printf '%s' "$_hname" | grep -qP '[\x00-\x1f\x7f]' 2>/dev/null || \
     printf '%s' "$_hval"  | grep -qP '[\x00-\x1f\x7f]' 2>/dev/null; then
    die "header-validation: default_headers for provider '$PROVIDER' contains a control character in header '$_hname'"
  fi
  _hi=$((_hi + 1))
done
```

#### Tool and flags

| Element | Value |
|---|---|
| Tool | `grep` |
| Flags | `-q` (suppress all output), `-P` (use PCRE / Perl-compatible regex engine) |
| Combined flag form | `grep -qP` |
| Error suppression | `2>/dev/null` on each invocation |

#### Pattern

`[\x00-\x1f\x7f]`

- `\x00`–`\x1F`: all 32 C0 ASCII control characters (NUL, SOH, STX, …, US).
- `\x7f`: the DEL character.
- Higher-byte characters (0x80–0xFF, multibyte Unicode) are **not** covered by this pattern.

#### Input source

`HEADER_NAMES` and `HEADER_VALUES` are parallel arrays populated at lines 514–516 from the parsed `default_headers` section of the provider block in `config.md`. Each array element represents one header name or one header value respectively.

The loop iterates `_hi` from 0 to `${#HEADER_NAMES[@]} - 1`, testing both the name string and the value string for each header.

### Code paths gated by the detection result

| Detection result | Code path |
|---|---|
| **Match found** (control char present in name or value) | `die` is called → message printed to stderr, `exit 1`. No API key is resolved, no network call is made. |
| **No match** (all headers clean) | Loop continues; after all headers pass, execution exits the `if [ "$TRANSPORT_TYPE" = … ]` block and proceeds to API-key resolution (line 574), stdin validation (line 588), prompt-injection guard (line 604), and then transport dispatch (line 612). |
| **`grep -P` unsupported** (`grep` exits non-zero with no match output, stderr suppressed) | `if` condition is false; control character is not detected; execution continues as if headers were clean. |

### Scope of the check

The control-character check is **not** applied to:

- The `codex-broker` transport path (the entire security pre-flight block is skipped when `TRANSPORT_TYPE` is not `openai-chat-completions`).
- The `base_url` string itself (only URL-scheme and host-shape checks apply to it).
- The `--model`, `--provider`, or any other CLI arguments.
- The stdin prompt (which has a separate prompt-injection guard via `guard_marker_injection` at line 604).
