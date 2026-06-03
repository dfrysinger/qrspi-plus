---
created: 2026-05-30
phase: 1
pipeline: full
codex_reviews: true
route:
  - goals
  - questions
  - research
  - design
  - phasing
  - structure
  - plan
  - parallelize
  - implement
  - integrate
  - test
verifier_enabled: true
scope_tagger_enabled: true
visual_fidelity_required: false
review_depth: deep
review_mode: loop_until_clean
---

# Run Config: qrspi-plus v0.7.2

## Notes

- **Host:** Copilot CLI (`COPILOT_CLI=1`). Codex review dispatch routes via task-tool transport per `skills/using-qrspi/SKILL.md` § "Per-host Codex dispatch transport routing". Documented model identifier is `gpt-5.3-codex`; v0.7.1 hardening run observed `gpt-5.5` in practice (tracked in plugin-issue inbox PI-001 + goals G19/G20 — calibration / reliability of substituted Codex model).
- **Meta-monitoring active:** This run also serves as a meta-monitoring channel for the running plugin (v0.7.1). Plugin-prompt / instruction / tool friction observed during the run is captured in the session DB `plugin_issues` table for synthesis at run end.
- **Review depth (Implement-phase decision):** Deferred to Implement per skill contract. Working assumption: **deep** given the schema-design work in G22 and the cross-cutting reviewer-pipeline cluster (G6/G7/G8/G9/G10/G11/G12/G13/G14/G19/G20). Operator may override to `quick` at Implement-phase start.

## Model routing

The five-tier vendor-neutral routing schema (G22 / design.md CD-1). Each tier maps to a concrete `{ vendor:, model: }` pair; `extra-low` is an operator opt-in surface that defaults to `none` (no agent declares it in the G22 initial rubric). `extra-high` is the pre-configured high-ceiling escalation tier (`claude-opus-4.7-high`) — an operator MAY set it to `none` to opt out of that ceiling. `default_tier:` supplies the tier for any agent dispatch missing a `tier:` field. A dispatch that resolves to a tier configured as `none` halts loudly (see `scripts/_resolve-lib.sh` and `skills/_shared/config-validation-procedure.md`) — there is no silent fallback to a neighboring tier.

```yaml
model_routing:
  extra-low:  none                                              # operator opts in
  low:        { vendor: claude, model: claude-haiku-4.5 }
  medium:     { vendor: claude, model: claude-sonnet-4.6 }
  high:       { vendor: claude, model: claude-opus-4.7 }
  extra-high: { vendor: claude, model: claude-opus-4.7-high }
default_tier: medium
```

