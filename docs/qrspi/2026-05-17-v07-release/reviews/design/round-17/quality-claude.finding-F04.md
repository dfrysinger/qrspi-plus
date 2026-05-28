---
finding_id: R17-F04
severity: medium
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L196-L201, docs/qrspi/2026-05-17-v07-release/design.md:L231-L237]
artifact: design
round: 17
reviewer: quality-claude
---

The G4 test strategy section lists the Plan-time spike as a test item without clarifying which test-strategy items are conditional on the spike outcome, leaving Plan authors unable to determine which tests to write before spike completion.

G4 (design.md lines 196-201) defines a spike with a clear two-path structure: if the dispatch path already caches automatically, Mechanism A reduces to verification-only (measuring hit rates); if it does not cache automatically, G4 scope expands to include adding `cache_control` markers before measurement. The design correctly states "G4 implementation tasks are blocked on spike completion."

The G4 test strategy section (lines 231-237) lists these items:
- For prompt cache, verify usage metadata shows cache hits at the dispatch sites Plan flags as cache-eligible.
- For narrow Reads, verify agents using the section-anchor index Read only the expected line ranges.
- For rejection of summary shims, a code search confirms no agent dispatch site feeds LLM-generated summaries.
- Capability-gated cache test: shell-shim dispatch to a provider with `supports_prompt_cache: false` succeeds without emitting cache_control fields.
- Plan-time spike (Mechanism A hypothesis resolution): verify whether `Agent({})` dispatches produce Anthropic cache-hit metadata.

The issue is that these items are presented as a flat list, but their status differs fundamentally:
- The spike item IS the spike deliverable — it is not a "test of G4", it is the pre-implementation probe that determines G4's scope.
- The "prompt cache cache hit" verification item is only meaningful after the spike resolves whether caching is already working or needs to be added.
- The shell-shim cache test (for G2's `supports_prompt_cache:` flag) is independent of the spike.

A Plan author reading the flat list would not know which items to sequence before spike completion, which items are conditional on spike path A (caches automatically), and which items are conditional on spike path B (requires `cache_control` additions).

Fix: restructure the G4 test strategy to make the spike the first item explicitly labeled as a pre-implementation probe, then group subsequent items as "Path A (caching already active)" and "Path B (cache_control additions required)" with the shell-shim test called out as spike-independent. This matches the two-path structure already documented in the spike contract.
