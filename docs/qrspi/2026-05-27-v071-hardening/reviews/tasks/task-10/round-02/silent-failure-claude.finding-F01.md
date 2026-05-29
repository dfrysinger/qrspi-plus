---
reviewer: silent-failure-claude
task: 10
round: 02
finding: F01
category: missing-error-paths
severity: high
status: open
---

# F01 — host→tier→model schema has no documented fail-loud contract for malformed entries (silent-fallback surface)

## Where

- `skills/using-qrspi/SKILL.md`, the `#### \`model_routing:\` block` section
  (lines 448–468 in the post-R1-fix worktree), and the adjacent
  `#### Missing \`model_routing:\` block in \`config.md\`` section
  (lines 508–518).
- `skills/using-qrspi/SKILL.md`, the `## Config Validation Procedure` →
  `### When a required field is missing or has an invalid value` block
  (lines 559–610) — `model_routing:` is **absent** from the per-field
  validation menus that govern every other configurable field.
- Test coverage for the surface: `tests/unit/test-config-model-routing.bats`
  and `tests/unit/test-using-qrspi-vocab.bats` — both pin schema **presence**,
  neither pins runtime behavior on **partial corruption**.

## What changed in R1 (the deletion this finding turns on)

The pre-fix `model_routing:` schema doc carried this sentence:

> Each value is `<provider-name>/<model-id>` where `<provider-name>` MUST
> refer to an entry in the `providers:` block. Using a provider name that
> is absent from `providers:` is a config validation error (the dispatcher
> halts and reports the unknown provider rather than falling back silently).

R1 retired this sentence on the (correct) grounds that the new
host→tier→model schema has no provider names. The replacement prose
describes the new shape:

> Top-level keys are the host names emitted by `detect_host` … Each host
> sub-mapping contains exactly four tier rows: `haiku`, `sonnet`, `opus`,
> and `inherit`. Values are fully versioned model IDs (e.g.
> `claude-haiku-4.5`, not the bare tier short-form `haiku`) — Copilot
> CLI's model proxy emits a "model not available" warning for bare tier
> requests but accepts versioned IDs.

…and stops. The new schema **announces three structural invariants** but
documents **zero runtime behavior on violation**. The fail-loud invariant
was deleted; no analogous invariant was put in its place.

## Silent-failure surfaces the deletion opens

The new schema's invariants are (paraphrasing from the post-fix prose):

1. Each top-level key MUST match a value `detect_host` can emit
   (`claude-code` or `copilot-cli`).
2. Each host sub-mapping MUST contain all four tier rows (`haiku`,
   `sonnet`, `opus`, `inherit`).
3. Each tier value MUST be a fully versioned model ID, not a bare
   short-form.

For each invariant there is a partial-corruption case the new schema
does not address:

- **Invariant 1 — missing host key.** `detect_host` returns
  `copilot-cli`, but `config.md` only carries the `claude-code:`
  sub-mapping (e.g. user hand-edited the table down to one host, or
  was on Claude Code when they last edited and never tested Copilot
  CLI). The "Missing `model_routing:` block" section (line 508) only
  covers the **whole block absent** case; it does not extend to "block
  present but the host this dispatch needs is missing." No prose tells
  the orchestrator whether to halt, warn, or silently fall through to
  the agent-bundled default.

- **Invariant 2 — missing tier row.** An agent declares `model: opus`
  (or carries the implicit `inherit` after T9), but the matched host
  sub-mapping is missing the `opus` row. Again — no documented
  behavior. Natural likely outcome under "follow the prose literally":
  silently fall through to the agent-bundled default (which after T9
  is *gone* for the 41 swept agents, so the orchestrator dispatches
  with no `model:` at all, leaving the host CLI to pick — exactly the
  pre-T10 G7b regression this run exists to fix).

- **Invariant 3 — bare short-form value.** A user's hand-edited
  `config.md` has `copilot-cli: { sonnet: sonnet }` (the bare
  short-form the doc warns against). The doc *describes* what the
  Copilot CLI proxy will do at dispatch time ("model not available"
  warning) but never says what the **orchestrator** should do when it
  sees such an entry. Should it halt at config-load (fail-loud, the
  pre-R1 pattern), or pass through and let the dispatch fail at the
  proxy boundary (silent-degradation, the explicit anti-pattern this
  whole hardening release was filed to fix per G7b / #204)?

All three are partial-corruption cases. All three end in either silent
fall-through or silent dispatch-time degradation under the post-R1
prose. The pre-R1 schema's fail-loud rule did not cover them either,
but the pre-R1 rule was **adjacent** (unknown provider → halt) and
provided a clear template for the orchestrator to extend. The R1 fix
deleted the template without leaving any landmark behind.

## Why this matters specifically for this hardening run

This run exists because of the silent-fallback regression filed as #204
(G7b) — bare Claude short model names in agent frontmatter being
silently re-routed by Copilot CLI's proxy. The whole point of the new
`model_routing:` block is to **force fail-loud routing decisions out of
the host proxy and into config-time validation**. Shipping the new
schema with **no documented runtime contract on malformed entries**
leaves the same class of silent-fallback surface — just one layer
deeper. A `model_routing:` block whose `copilot-cli:` sub-mapping is
missing the `opus` row will reproduce the original G7b symptom
("Copilot CLI silently downgrades the dispatch") with no diagnostic
trail back to the missing config entry.

## What's missing (concrete repair shape)

Either of these (the fix author can pick; this finding does not
prescribe which) would close the surface:

1. **Extend the `#### \`model_routing:\` block` section** with an
   explicit fail-loud rule analogous to the deleted one, e.g.:

   > When a dispatch's `detect_host` output matches no top-level key,
   > or when an agent's tier name matches no row under the matched
   > host's sub-mapping, or when a tier value is a bare short-form
   > rather than a versioned model ID, the dispatcher halts and
   > reports the missing/invalid entry rather than falling back to the
   > agent-bundled default or the host CLI's silent re-routing.

2. **Add `model_routing:` to the `### When a required field is missing
   or has an invalid value` menu list** (lines 563–610), with a
   per-failure-mode menu shape matching the other validated fields
   (e.g. "If a host sub-mapping is missing for the active
   `detect_host` output", "If a required tier row is missing under
   the matched host", "If a value is a bare tier short-form").

Either form gives the orchestrator a contract to follow on partial
corruption. The current post-R1 prose gives it none.

Test coverage to land alongside (pin shape only — implementation is
the fix author's call):

- Pin **presence** of the missing-host-key / missing-tier-row /
  bare-short-form fail-loud sentences in
  `test-config-model-routing.bats` (parallel to the existing
  `provider resolution: ...` test at line 124).
- Pin **absence** of the "silently fall back" / "silently degrade"
  anti-pattern wording in the schema doc body (parallel to the
  existing `[[ "$out" != *"halts and reports the unknown
  provider"* ]]` absence-pin at line 137).

## Severity rationale

**High**, not critical: the surface is doc-shaped (the SKILL prose is
the orchestrator's only contract), so a missing fail-loud rule
translates to "the orchestrator has discretion on partial corruption"
rather than "the code silently swallows the error." But the
discretion is being exercised in exactly the area (Copilot CLI proxy
fallback) where the silent-fallback class of bug already cost this
project enough to spawn the v0.7.1 hardening release. Shipping a
documented invariant without a documented violation contract
reintroduces the very surface the release exists to close.

## Out-of-scope observation (noted, not a finding)

Pre-existing — `tests/unit/test-config-model-routing.bats:187–192`
still pins `"role lookup"` in the Precedence chain section, while the
R1 fix rewrote step 3 to `"host/tier lookup"`. That test will fail in
GREEN after the R1 fix lands. This is a **loud** test break, not a
silent-failure surface, and is out of scope for this reviewer slot
(quality / consistency hunter territory), but flagged here in case
the fix author wants to bundle the test update with the silent-failure
repair above.
