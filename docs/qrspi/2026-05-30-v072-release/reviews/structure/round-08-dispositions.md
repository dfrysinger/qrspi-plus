# Structure R8 — Dispositions

## KEEP — apply fix

### F01 (medium, correctness/clarity)
**Fix:** Change L772 from "Additions A, C, and D are inline-permanent text" to "Additions A, B, C, and D are inline-permanent text". The Consumer #2 row at L779 already shows Addition B is inline-permanent verbatim.

### F02 (high, correctness)
**Fix:** Rewrite L773-774 to remove the incorrect implication. Current text reads:

> This is distinct from the `skills:` frontmatter preload used by agent files (Consumers #4-#8 per design.md G31 Distribution Table).

Problem: Consumer #6 uses BOTH `skills:` preload AND has Addition D inline in the Hook-Point table. The parenthetical implies "#4-#8 are absent from this table" which is false.

Replacement:

> This is distinct from the `skills:` frontmatter preload used by agent files (Consumers #4–#8 per design.md G31 Distribution Table). Consumer #6 (`qrspi-design-reviewer`) appears in BOTH groups: it preloads `prompt-prose-reviewer` via `skills:` frontmatter AND carries Addition D inline as a per-block refinement, so its row appears in the table below.

### F03 (medium, correctness)
**Fix:** Extend the test row at L129 to pin Addition C's standalone anchor. Current responsibility:

> Guard shared include usage for prompt-prose and design-boundary snippets.

Replacement responsibility:

> Guard shared include usage for prompt-prose and design-boundary snippets; additionally pin the standalone Addition C anchor phrase (`"Scope: only \`task_type: code\` tasks."`) at the TOP of `agents/qrspi-plan-test-coverage-reviewer.md` so silent drift or misplacement of the scope guard is caught.

### F04 (medium, correctness)
**Fix:** Change Slice 1.2 L37 from NEW name to OLD name with a forward pointer. Current:

> `scripts/dispatch-agent.sh` | Modify | Add host/vendor/model metadata persistence into the dispatch manifest for later observability.

Replacement:

> `scripts/run-codex-review.sh` | Modify | Add host/vendor/model metadata persistence into the dispatch manifest for later observability. **Note:** this file is renamed to `scripts/dispatch-agent.sh` in Slice 1.4 (rename row at L60). Either slice can land first; whichever lands second works against the post-rename path.

This matches the OLD-keyed convention applied across Slice 1.4 rename rows and explicitly carries the cross-slice dependency in the responsibility prose where Plan will see it.
