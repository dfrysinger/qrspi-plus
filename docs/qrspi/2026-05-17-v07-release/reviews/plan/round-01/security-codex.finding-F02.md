---
finding_id: R1-F02
severity: high
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L148-L155, docs/qrspi/2026-05-17-v07-release/plan.md:L198-L206]
artifact: plan
round: 1
reviewer: security-codex
---

The provider schema accepts `base_url` and `default_headers`, and the dispatcher sends the resolved API key to `<base_url>/chat/completions`, but the plan does not require validation of URL scheme, host shape, or header names/values. A malformed or hostile `config.md` could route credentials over plaintext HTTP, to a local/metadata endpoint, or inject extra headers via newline-containing header names or values. The current tests cover missing providers and transport branching, but not rejection of invalid provider config.

Fix: add fail-closed provider validation requirements before any network call: reject non-HTTPS URLs for `openai-chat-completions` unless an explicit documented local-test carve-out is active, reject localhost/link-local/metadata addresses unless explicitly allowed for a fixture, and reject header names/values containing control characters. Add unit tests proving these invalid configs exit 1 without issuing a request.
