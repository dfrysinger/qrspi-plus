---
finding_id: R4-F01
artifact: structure
reviewer_tag: quality-claude
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
line_range: [215, 296]
---

## §3 verifier-fanout `--tier-override <tier>` signature contradicts §7 grammar (introduced in R3)

The R3 addition of the verifier-fanout invocation form to Interface §3 documents the override flag as a bare tier value:

```
scripts/dispatch-agent.sh --verifier-fanout \
  --step <step> --round <N> --output-dir <round-dir> \
  [--tier-override <tier>]
```

But Interface §7 (`Host-and-tier-aware second-reviewer override`) — the canonical contract for the same `--tier-override` flag — defines a strict grammar that requires every value to be a tag=tier assignment, optionally CSV-joined:

```
--tier-override <csv>

csv        := assignment ("," assignment)*
assignment := <reviewer-tag> "=" <tier>
tier       := extra-low | low | medium | high | extra-high
```

and adds:

> the override is applied per emitted reviewer tag, so one batch can escalate only the second reviewer while leaving primary reviewers unchanged
> invalid tag names or tier values halt dispatch before any Task invocation

A bare `--tier-override high` would therefore be rejected by §7's parser ("invalid tag name"), so as written, the verifier-fanout invocation form in §3 is unimplementable against §7's contract. The two surfaces disagree on the flag's value shape.

This is a contract-level correctness issue, not just a clarity one: it forces the implementer to either (a) silently relax §7's grammar to accept a bare tier, (b) re-author §3 to use the assignment form (e.g., `--tier-override qrspi-finding-verifier=<tier>`), or (c) introduce a second, undocumented flag — and Plan/Implement will need to make that choice without any guidance from Structure.

### Recommended fix

Pick one and align both sections. The cleanest option is to keep §7's single grammar and rewrite §3's verifier-fanout form to use it explicitly, since every fan-out dispatch resolves to the same agent:

```
[--tier-override qrspi-finding-verifier=<tier>]
```

If a bare-tier shorthand is intentional for the fan-out single-agent case, §7 should be amended to document a second accepted shape (e.g., `csv := assignment ("," assignment)* | <tier>` with the note "bare-tier form is only valid in `--verifier-fanout` mode, where the agent is fixed"), and §3 should cross-reference §7 for the grammar definition so the two stay coupled.

Either way, both interface sections must agree on the value shape before this becomes a downstream lookup problem for the dispatch script implementer and the test author of `tests/unit/test-routing-matrix-application.bats`.
