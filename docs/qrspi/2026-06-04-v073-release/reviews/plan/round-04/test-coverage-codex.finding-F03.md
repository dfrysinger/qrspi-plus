---
finding_id: R4-F03
severity: medium
change_type: correctness
referenced_files:
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-06-04-v073-release/plan.md:L859-L866
artifact: plan
round: 4
reviewer: test-coverage-codex
---

T37 requires tokenization with a pinned default tokenizer (`tiktoken:cl100k_base`), but the test expectations never verify tokenizer identity/pinning. A different tokenizer could pass the current checks while violating the task contract. Add a deterministic expectation that proves the tokenizer pin (e.g., emitted tokenizer ID and/or known-token-count fixture tied to `cl100k_base`).
