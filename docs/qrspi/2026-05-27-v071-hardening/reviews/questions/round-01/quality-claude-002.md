---
id: quality-claude-002
artifact: questions
severity: MEDIUM
check: goal-leakage + objectivity
---

## Finding

**Q12** embeds the constraint "without embedding host-specific model names," which mirrors the framing of G7b Candidate A and reveals the intended design direction to the researcher.

### Offending text

> …what patterns exist for expressing agent-tier intent **without embedding host-specific model names**?

### Goal-leakage dimension

G7b Candidate A reads: "Delete `model:` from all 41 agent frontmatters; author model-tier intent in dispatching skill prose using **transport-agnostic vocabulary** ('dispatch with a low-tier model' / 'dispatch with a frontier reasoning model')." The constraint appended to Q12 is a restatement of Candidate A's core premise. A researcher reading Q12 alone can infer that the project intends to decouple model selection from host-specific identifiers — the primary goal of the G7b migration is thus recoverable.

### Objectivity dimension

The qualifying phrase "without embedding host-specific model names" steers the researcher toward solutions that omit explicit model identifiers and away from other valid patterns (alias maps, build-time rewriting, per-host config tables). This shrinks the research surface in a direction that matches a pre-chosen candidate rather than characterising the full landscape.

### Suggested rewrite

> How do multi-host AI-agent plugin projects that target Claude Code, Copilot CLI, Cursor, and/or Codex CLI simultaneously handle model selection and model-tier vocabulary across hosts: what patterns have been observed in open-source projects, and what are the trade-offs of each approach?

This retains the cross-host scope and the practical framing without revealing the project's preferred direction.
