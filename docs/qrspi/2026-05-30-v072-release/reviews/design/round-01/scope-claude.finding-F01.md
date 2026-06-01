---
finding_id: R1-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-30-v072-release/design.md:L976-L1001]
artifact: design
round: 1
reviewer: scope-claude
---

The G4 section ("Canonical cumulative diff helper + round preparation") embeds 25+ lines of actual bash shell code at lines 976–1001 — full `if [[ -z "$VAR" ]]; then ... fi` blocks, variable assignments using command substitution (`PRIOR=$(resolve_prior_anchor ...)`, `ACTUAL_HEAD=$(git -C ... rev-parse HEAD)`), and echo-to-stderr + exit-with-code statements for three distinct failure branches. This is line-by-line logic with explicit control-flow detail, which the Design DEFERS rule assigns to Plan/Implement, not Design.

The Design-appropriate treatment would be a prose statement of what the three checks do and what exit codes they produce (e.g. "Script performs three ordered correctness checks — flag-presence (exit 10), across-rounds advance (exit 12), within-round equality (exit 11) — each with a distinct recovery directive for main chat"). That level of specificity is sufficient for architectural decision-making; the exact conditional structure, variable plumbing, and stderr message wording belong in the Plan task spec.

The embedded code block is also internally inconsistent with the design's own Sub-Rule B ("Prose-as-Decision"): Sub-Rule B shields LLM-sensitive prompt prose from being flagged as premature implementation detail, but bash control flow does not qualify as LLM-sensitive prompt prose. The design offers no internal justification for this level of procedural depth at Design phase.

To resolve: replace the fenced bash code block at lines 976–1001 with a concise prose description of the three-check contract (check names, exit codes, and main-chat recovery actions in tabular or bulleted form at the prose level). The exit-code recovery table that follows at lines 1005–1016 is already at the right level of abstraction and may be retained.
