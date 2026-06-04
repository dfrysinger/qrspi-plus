# F01 — Partial state: current-round anchor written before exit-1 prior-artifact failure; untested and mis-documented

**Category:** 6 — Partial State on Failure (+ test coverage gap)
**Severity:** Medium
**Files:**
- `skills/implement/SKILL.md:1189`, `skills/implement/SKILL.md:1198` (changed)
- `scripts/round-prepare.sh:173-182` vs `:191-224` (pinned contract)
- `tests/unit/test-scope-tagger-dispatch.bats` "fails loudly when prior-round commit anchor is missing" (diff L257-277) and "fails loudly on missing scope-set" (diff L279-305)

## What happens

In `round-prepare.sh` the per-task commit-anchor is written in **Step 1** (line 176,
`printf '%s\n' "$IMPLEMENTER_COMMIT" > "$ANCHOR_TMP"` → `mv`), which runs *before* the
**Step 10** prior-round bookkeeping assertions (lines 191-224) that exit `1` when the
prior `round-(NN-1)-commit.txt` is missing/malformed or the prior `round-NN-scope-set.txt`
is missing/empty.

Consequence: when a round fails its prior-artifact assertion (exit 1), the script has
**already written `round-NN-commit.txt` for the current round** and leaves it on disk.
A "failed" preparation therefore leaves a stray, well-formed current-round anchor. A
subsequent round (NN+1) will find that anchor present and well-formed and treat round NN
as having completed — even though round NN never dispatched reviewers. This defeats the
consume-once / "no stray anchor on failure" invariant the design leans on for the narrow
decision.

## Why the new code masks this

`skills/implement/SKILL.md:1198` (changed) asserts the anchor is written *"on exit 0"* and
that *"a failed verification leaves no `round-NN-commit.txt` on disk (preserves consume-once
invariants downstream)."* That claim is **only true for exit 11/12** (which short-circuit
before the Step 1 write). It is **false for exit 1** prior-artifact failures, which write
the anchor first and fail second. The doc's reassuring language hides the partial-state
window.

## Why the bats do not catch it

Both loud-failure fixtures assert only `[ "$status" -ne 0 ]` plus a diagnostic grep, then
`rm -rf "$tmp"`. Neither asserts the *negative* invariant — that the current round's
`round-0N-commit.txt` was **not** left behind. Example: the missing-scope-set fixture
(diff L279-305) runs round 3, the script writes `task/round-03-commit.txt` at Step 1, then
exits 1 at Step 10; the test passes (`status != 0`, grep matches `round-02-scope-set.txt`)
while the stray `round-03-commit.txt` sits on disk unexamined. A regression that turns the
partial-state window into a real downstream bug would stay green.

## Recommendation

- In `round-prepare.sh`, move the Step 1 anchor *write* to after the Step 10 prior-artifact
  assertions (keep the SHA checks where they are, but defer the `mv` of the anchor until all
  fail-loud gates have passed), so any non-zero exit leaves no current-round anchor.
- Correct the `SKILL.md:1198` claim to scope the "leaves no anchor" guarantee accurately, or
  (preferably) make it true for all non-zero exits per the fix above.
- Strengthen both loud-failure bats fixtures with `[ ! -f task/round-0N-commit.txt ]` to pin
  the no-stray-anchor invariant fail-closed.
