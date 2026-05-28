---
round: 17
artifact: design
status: fixing (supplementary)
---

# Round 17 supplementary dispositions

This document captures the 5 quality-claude findings that arrived after the primary `round-17-dispositions.md` fix subagent was dispatched (race condition: quality-claude completed last), plus 1 user-directed scope change.

## Findings inventory (supplementary)

- R17-F02 quality-claude (medium, correctness): G6 `task_type:` TDD default not propagated to summary
- R17-F03 quality-claude (medium, correctness): G11 `wave_context:` T-NN tokens conflict with G7 hygiene
- R17-F04 quality-claude (medium, clarity): G4 Plan-time spike list flat (spike vs path-A vs path-B not separated)
- R17-F05 quality-claude (low, correctness): G3 "<600 lines" attribution to Q6/Q7 overstates research
- R17-F06 quality-claude (low, clarity): VFRAgent Mermaid label is note-to-implementer

## User-directed change

- **G2 universal-dispatcher direction (user-approved at round-17 supplementary gate):** unify the Codex and OpenAI-compatible script paths into a single `run-third-party-llm.sh` entry point parameterized on `transport_type:` in provider config. `run-codex-review.sh` retires; Codex becomes one of N transports.

## R17-F02 quality-claude — accept. G6 task_type default not in summary

G6 recommendation says "absent `task_type:` defaults to TDD path" but cross-cutting test strategy and per-goal summary table do not propagate this default. Plan/Implement reading those sections would miss the default routing.

**Fix:** Add to cross-cutting test strategy "TDD path default test" bullet: "A task spec with no `task_type:` field is dispatched on the TDD path (acceptance: pre-implementation test-writer dispatched; gate runs)." Add a similar note in the per-goal summary table row for G6: "default: TDD path when `task_type:` absent."

## R17-F03 quality-claude — accept. G11 wave_context T-NN tokens vs G7 hygiene

G11 `wave_context:` body includes per-task entries showing task IDs (T-NN tokens). G7 forbids T-NN tokens in shipped/executable files. wave_context is assembled at runtime and passed into a reviewer prompt — is it "shipped" content? The conflict is unresolved.

**Fix:** Add to G11 a "G7 hygiene reconciliation" sub-block: `wave_context:` is RUNTIME-ASSEMBLED reviewer-prompt input, not a shipped artifact. It is in-memory only; never written to a git-tracked file. T-NN tokens inside it are therefore exempt from G7's banned-token list. The G7 hygiene scan applies to git-tracked files only; per-dispatch prompt assembly is out of scope. Add to G7's "Path-shaped carve-outs" subsection: "Runtime-assembled prompts (e.g., G11 `wave_context:` payloads) are exempt — these are in-memory dispatch parameters, not shipped files."

Add a design-level test bullet to G11: a `wave_context:` containing T-NN tokens for sibling tasks dispatches cleanly; G7's hygiene scan does not flag the wave_context contents.

## R17-F04 quality-claude — accept. G4 spike list flat

G4 Plan-time spike test list is flat. Reader cannot tell which test is the spike itself, which is conditional on path A (caching active), which on path B (cache_control needs adding).

**Fix:** Restructure G4's spike test bullets under three labeled sub-headings:
- **Spike (always runs):** the cache-probe report deliverable + measurement criterion.
- **Path A (caching already active):** verification-only tests (hit-rate measurement on stable prefixes; no cache enablement work).
- **Path B (cache_control required):** add-cache-then-verify tests (cache_control marker insertion at the Anthropic SDK boundary; hit-rate measurement after insertion).

## R17-F05 quality-claude — accept. G3 600-line attribution overstated

G3's "<600 lines" calculation is a design-time synthesis, not a Q6/Q7 finding. Citing Q6/Q7 overstates the research.

**Fix:** Replace "based on Q6/Q7 task-file template size" with "based on a design-time synthesis using Q6/Q7's documented task-file template structure (typical task spec ~150-200 lines; combined two-task plan + specs estimated at <600 lines)". This separates the design-time estimate from what the research literally found.

## R17-F06 quality-claude — accept. VFRAgent Mermaid label is note-to-implementer

The VFRAgent node carries label "(study Keeplii reference)" — a note to implementer, not a component description. Reduces diagram utility.

**Fix:** Replace the Mermaid VFRAgent label with a component-description label: "VFRAgent: visual-fidelity reviewer per G11". Move the "study Keeplii reference" hint (which is genuinely useful for the implementer) into G11's prose as a sentence: "Implementer reference: see the Keeplii workspace's qrspi-visual-fidelity-reviewer agent file as a working template."

## R17-USER-01 G2 universal dispatcher — accept. User-directed unification

Update G2 recommendation: ship a SINGLE `scripts/run-third-party-llm.sh` with `transport_type:` in provider config. Codex becomes one transport; `run-codex-review.sh` retires.

**Fix scope (multi-edit in G2):**

1. **G2 Recommendation section:**
   - Open with: "Ship a single universal shell dispatcher: `scripts/run-third-party-llm.sh`. It serves both OpenAI Chat Completions providers (DeepSeek, Mistral, Together, Fireworks, xAI, Groq, etc.) and the Codex companion broker, dispatching via a `transport_type:` field on each provider's `config.md` entry."
   - Add explicit transport-type vocabulary: `transport_type: codex-broker` (delegates to existing `codex-companion-bg.sh launch` internally) or `transport_type: openai-chat-completions` (direct HTTPS call to `<base_url>/chat/completions`).
   - Note that `codex-companion-bg.sh` is preserved as the Codex broker runtime (it owns the async launch/await/JSONL lifecycle); only the user-facing wrapper script `run-codex-review.sh` retires.
   - The stdin-only prompt contract, numbered exit-code contract, `--output-file` contract, and key-resolution rules apply uniformly across both transports.

2. **G2 Trade-offs table:**
   - The row currently labeled "Reuse the existing Codex companion script directly" should be RECLASSIFIED. The previous rejection reasoning ("conflates third-party LLM routing with Codex-specific behavior; cleaner to factor shared prompt-assembly into a library and have two thin wrappers") was correct when the alternative was reuse-as-is. With the new `transport_type:` abstraction, that coupling argument no longer applies — Codex is a peer transport, not a special case.
   - Add a NEW accepted row: "**Single universal dispatcher with transport_type config (accepted; user-directed at round-17 supplementary disposition gate).** One entry point. Codex is one of N transports declared in `providers:`. Async-vs-sync dispatch handled by transport adapters; user-facing skill API is symmetric. Cost: internal branch on transport_type. Win: one mental model, one smoke-test loop covers all providers, eliminates the special-case Codex wrapper."
   - Move the previously-accepted "One parameterized OpenAI-compatible script" row to REJECTED with new reasoning: "Superseded by the universal-dispatcher decision; this option would have left Codex as a special case requiring a separate wrapper."

3. **G2 Test strategy:**
   - Update the smoke test bullet: "for each provider listed in `config.md`'s `providers:` block (including the Codex provider entry), dispatch a small prompt through `run-third-party-llm.sh`... — one loop covers all transports."
   - Add transport-type test: "A provider entry with `transport_type: codex-broker` invokes `codex-companion-bg.sh` internally and returns the jobId for separate `await`. A provider entry with `transport_type: openai-chat-completions` blocks until the HTTPS response and writes the result to `--output-file`."

4. **Decision 1 (G1/G2/G5 routing system):**
   - Update G2's "call mechanism" framing to reflect the universal dispatcher: "G2 defines the universal call mechanism. It runs every third-party LLM call (Codex included) from one shell script parameterized on transport_type."

5. **System Mermaid diagram (around line 1068-1070):**
   - Rename the G2 node label from "G2: scripts/run-third-party-llm.sh shell dispatcher" to "G2: scripts/run-third-party-llm.sh universal dispatcher (all transports)". Verify the diagram still reads cleanly.

6. **Per-goal summary table:**
   - The G2 row currently lists `scripts/run-third-party-llm.sh`; keep that file path (canonical entry point). Update the test-type column to retain "acceptance, boundary" but ensure the boundary tests cover transport-type branching.

## Fix dispatch plan

Single fix subagent. 6 distinct accepts (5 missed claude findings + 1 user-directed G2 unification). All in design.md.

## Status

draft → fixing (supplementary) → re-review round 18.
