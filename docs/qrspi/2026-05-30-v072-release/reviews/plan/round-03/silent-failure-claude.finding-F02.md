---
reviewer_tag: silent-failure-claude
round: 3
artifact: plan.md
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
---

# F02 — T11 dispatch-manifest provenance has no fail-loud requirement when a resolved field is missing/unknown

## What is wrong

T11 (`G3 dispatch-manifest provenance fields ... in .dispatch-manifest.json`) requires the dispatch script to persist five provenance fields in every manifest entry — `dispatch_spec.subagent_type`, `dispatch_spec.host`, `dispatch_spec.vendor`, `dispatch_spec.model`, and `dispatch_spec.prompt_file` (DoD bullets 1–2). The DoD also requires append behavior to be "atomic and append-safe across multiple reviewer tags ... no entries are lost or malformed."

What the DoD and Test Expectations are **silent on**: what happens when one of those resolved fields cannot be determined at dispatch time. There is no requirement that the script halt loud if:

- `host` cannot be detected (`_host-detect.sh` returns `unknown`),
- `vendor` resolves to nothing (no matrix entry for this host),
- `model` resolves to `none` (the `extra-low: none` operator-only surface — or any other tier configured as `none`), or
- the resolver chain falls through to `default_tier: medium` without a `model_routing.medium:` value being present.

The Test Expectations only inspect that the keys **exist** in the JSON:
> *"Exercise a first-party reviewer dispatch and inspect `.dispatch-manifest.json` for a `dispatch_spec` object containing `subagent_type`, `host`, `vendor`, `model`, and `prompt_file`."*

A manifest entry like `{"dispatch_spec": {"host": "unknown", "vendor": null, "model": null, ...}}` would satisfy every assertion in T11's Test Expectations block, yet would silently record a dispatch that proceeded without resolved provenance.

## Why this is a silent-failure class

The round-03 dispatch prompt called this concern out by name:

> *"T11's dispatch-manifest provenance fields — if any are missing or malformed at dispatch time, does Test Expectations require fail-loud or does it allow log-and-continue?"*

The answer is: Test Expectations **allow log-and-continue by silence**. T11 specifies write semantics but not value-quality preconditions.

This matters because the dispatch-manifest is the audit trail that downstream calibration consumers (T09 `actual_model:` flow), the security exfil guard (T21), and Test-phase acceptance checks all rely on. A manifest that records `host: "unknown"` instead of halting on unknown host is the SILENT_FALLBACK class — readers cannot distinguish "dispatch happened with degraded provenance" from "dispatch happened with full provenance and the calibration data is real."

Worse, T11 sits **before** T20's rename and per-skill prose migration in the dependency graph. If T11 ships permissive write semantics, every later consumer (T20's `await-round.sh` drain, T09's `actual_model:` cross-check, T21's path-filter audit) inherits the same permissive provenance and may make decisions on `null`/`unknown` values without halting.

CD-1 explicitly forbids silent fallback at the `_resolve-lib.sh` layer ("halts loudly when the selected tier is configured as `none`; it never silently falls back to a neighboring tier or agent-bundled model" — T16 DoD). The dispatch-manifest writer is the consumer of that resolution; it should mirror the same fail-loud posture rather than persist whatever the resolver returned.

## Where this is in the artifact

- plan.md `### Task 11: G3 dispatch-manifest provenance fields (subagent_type / host / vendor / model / prompt_file in .dispatch-manifest.json)` →
  - `**Definition of done**` bullets 1–5 (specifies field presence and atomicity, not value-resolution preconditions)
  - `**Test expectations**` bullets 1–4 (only checks key presence, not value quality)

## What a fix looks like

Add one DoD bullet and one Test Expectations bullet:

**DoD addition:** *"If any of `host`, `vendor`, or `model` cannot be resolved at dispatch time (unknown host, no matrix entry, tier configured as `none`, or fallback default unconfigured), the dispatch script exits non-zero with a diagnostic naming the unresolved field and the resolution path that failed; no manifest entry is appended with `null`, `unknown`, or other placeholder values for these three fields. `subagent_type` and `prompt_file` are call-site inputs and must be validated before any resolution begins."*

**Test Expectations addition:** *"Exercise four halt fixtures — unknown host, vendor-not-in-matrix, tier resolved to `none`, and resolver fall-through to an unconfigured `default_tier:` — each exits non-zero with a diagnostic naming the unresolved field and produces no new manifest entry."*

The implementation cost is small (the resolver already has fail-loud semantics per T16; T11 needs to propagate them past the resolver boundary). The plan-level cost is zero ripple — no other task spec changes.

## Confidence

high — the round-03 dispatch prompt explicitly asked the question; the DoD and Test Expectations literally do not answer it.
