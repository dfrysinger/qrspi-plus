---
finding_id: R5-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L46-L48]
artifact: design
round: 5
reviewer: quality-codex
---

The G1 provider schema contradicts itself. Line 46 says the `providers:` block does not carry the model identifier and that model identifiers live in `model_routing:` only, but line 48 then allows `providers:` entries to carry `default_model:` and says it is used when repeated `model_routing:` values would otherwise be redundant. That leaves downstream Structure/Plan unable to know whether `providers.default_model` is legal schema or an invalid provider-level model surface.

Fix by choosing one contract. Either remove `providers.default_model` entirely and keep model identifiers exclusively in `model_routing:`, or revise the provider/config language so `providers.default_model` is explicitly a legal fallback model source and update the “single source of truth” wording accordingly.
