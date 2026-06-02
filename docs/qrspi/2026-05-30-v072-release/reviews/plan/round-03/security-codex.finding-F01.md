---
reviewer_tag: security-codex
change_type: correctness
severity: high
artifact: plan.md
location: Task 11 + Task 20 test/DoD contracts
referenced_files: [plan.md]
---

# F01 — Dispatch manifest is treated as trusted input without a fail-closed validation contract

Task 11 requires writing `dispatch_spec` fields and only tests for field presence/well-formed JSON (`plan.md` lines 707–719), but does not require rejecting malformed or forged manifest entries.  
Task 20/await-round behavior consumes manifest entries to drive background completion/splitting (`plan.md` lines 1185, 1202, 1213), and structure/design explicitly model command-bearing manifest fields (`await_cmd`, `split_cmd`) as execution inputs.  
That creates a fail-open path: a tampered `.dispatch-manifest.json` can spoof provenance (`host/vendor/model/subagent_type/prompt_file`) and potentially steer round processing, while still satisfying current acceptance checks that only assert presence/shape.  
A security-hardening plan should explicitly add schema + semantic validation (required keys, allowed enums/hosts/vendors, path constraints, command template constraints, and reject-on-invalid before execution).
