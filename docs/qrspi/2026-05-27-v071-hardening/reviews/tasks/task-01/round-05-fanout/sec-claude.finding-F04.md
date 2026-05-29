---
finding: F04
reviewer: sec-claude
round: 5
task: 1
severity: info
category: input-validation / over-permissive-guard
file: scripts/run-third-party-llm.sh
lines: 633-634
---

# F04 — `api_key_env` identifier validator allows digit-leading names — `${!var}` resolves to positional parameters

## What the code does

```bash
# scripts/run-third-party-llm.sh  lines 633-634
case "$API_KEY_ENV" in
  ''|*[!A-Za-z0-9_]*) die "key-resolution: api_key_env must be a valid shell \
identifier (for provider '$PROVIDER')" ;;
esac
# …
_API_KEY="${!API_KEY_ENV:-}"
```

The pattern `[!A-Za-z0-9_]` rejects any character outside `[A-Za-z0-9_]`.
This allows values like `1`, `123`, or `1FOO` — identifiers that begin
with a digit — because digits are included in the allowed set with no
position constraint.

## What goes wrong

A valid POSIX shell identifier must **not start with a digit** (`[A-Za-z_][A-Za-z0-9_]*`).  When `API_KEY_ENV` is a digit-leading string, bash's
`${!API_KEY_ENV}` indirect expansion resolves it as a positional parameter
reference rather than an environment variable lookup:

| `API_KEY_ENV` value | `${!API_KEY_ENV}` resolves to |
|---------------------|-------------------------------|
| `1`                 | `$1` (positional parameter 1) |
| `2`                 | `$2` |
| `10`                | `${10}` |

After the argument-parsing loop (`while [ "$#" -gt 0 ]`) all positional
parameters have been consumed via `shift`.  At line 641, `$1`…`$9` are
empty, so `_API_KEY` would be `""`, immediately caught by the emptiness
check at line 642:

```bash
if [ -z "$_API_KEY" ]; then
  die "key-resolution: environment variable '$API_KEY_ENV' … is set but empty"
fi
```

This means the validator's gap **does not currently lead to a successful
exploit** — the fail-closed empty-key check catches it.

### Residual concern

If the positional-parameter landscape changes in a future refactor (e.g.,
a function is added that calls `_api_key_resolution` with arguments still
in scope), `${!1}` could silently resolve to a non-secret positional
argument value, using it as the `Authorization: Bearer` token.  This is
a latent correctness bug, not an immediate security issue.

Additionally, `api_key_env` values like `RANDOM`, `SECONDS`, or
`LINENO` (bash special variables) pass the validator.  `${!RANDOM}`
evaluates to a new random number each invocation.  Again, this requires
config.md to be adversary-controlled, but if so, it would produce a
constantly-changing, non-functional Bearer token with no diagnostic error.

## Recommended fix

Tighten the validator to enforce the POSIX identifier grammar
(`[A-Za-z_][A-Za-z0-9_]*`):

```bash
case "$API_KEY_ENV" in
  ''|[0-9]*|*[!A-Za-z0-9_]*)
    die "key-resolution: api_key_env must be a valid shell identifier \
(for provider '$PROVIDER')" ;;
esac
```

The added `[0-9]*` alternative rejects any value beginning with a digit.
