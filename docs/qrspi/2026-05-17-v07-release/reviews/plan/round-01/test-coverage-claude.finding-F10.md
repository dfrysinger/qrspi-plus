---
finding_id: R1-F10
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md]
artifact: plan
round: 1
reviewer: test-coverage-claude
---

T03's test expectations are missing the empty-string API key edge case that design.md explicitly requires.

Design.md's G2 test strategy (design.md line 134) states: "Key-resolution test: a missing or empty environment variable named in providers: causes a validation failure (exit 1) at call time, not a silent attempt with an empty Authorization header."

T03's test expectations cover provider-resolution failure ("When --provider does not match any entry in artifact-dir/config.md, the script exits 1") and the general "exits 1 and names the missing flag" for argument failures — but no expectation explicitly covers the case where `api_key_env` is set in config.md, the environment variable EXISTS, but its value is an empty string. The design's requirement covers both "missing" (variable unset) and "empty" (variable set to empty string).

A test writer following T03's expectations could write a test that checks for an unset variable but miss the empty-string case entirely. Since an Authorization header with an empty Bearer token is a security-relevant failure mode (the request may still be sent with no authentication), this edge case deserves its own explicit expectation.

Add to T03's test expectations: "When the environment variable named in providers: api_key_env exists but is set to an empty string, the script exits 1 with a validation diagnostic at call time, without issuing the HTTP request."
