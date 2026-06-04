# F05 — Pinned diff-emission contract: `git diff ... 2>/dev/null || true` writes empty diff on failure; T13 bats only covers the happy path

**Category:** 2 — Silent Fallbacks (coverage gap on pinned contract)
**Severity:** Low
**Files:**
- `scripts/round-prepare.sh:364-368` (pinned, unchanged)
- `tests/unit/test-scope-tagger-dispatch.bats` — "[T13] round-prepare.sh task-branch mode emits round-NN.diff (G4 inheritance preserved)" (diff L159-181)

## What happens

The diff-emission step swallows `git diff` failure:

```bash
git diff "$REF" -- > "$DIFF_TMP" 2>/dev/null || true
...
mv "$DIFF_TMP" "$DIFF_PATH"   # exit 0 path continues
```

If `git diff` fails for any reason (e.g. an unresolved/empty `$REF` — note `$REF` can be
empty when `--base-ref` is unset and none of `main`/`trunk`/`HEAD~1` resolve), the script
writes an **empty** `round-NN.diff`, emits a sidecar pointing at it, and exits 0. Reviewers
then receive an empty diff and review nothing — a silent under-review with a success exit.

## Why I'm flagging it under T13

`round-prepare.sh` is unchanged, so this is the pinned contract — but T13 owns the bats that
pin diff emission, and the *only* diff fixture (diff L159-181) exercises the happy path
(a committed `a.txt` with a valid `--base-ref`). There is **no fixture** that asserts the
script fails loudly (or at least does not silently emit an empty diff + exit 0) when the diff
cannot be produced. The `|| true` fallback is exactly the kind of "default value masking a
failure" that the test suite should pin against, and right now a regression that produces an
empty diff for a non-trivial change would not be caught by any T13 assertion.

## Recommendation

Add a fixture that drives the diff failure/empty-ref path and asserts the script does not
silently exit 0 with an empty diff (either it fails loudly, or the sidecar `reason` records
the empty-diff condition). At minimum, document that an empty `round-NN.diff` on exit 0 is a
valid "no changes" signal vs. a swallowed `git diff` error, so consumers can distinguish them.
