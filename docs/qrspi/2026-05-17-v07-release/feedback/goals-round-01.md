---
step: goals
round: 01
rejected_artifact: docs/qrspi/2026-05-17-v07-release/goals.md
---

## User Feedback

(Verbatim from Daniel, 2026-05-17.)

> for G1 its not clear to me what the goal is, is this just a budget tracking tool? if so is it really nevessary? i can track token usage from my llm provider interfaces. If the goal is just defining the rules for what kind of work gets routed where thats fine, but it should be trimmed to that and made more clear. Also you mention the porting to openAI a few time but thats not in scope for this phase and i dont want to confuse the downstream agents.
>
> G3 is also a bit unclear to me, what particular steps would this summarize agent be helpful, and what are the risks/tradeoffs and are they worth it? im a bit worried about only using summaries of a long file unless they are just used as previews or something and the agents will read the real source. maybe an index would be helpful instead so agents can find the right spot in the file? again though im not clear on the specific steps this would help so the problem isnt clear.
>
> G4 is a bit muddled as well, if G1 is about knowing when to route to cheaper models (but it might not be i cant tell), then G4 is also discussing the same kind of thing but a bit more specifically. we should probably pick one goal to be the one defining the routing rules, and another to be defining the actual script/mechanism for calling third party openAI compatible llms. Also id like it to be easy to swap any subagent or task to use the cheaper models so we can be dynamic about it rather than up front deciding only a few subagents will support it. also id like to research if we should have a test writer subagent for implement and if that test wroter could be a cheaper model. i expect both tge separation of the tests from the inplementation might be good (or bad we should check) and also an opportunity to farm out simpler work to cheaper models. also we should reference and research this arricle for script implementation ideas for outsourcing to cheaper models: https://medium.com/@kunalbhardwaj598/i-was-burning-through-claude-codes-weekly-limit-in-3-days-here-s-how-i-fixed-it-0344c555abda

## Action Items Distilled

1. **G1 — narrow to routing rules only.** Drop budget tracking (Daniel tracks tokens externally via provider dashboards). G1 becomes a decision-policy goal: which dispatcher class × work type routes to cheaper models, with what override behavior. Make Problem framing clearer.

2. **G1 prose — kill the "OpenAI-compat porting" confusion surface.** Downstream agents may conflate "OpenAI-compatible endpoint routing" (which IS in v0.7 scope, as cheaper *dispatch targets*) with "port QRSPI to OpenAI/Codex" (which is #89, moved to v0.8). Reframe to talk about third-party cheaper LLM endpoints (DeepSeek-V3, Kimi K2 as exemplars) — mention OpenAI-compat API surface at most once, as implementation detail Design will handle. Never as a Purpose-line framing.

3. **Insert new G2 — cost-opt dispatch mechanism.** The script/shim that actually calls a third-party LLM endpoint from any subagent dispatch site. Constraint: dynamic opt-in — any subagent or task can route to cheaper models at runtime, not a fixed pre-approved subset. Reference the Medium article in "What we know so far" as a research input Design should consult.

4. **Reframe old G3 (summarize CLI shim) as G4 — context optimization for repeated long-file reads.** Two candidates in "What we know so far": (a) summary shim (compact summary as prompt input — surface Daniel's risk that summaries must NOT replace source-of-truth reads), (b) file index (table of section anchors with line numbers, so agents Read just the relevant subset). Problem statement should enumerate which specific repeated-read patterns this targets — vague framing is what made old G3 unclear.

5. **Reframe old G4 (dispatcher tolerance merge) as G5 — dispatcher tolerance research + new test-writer subagent investigation.** Add a NEW research question: should Implement split test-writing into its own subagent? If so, could that subagent run on a cheap model? Daniel expects both the separation question (good/bad?) and the cost-opt question (worth farming out?) to be open — frame as exploratory research, not a committed feature. Reference the Medium article here too as relevant prior art.

6. **Renumber.** Old G2 → G3 (Plan post-approval split). Old G3 → G4 (context optimization). Old G4 → G5 (tolerance + test-writer). P2/P3/P4 goals shift by +1 (old G5→G6, …, old G16→G17). Total goal count: 16 → 17.

7. **Update Cross-Cutting Notes for new IDs.** The G1↔G3↔G4 (foundation/leaves) relationship still holds but the IDs change. Add a note that G1 (rules) and G2 (mechanism) are paired — G1 decides where, G2 does the call.

## Previous Artifact

(See `goals.md` at the path in `rejected_artifact` above. Version preserved in git; do not duplicate the 290-line body here.)
