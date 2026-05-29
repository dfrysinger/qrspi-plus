---
reviewer: simplify-claude
finding: F05
task: task-10
round: 04
severity: advisory
category: readability
file: tests/unit/test-using-qrspi-vocab.bats
lines: 889-898
status: open
---

# F05 — anti-pattern absence pin (slice 3c) negative-asserts narrow literal phrases

## What

The R2 fix added a final "anti-pattern wording absent" test at
`tests/unit/test-using-qrspi-vocab.bats:889-898`:

```bash
@test "model_routing block: anti-pattern wording absent (no 'silently fall back' / 'silently degrade')" {
  local body
  body="$(_extract_h4 "$USING" '`model_routing:` block')"
  # T10 R2 fix (restore fail-loud contract):
  # Pin the absence of anti-pattern wording G7b/#204 was filed
  # against. If a future edit "softens" the fail-loud rule into a
  # silent-fallback, this pin RED-fails.
  [[ "$body" != *"silently fall back to the agent-bundled default"* ]]
  [[ "$body" != *"silently degrade"* ]]
}
```

The two negative-substring matches require the body to NOT contain
these exact byte sequences:

1. `silently fall back to the agent-bundled default`
2. `silently degrade`

The fragility concern: variations that mean the same thing slip past.
The schema H4 currently says (line 470 of SKILL.md):

> "The dispatcher never falls back silently to the agent-bundled
> default and never passes the dispatch through…"

Note the wording is "**falls back silently**", not "**silently fall
back**" — the live wording already orders these two adverbs
differently from the pinned anti-pattern. If a future edit rewrote
the assertion into the literal anti-pattern (e.g. "the dispatcher may
silently fall back to the agent-bundled default when…"), the pin
catches it. But all of these regressions would slip past undetected:

- "silently falls back to the agent default" (no "-bundled-")
- "silently fall through to the agent default"
- "falls back silently to the agent-bundled default" (current
  positive wording — almost a near-match to the anti-pattern)
- "silently re-routes to the agent-bundled default"
- "degrades silently" (adverb order)
- "silent fallback to the agent default" (noun form)

The pin is therefore narrower than its intent. The companion positive
pin in the preceding test (line 885-887) is the load-bearing one:

```bash
[[ "$body" == *"halts and reports"* ]]
[[ "$body" == *"never falls back silently"* ]] || [[ "$body" == *"never fall back silently"* ]]
```

The positive pin already guarantees the section says "never falls
back silently" (or the plural variant) — so the anti-pattern absence
pin is mostly a defense-in-depth signal against someone DELETING the
positive-fail-loud sentence AND adding a softened sentence in the
same edit. For that scenario, broader pattern matching is more
useful than two exact substrings.

## Why it's a simplification candidate

- **The pin's intent is "no softening into silent-fallback wording",
  not "no literal string X".** A regex check expresses the intent
  more directly.
- **Two specific literal phrases is an arbitrary cut.** Why those
  two and not "silently route to", "silent fallback", "degrades
  silently"? The comment says "anti-pattern wording G7b/#204 was
  filed against" but G7b/#204 is the silent-fallback class, not the
  specific phrase.

## Suggested shape (semantics-preserving — still passes today)

Use a regex (with `grep -iE`) that captures the silent-fallback
*class* rather than two specific phrases. The current body says
"never falls back silently" — that's the positive-asserted phrase,
guarded by the preceding test. So in the body of the H4 we want to
forbid ANY positive (non-negated) silent-fallback claim.

The simplest semantics-preserving widening:

```bash
@test "model_routing block: anti-pattern wording absent (silent-fallback class)" {
  local body
  body="$(_extract_h4 "$USING" '`model_routing:` block')"
  # Forbid silent-fallback / silent-degrade class wording in ANY adverb
  # order or morphological form (fall back / falls back / falling back /
  # fallback; degrade / degrades / degrading; silent / silently).
  # The positive pin in the preceding test guarantees the section says
  # "(never) falls back silently" — that negated form must not match
  # this pattern (and doesn't, because of the leading "never").
  ! printf '%s\n' "$body" \
    | grep -iE '(^|[^a-z])(silent(ly)?[[:space:]]+(fall[[:space:]]?back|fall[[:space:]]+through|degrade|re-?route)|(fall[[:space:]]?back|degrade)[[:space:]]+silent(ly)?)' \
    | grep -ivE '(never|not)[[:space:]]+(falls?[[:space:]]?back|silent)' \
    >/dev/null
}
```

Trade-off: the regex is more complex than two literal substring
matches, which somewhat undercuts a "readability" simplification
argument. An alternative that prioritizes clarity over coverage:
**leave the negative pin as-is, but add a comment that names its
scope and points at the positive pin as the load-bearing
counterpart.** That makes the narrow scope intentional rather than
accidental:

```bash
@test "model_routing block: anti-pattern wording absent — narrow literal pin" {
  local body
  body="$(_extract_h4 "$USING" '`model_routing:` block')"
  # SCOPE: this pin is intentionally narrow — it catches only the two
  # canonical anti-pattern phrasings G7b/#204 referenced verbatim. The
  # broader "no silent-fallback claim" contract is enforced positively
  # by the preceding test ("never falls back silently" must be present).
  # If you change the positive wording, audit this pin too.
  [[ "$body" != *"silently fall back to the agent-bundled default"* ]]
  [[ "$body" != *"silently degrade"* ]]
}
```

Either route improves the readability/intent gap. The second is
strictly clearer; the first is strictly more thorough.

## Why this is advisory only

The pin passes today, the positive companion pin carries the
load-bearing contract, and the narrow literal match has zero false
positives. The narrow shape is a fragility risk, not a correctness
defect. Verifier may KEEP the current shape unchanged.

## Pointer

- `tests/unit/test-using-qrspi-vocab.bats:876-887` (positive fail-loud pin)
- `tests/unit/test-using-qrspi-vocab.bats:889-898` (anti-pattern absence pin)
- `skills/using-qrspi/SKILL.md:470` (the live wording "never falls back silently")
