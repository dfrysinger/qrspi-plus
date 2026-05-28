---
finding_id: R4-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L32-L46, docs/qrspi/2026-05-17-v07-release/design.md:L91-L97]
artifact: design
round: 4
reviewer: quality-codex
---

The routing schema gives the model identifier two different homes. G1 says `model_routing:` maps roles to concrete provider + model pairs, but the same section also says `providers:` lists the endpoint URL, model identifier, and API-key env var. G2 then describes provider configuration as base URL, env var, and default headers, with `--model` supplied separately to the dispatcher. Downstream Structure/Plan cannot implement this deterministically because it is unclear whether a provider entry is a reusable endpoint profile or a provider+model profile.

Fix: make the schema single-sourced. The cleaner contract is: `providers:` defines endpoint/auth/header metadata only, while `model_routing:` supplies the concrete model name for each role or task. If provider-level default models are intended, state that explicitly as an optional default and define how it interacts with the `model_routing:` model value.
