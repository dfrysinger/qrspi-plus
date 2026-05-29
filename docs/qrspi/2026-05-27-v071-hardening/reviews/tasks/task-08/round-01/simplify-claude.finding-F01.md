---
reviewer: simplify-claude
task: 8
round: 1
severity: low
blocking: false
category: unnecessary-complexity
file: scripts/run-third-party-llm.sh
lines: 275-311
---

# F01 — `_dispatch_openai_chat`: collapse two-array two-loop / two-branch curl-header construction

## Observation

T8 removed the cache-control branch from `_dispatch_openai_chat`, which trimmed the JSON-build side of the function nicely. The curl-invocation side, however, still carries pre-T8 scaffolding that was not load-bearing for the cache mechanism but is more visible now that it sits next to a much shorter function body. The current shape (lines 275–311) is:

```bash
# Build extra-header arguments.  We populate a parallel array and pass each
# as explicit curl -H flags.  No eval; no here-doc with secrets.
local CURL_EXTRA_HEADERS=()
local _j=0
while [ "$_j" -lt "${#HEADER_NAMES[@]}" ]; do
  CURL_EXTRA_HEADERS+=("${HEADER_NAMES[$_j]}: ${HEADER_VALUES[$_j]}")
  _j=$((_j + 1))
done

local curl_rc=0

if [ "${#CURL_EXTRA_HEADERS[@]}" -gt 0 ]; then
  local _h_args=()
  local _k=0
  while [ "$_k" -lt "${#CURL_EXTRA_HEADERS[@]}" ]; do
    _h_args+=("-H" "${CURL_EXTRA_HEADERS[$_k]}")
    _k=$((_k + 1))
  done
  curl --silent --show-error --fail-with-body \
    --max-time "$timeout_val" \
    -X POST "$chat_url" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $_API_KEY" \
    "${_h_args[@]}" \
    -d "$request_json" \
    -o "$tmp_response" \
    2>"$tmp_stderr" || curl_rc=$?
else
  curl --silent --show-error --fail-with-body \
    --max-time "$timeout_val" \
    -X POST "$chat_url" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $_API_KEY" \
    -d "$request_json" \
    -o "$tmp_response" \
    2>"$tmp_stderr" || curl_rc=$?
fi
```

Three redundancies stack here:

1. **Intermediate array `CURL_EXTRA_HEADERS`** is constructed once and consumed once — its only purpose is to be re-iterated by the second loop to interleave `-H` between elements. The two loops can fuse into one that builds `_h_args` directly from `HEADER_NAMES` / `HEADER_VALUES`.

2. **Duplicated curl invocation** — the two branches are byte-identical except for the presence of `"${_h_args[@]}"`. The branch exists because under `set -u` on bash 3.2, `"${empty_array[@]}"` triggers "unbound variable". The established bash-3.2-safe idiom for that is `${arr[@]+"${arr[@]}"}`, which expands to nothing when the array is empty and to `"${arr[@]}"` otherwise. Using it lets the curl call become a single invocation.

3. **`local _h_args=()` declared inside the `if`** means the variable is leaked-scoped (bash `local` inside a conditional is still function-scoped, but the declaration site reads as if it's block-local). Hoisting it out alongside the build loop clarifies intent.

Suggested shape (single loop, single curl call, no branch, no intermediate array):

```bash
# Build curl -H argument array directly from HEADER_NAMES / HEADER_VALUES.
# No eval; no here-doc with secrets.
local _h_args=()
local _j=0
while [ "$_j" -lt "${#HEADER_NAMES[@]}" ]; do
  _h_args+=("-H" "${HEADER_NAMES[$_j]}: ${HEADER_VALUES[$_j]}")
  _j=$((_j + 1))
done

local curl_rc=0
curl --silent --show-error --fail-with-body \
  --max-time "$timeout_val" \
  -X POST "$chat_url" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $_API_KEY" \
  ${_h_args[@]+"${_h_args[@]}"} \
  -d "$request_json" \
  -o "$tmp_response" \
  2>"$tmp_stderr" || curl_rc=$?
```

Net effect: ~24 source lines → ~12; one local array eliminated; one loop eliminated; one branch eliminated. Behavior is preserved for both the empty-headers and non-empty-headers cases.

## Why it matters

This is purely a readability / locality improvement — no behavior change, no security implication. The pattern is observable now because T8 left `_dispatch_openai_chat` significantly shorter, and the curl section now stands out as the longest remaining block. The `${arr[@]+"${arr[@]}"}` idiom is already standard for bash 3.2 + `set -u` codebases (it appears in the bash FAQ and is the documented workaround for the pre-bash-4.4 empty-array expansion bug under `nounset`). If the maintainer prefers to keep the explicit branch for clarity, the single-loop simplification (collapsing the two-loop `CURL_EXTRA_HEADERS` → `_h_args` chain into a one-loop direct build from `HEADER_NAMES`/`HEADER_VALUES`) is still independently worthwhile.

## Suggested fix

Either:
- **Minimum:** fuse the two loops into one that builds `_h_args` directly. Keeps the if/else for safety. Eliminates one local array and one loop body.
- **Full:** as shown above — adopt `${_h_args[@]+"${_h_args[@]}"}` and drop the if/else entirely. Halves the line count of the curl-call section.

Non-blocking — suggestion only.
