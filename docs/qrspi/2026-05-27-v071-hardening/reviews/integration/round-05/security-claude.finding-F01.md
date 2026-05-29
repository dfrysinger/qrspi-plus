---
finding_id: R5-F01
severity: medium
change_type: security
referenced_files:
  - skills/using-qrspi/SKILL.md
  - tests/unit/test-using-qrspi-vocab.bats
artifact: integration
round: 5
reviewer: security-claude
addresses_partial: R4-F01
self_score: 70
materialized_by: orchestrator
materialization_reason: security-claude reviewer agent ran under the cross-cutting hard rule "ONLY output channel is response text" — returned full finding body inline; orchestrator persists to disk per the inline-handling pattern established R3+ rounds.
---

## Sibling silent-fallback paths to empty step 4 remain unguarded after R5 fix (`validators:` re-run + missing-`model_routing:` backfill)

### The cross-task interaction (same class as R4-F01, different paths)

R4-F01 enumerated the T9 × prose-contract interaction: after T9 emptied `model:` from all 41 agents, precedence-chain step 4 ("agent-bundled default") resolves to nothing for every agent. R4-F01 was scoped — incorrectly, on my part — to the **`trusted_path:` short-circuit** as the only reachable path to step 4 outside the model_routing: chain. R5 closed that path cleanly.

A re-audit of SKILL.md for the literal phrase "agent-bundled default" turns up **two more reachable paths** to step 4 that the R5 fix paragraph does not cover:

**Path 2 — `validators:` trusted-model re-run (SKILL.md:499):**
> "When a dispatch's output falls below this floor, the validator triggers a trusted-model re-run: the same prompt is re-dispatched to **the agent-bundled default model (bypassing `model_routing:`)** and the re-run output replaces the original."

This is an exact structural twin of the trusted_path: short-circuit: a documented path that bypasses model_routing: and routes to the agent-bundled default. Post-T9, "the agent-bundled default model" is empty for every agent. The R5 fix paragraph is scoped to `trusted_path:` matches only (it opens with "When `trusted_path:` matches..."), so it does not bind here. The same three-way ambiguity (a/b/c) from R4-F01 applies:
- (a) halt loudly on empty default → G7b closed
- (b) silently fall to model_routing: → G7b **reopened**
- (c) silently fall to host CLI default → G7b **reopened**

A dispatcher implementer reading the validators: H4 in isolation gets no fail-loud contract for the empty-default case. Worse: the validators: trigger is **citation_density_floor breach**, which is a fuzzy/probabilistic condition that fires routinely during actual dispatch traffic, not a rare error path. The exploitability surface is narrower than trusted_path:'s but is far from cold.

There's a second, subtler problem with path 2: the validators: feature is *named* "trusted-model re-run" — the whole premise is that the agent-bundled default is a stronger/more-trusted model than `model_routing:` would have picked. Post-T9, the named premise is gutted (there is no agent-bundled default to retrieve), so the validator may silently fail to provide its documented guarantee even in the halt-loudly implementation. The validator's prose still asserts the re-run "replaces the original", which is impossible if the re-run has no model to dispatch to.

**Path 3 — Missing `model_routing:` block backfill (SKILL.md:512-522):**
> "When `config.md` does not contain a `model_routing:` block, the dispatcher fires a one-time in-memory warning:
> > `model_routing: absent from config.md — using **agent-bundled defaults** for this session`"

The L516 warning string itself promises "using agent-bundled defaults" — which is a literal description of routing to empty post-T9. The backfill behavior bullets at L518-522 reinforce this. Path 3 is partially mitigated relative to paths 1 & 2 because the warning is surfaced to main-chat output once per session, but the dispatch behavior on subsequent calls — when those "agent-bundled defaults" are empty — is undefined in the same a/b/c way as paths 1 & 2. The L488 fix paragraph doesn't bind here either.

### Why R5's fix paragraph does not generalize to cover paths 2 & 3

The R5 fix paragraph opens with "When `trusted_path:` matches but the matched agent's frontmatter declares no `model:` field..." — the predicate is explicitly trusted_path:-scoped. A future implementer reading the validators: H4 or the missing-block H4 has no syntactic reason to apply the trusted_path: paragraph by analogy. The two new vocab pins extract only the `\`trusted_path:\` block` H4 body, so even a maximally-loud SKILL.md edit to validators: or the missing-block section would not be enforced by the pin lattice.

### Why this is cross-task (and surfaces only now)

These paths existed pre-T10. They became silent-fallback risks the moment T9 emptied step 4. The R4 review correctly identified the **class** but only enumerated one of three reachable paths in the class — my own oversight, surfaced by re-auditing while verifying R5.

### Severity scoring (self-score 70, KEEP per Hotfix B threshold)

- G7b/#204 silent-fallback class is the load-bearing security goal this release exists to close. Two of three documented paths to step 4 are unguarded; only one is closed.
- Path 2 exploitability: citation_density_floor breach is a routine dispatch condition. Trigger surface is meaningfully larger than `trusted_path:`'s opt-in surface.
- Path 3 exploitability: narrower (requires repo-maintainer to ship without model_routing: in config.md, with a session-warning surfaced) — closer to a doc-quality issue.
- Configuration is repo-maintainer-controlled at all three paths.
- Same defect class as R4-F01 (verifier 70). Path 2 is mechanically identical to trusted_path: with comparable-or-slightly-narrower exploitability.

Score: **70 / KEEP**.

### Suggested fix (Option A — recommended)

Append a parallel fail-loud paragraph to the `validators:` H4 covering the empty-default case for the trusted-model re-run, and a sentence to the missing-`model_routing:` H4 covering the empty-default case for the backfill. Add two vocab pins extracting each H4 asserting the same `halts and reports` + `never falls back silently` substring pair. Mirrors R5's per-H4 mirror-paragraph pattern exactly.

### Wording invariants (for the parallel paragraphs)

To remain pinnable by the existing `_extract_h4` + substring-grep pattern:
- Contains literal substring `halts and reports`
- Contains either `never falls back silently` or `never fall back silently`
- Does NOT contain `silently fall back to the agent-bundled default`
- Does NOT contain `silently degrade`

### Verification trace

- Read SKILL.md L460-560 with the R5 commit applied. Confirmed the new paragraph at L488 cleanly closes the trusted_path: branch.
- `grep` audit for `agent-bundled default` across the H4 cluster (L470-522): L470 covered by T10 R2 (model_routing:-scoped), L499 (validators:, **uncovered**), L508 (precedence-chain step-4 definition — pure definition, no route), L510 (trusted_path: reference, covered by R5), L516 (missing-block warning string, **uncovered**), L520/L522 (backfill behavior bullets, **uncovered**).
- `_extract_h4` boundary verified: helper stops at any `^#{1,4} ` line, so each H4's body is independently pinnable. R5's pins do not transitively cover validators: or missing-block H4 bodies.

### Out of scope for this finding

- R5's `trusted_path:` fix itself — that work is correct and complete for its scope.
- The anchors.json bookkeeping — pure line-count regeneration, no security surface.
- T9 sweep — `model:` deletion remains correct.
- Schema changes — Option A is prose + tests only.
