# QRSPI Future Ideas

Cross-phase ideas about evolving the QRSPI pipeline itself. Not scoped to any single QRSPI run — these are meta-improvements to the framework. Move ideas into a phase plan when ready to execute.

---

## Streamline quick-fix to a superpowers-style flow

**Idea:** Quick-fix mode currently mirrors full-pipeline gating (every step prompts for human approval). Reshape it so most steps run autonomously and only the high-leverage decisions surface to the human, similar to the superpowers brainstorming → writing-plans → subagent-driven-development flow.

**Proposed quick-fix flow:**

| Step | Human gate? | Notes |
|------|-------------|-------|
| Goals | Yes | Capture intent — same as today |
| Research | No | Quick autonomous research; findings flow forward |
| Design | Yes | Present proposed options, user picks (this is the "brainstorming" gate) |
| Plan | No | Auto-generate plan from approved design (like superpowers writing-plans handoff) |
| Parallelize | No | Auto-derive parallelization from plan |
| Implement | No | TDD with subagent-driven-development style execution |
| Test | Optional | User can skip if they want to verify manually |

**Why:** Today's quick-fix has six human gates for what is, by definition, a small change. Superpowers gets meaningful work done with two gates (after brainstorm, after plan review). The current QRSPI quick-fix tax is high enough that users may bypass the pipeline for trivial changes — defeating the point of having a quick-fix mode at all.

**Tradeoffs to think through:**
- Reviews still need to run on autonomous steps — keep the Claude+Codex loop, just don't surface the artifact for human approval unless the loop hit the cap with unresolved findings
- Need a clean "abort" mechanism so the user can interrupt mid-flight if an autonomous step is heading the wrong way
- Goals + Design as the only two gates assumes those are where the user adds the most leverage; verify this assumption before committing to it

**Scope when promoted:** Treat as its own QRSPI run (probably a quick-fix run on QRSPI itself, ironically). Goals would clarify which gates matter and why; Design would propose the new flow against the current one with an explicit comparison.
