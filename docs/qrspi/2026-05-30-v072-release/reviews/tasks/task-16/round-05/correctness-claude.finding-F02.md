---
finding_id: R5-F02
severity: medium
change_type: correctness
referenced_files: [scripts/_resolve-lib.sh]
---
Unset/missing CONFIG_MD is masked as a routing-table error. In `resolve_model`, when CONFIG_MD is unset or the file is absent, the outer `-f` guard leaves `row` empty and the function emits "[routing] HALT: tier X resolves to none (unconfigured tier); configure model_routing.X" — sending an operator who has a correct config down the wrong repair path. In `resolve_tier`, the same condition silently skips Layer 3 and drops to the Layer-4 "no tier resolved; falling back to hardcoded medium" warning, masking the missing-config-path root cause; an operator with a correct `default_tier:` believes their config was consulted when it never was. Error-transformation in a fail-loud hardening release. Convergent: cq-claude F02, sf-claude F02 (resolve_model), sf-claude F03 (resolve_tier). Fix: in `resolve_model`, hard-fail immediately with a distinct "CONFIG_MD unset/file-not-found" diagnostic before the row lookup. In `resolve_tier`, preserve the documented medium fallback but make the Layer-4 warning name CONFIG_MD-unset as the cause when that is why Layer 3 was skipped.
