# spec-claude — Round 03 Clean

reviewer: spec-claude
task: 19
round: 3
verdict: APPROVED

## Summary

Both round-02 findings (F01 and F02) are correctly addressed. No new spec
divergence or regression was found in this round.

---

## F01 fix verification — `scripts/second-reviewer-available.sh`

**Claim:** the probe now computes `_default_vendor` once and gates on
`[ "$_default_vendor" = "none" ]` so an unknown host exits non-zero even when
a recognized vendor override is supplied.

**Verified at:** `second-reviewer-available.sh` lines 41–58.

```
_default_vendor="$(lookup_default_second_reviewer "$_host")"   # line 41

if [ "$#" -ge 1 ] && [ -n "$1" ]; then                        # line 44
  _vendor="$1"
else
  _vendor="$_default_vendor"
fi

if [ "$_default_vendor" = "none" ] || [ "$_vendor" = "none" ] || ! second_reviewer_vendor_known "$_vendor"; then
  printf '[second-reviewer-unavailable] host=%s vendor=%s ...' "$_host" "$_vendor" >&2
  exit 1
fi
```

*Path trace — unknown host + `openai-codex` override:*

| Variable | Value | How |
|---|---|---|
| `_host` | `unknown` | `detect_host` finds no signal |
| `_default_vendor` | `none` | `lookup_default_second_reviewer("unknown")` returns `none` |
| `_vendor` | `openai-codex` | override arg `$1` is set |
| Gate fires? | YES — `[ "none" = "none" ]` is TRUE | First clause short-circuits |
| Diagnostic | `[second-reviewer-unavailable] host=unknown vendor=openai-codex` | `$_vendor` = override, not `_default_vendor` |
| Exit | 1 (non-zero) | ✓ DoD L42 |

*Override-boundary on known hosts — no regression:*

For `copilot-cli` + `openai-codex` override:
- `_default_vendor = "openai-codex"` → first clause FALSE
- `_vendor = "openai-codex"` → second clause FALSE
- `second_reviewer_vendor_known("openai-codex")` returns 0 → third clause FALSE
- Exits 0 ✓ (override still honored on known hosts)

---

## DoD L42 — all four conditions confirmed

| Condition | Gate that fires | Exit | Diagnostic |
|---|---|---|---|
| Unknown host | `_default_vendor = "none"` (first clause) | non-zero | names host and override/default vendor ✓ |
| Missing default vendor | `_default_vendor = "none"` (same path) | non-zero | ✓ |
| Unknown vendor | `! second_reviewer_vendor_known "$_vendor"` (third clause) | non-zero | ✓ |
| Unavailable vendor | `! second_reviewer_vendor_known "$_vendor"` (matrix-membership proxy per spec intent) | non-zero | ✓ |

All four DoD L42 conditions produce exit 1 with exactly one stderr line beginning
`[second-reviewer-unavailable]` naming both `host=` and `vendor=`.

---

## F02 fix verification — `tests/unit/test-second-reviewer-available.bats`

**Test at lines 414–441:**
`unknown-host-guard: unknown host with recognized vendor override exits non-zero with [second-reviewer-unavailable]`

Assertions checked:
1. Clears `COPILOT_CLI`, `CLAUDE_PROJECT_DIR`, `CODEX_CLI` → unknown host
2. Passes `openai-codex` (recognized matrix vendor) as `$1`
3. `[ "$_status" -ne 0 ]` — non-zero exit ✓
4. `[ "$line_count" -eq 1 ]` — exactly one stderr line ✓
5. `grep -q '^\[second-reviewer-unavailable\]'` — correct tag ✓
6. `grep -q 'host=unknown'` — names the detected host ✓
7. `grep -q 'vendor=openai-codex'` — names the override vendor ✓

The test is **not vacuous**: it can fail in three independent ways (wrong exit
code, wrong line count, missing tag/host/vendor in diagnostic). Each assertion
is a load-bearing behavioral check against the DoD L42 scenario.

---

## Scope check — no out-of-scope additions

Files changed in this round-03 fix (from the diff against base):

- `scripts/second-reviewer-available.sh` — new file, in Target files ✓
- `scripts/_host-detect.sh` — new file, in Target files ✓
- `scripts/_resolve-lib.sh` — modified, in Target files ✓
- `skills/goals/SKILL.md` — modified, in Target files ✓
- `skills/using-qrspi/SKILL.md` — modified, in Target files ✓
- `skills/using-qrspi/SKILL.anchors.json` — line-number update tracking SKILL.md edits; auxiliary bookkeeping, not a spec divergence ✓
- `skills/reviewer-protocol/SKILL.md` — modified, in Target files ✓
- `tests/unit/test-second-reviewer-available.bats` — new file, in Target files ✓
- `tests/unit/test-dispatch-companion-availability.bats` — new file, in Target files ✓
- `tests/unit/test-routing-matrix-application.bats` — modified, in Target files ✓

No files outside the Target files list were modified (anchors.json is an
auto-maintained index for SKILL.md, not an independent spec surface).

---

## Result

✅ **Approved** — both findings from round-02 are correctly resolved; no new
spec divergence, no regression to override-boundary behavior on known hosts,
and the new regression test is substantive.
