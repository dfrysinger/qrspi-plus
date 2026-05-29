---
finding: F03
reviewer: sf-claude
round: 5
task: 1
severity: low
category: inappropriate-error-transformation / diagnostic-masking
file: scripts/run-third-party-llm.sh
lines: 222-223, 649
---

# F03 — `_control_char_check` die message hardcodes "default_headers" regardless of caller context

## What the code does

```bash
# scripts/run-third-party-llm.sh  lines 222-223
[ "$_cc_count" -eq 0 ] || \
  die "header-validation: default_headers for provider '${PROVIDER:-}' contains a control character in header '$_cc_hname'"
```

The function is also called for API key validation (line 649):

```bash
_control_char_check "api_key_env/${API_KEY_ENV}" "$_API_KEY"
```

## What goes wrong

When the API-key path triggers the die, the operator sees:

```
run-third-party-llm: header-validation: default_headers for provider 'my-provider'
  contains a control character in header 'api_key_env/OPENAI_KEY'
```

The message says **"default_headers"** even though the control character is
in the API key value, not in any `default_headers` entry.  An operator
triaging this error would:

1. Open `config.md` and inspect the `default_headers:` block.
2. Find it clean.
3. Waste time before realising the actual issue is the value of the
   `OPENAI_KEY` environment variable.

The header-name field (`api_key_env/OPENAI_KEY`) hints at the real source,
but it sits inside a "default_headers" sentence that actively misdirects
the reader.

## Why this matters

The task explicitly designed the API-key check to be transparent without
leaking the key value (using `"api_key_env/${API_KEY_ENV}"` as the label).
That transparency goal is partially undermined if the sentence framing
attributes the problem to `default_headers` configuration.

This is diagnostic masking: the wrong root cause is reported, increasing
mean-time-to-resolution for a security-relevant failure.

## Recommended fix

Accept an optional `context` parameter, or build the die message from
`_cc_hname` rather than assuming "default_headers":

**Minimal fix** — change the hardcoded prefix to be context-aware:

```bash
_control_char_check() {
  local _cc_hname="$1" _cc_hval="$2"
  local _cc_count
  _cc_count=$(printf '%s' "$_cc_hname$_cc_hval" \
    | LC_ALL=C tr -d '\040-\176\200-\377' \
    | wc -c \
    | tr -d ' \t')
  case "$_cc_count" in          # numeric guard (see F01)
    ''|*[!0-9]*) die "header-validation: failed to compute control-char byte count for '$_cc_hname' (provider '${PROVIDER:-}')" ;;
  esac
  [ "$_cc_count" -eq 0 ] || \
    die "header-validation: provider '${PROVIDER:-}' — control character in header/key '$_cc_hname'"
}
```

The `"in header/key '$_cc_hname'"` phrasing is accurate for both `default_headers` entries and `api_key_env/…` labels without hardcoding the wrong config section.
