---
finding_id: R5-F05
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-05-30-v072-release/config.md, skills/using-qrspi/SKILL.md]
---
Prose/config contradiction on `extra-high`. Prose states "`extra-low` and `extra-high` are operator opt-in surfaces that default to `none`", but the shipped `model_routing:` block maps `extra-high: { vendor: claude, model: claude-opus-4.7-high }` (a concrete model, not none). Only `extra-low` is `none`. Operators reading the prose expect an `extra-high` dispatch to halt, but the resolver routes it to opus-4.7-high. Source: cq-claude F03. Fix (prose-only, reflect intended policy): update the prose to say only `extra-low` defaults to `none`; describe `extra-high` as the pre-configured high-ceiling escalation tier (`claude-opus-4.7-high`) that an operator may set to `none` to opt out. Do NOT change the config value (extra-high is intentionally the escalation ceiling).
