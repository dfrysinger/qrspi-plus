---
finding_id: F01
severity: high
category: completeness
files:
  - tests/unit/test-using-qrspi-vocab.bats
---

# F01 — Unit-test regex does not reject `silently substitutes the bundled default` (explicit DoD example)

## What the spec requires

`tasks/task-44.md` Definition of Done bullet 3 (lines 38–39):

> The regex rejects equivalent contract regressions including `silently substitutes the bundled default`, `silently degrades to the agent default`, and `no silent fallback to a neighboring tier`.

And Scope bullet 3 (line 26):

> Cover equivalent silent-fallback regressions such as `silently substitutes the bundled default`, `silently degrades to the agent default`, and `no silent fallback to a neighboring tier` …

These bullets are about the in-place regex pins in `tests/unit/test-using-qrspi-vocab.bats` (the surface named in the surrounding bullets and in the structure.md reference). The list of three example phrasings is presented as the contract surface the regex must close on.

## What the implementation does

The four rewritten pins all use the identical pair:

```
[[ ! "$body" =~ silently[[:space:]]+(fall|degrad) ]]
[[ ! "$body" =~ (^|[[:space:]])silent[[:space:]]+fallback ]]
```

(`tests/unit/test-using-qrspi-vocab.bats` lines 144–147, 178–181, 210–213, 252–255.)

The first regex covers `fall*` and `degrad*` stems → catches `silently degrades to the agent default` ✓ (matches "silently degrades").
The second regex covers the `silent fallback` noun phrase → catches `no silent fallback to a neighboring tier` ✓.

But neither regex matches `silently substitutes the bundled default` — the `substitut` stem is intentionally excluded. The implementer's inline comment at line 246–251 documents the rationale:

> Note: this H4 body contains "does not silently substitute defaults" (the negated, non-anti-pattern form); the regex intentionally uses (fall|degrad) rather than adding "substitut" to avoid false-positives on that negated phrase.

So the deployed in-place pin will silently allow a future regression that re-introduces `silently substitutes the bundled default` — which is exactly the scenario DoD bullet 3 lists by name as a regression the regex must reject.

## Why this is a real spec deviation, not a judgment call

The implementer encountered a genuine constraint conflict:

- DoD requires the regex to reject `silently substitutes the bundled default`.
- The "stay green against settled prose" DoD bullet (line 40) requires the regex not to trip on the existing missing-block H4 body, which contains `does not silently substitute defaults` (the negated form).
- The Out-of-Scope list (line 32) forbids editing the dispatch-routing prose itself.

These three constraints together appear unsatisfiable as written: you cannot add a `substitut` branch without false-positiving on the existing negated prose, and you cannot rewrite the prose. The implementer chose to drop the `substitut` branch from the deployed pin and route demonstration of the broader pattern into the acceptance test (C-3, which uses a *different* regex with `substitut` added — see F02).

This is a meaningful gap from the spec's literal requirement. The result is that one of the three named regression phrasings — the *first* one listed in both the Scope and DoD bullets — is not actually pinned against by the deployed unit-test regex.

## Recommendation

Operator-level decision needed. Two paths:

1. **Amend the task spec / accept**: explicitly note that the `substitut` branch is unsatisfiable against current settled prose without prose edits (which are out-of-scope) and that acceptance-test C-3 documents the broader regex for a future round when prose is amenable. Drop `silently substitutes the bundled default` from the DoD example list.

2. **Rework**: solve the constraint conflict — for example, narrow the regex to a pattern that requires an unambiguously affirmative/anti-pattern context (so `does not silently substitute` would not match but `silently substitutes the bundled default` would), or scope the `substitut` branch only to the three pin sites whose H4 body does not contain the negated form.

I lean toward path 2 being achievable: an anchored alternation like `silently[[:space:]]+(falls?|fell|degrade[sd]?|substitutes?)[[:space:]]+(back|to|the|defaults?|[a-z]+[[:space:]]+default)` would still false-positive on `does not silently substitute defaults` — but a lookbehind-style guard isn't available in bash ERE. A simpler alternative is to use two patterns where the third pin file (missing model_routing) gets a regex without the `substitut` branch (status quo), while the *other three* pin sites get the broader regex including `substitut`. That would close the gap on three of four sites without breaking the fourth.

This isn't a recommendation about which path to take — it's a flag that the spec's literal DoD is not met and the implementer's inline rationale documents the gap rather than closing it.
