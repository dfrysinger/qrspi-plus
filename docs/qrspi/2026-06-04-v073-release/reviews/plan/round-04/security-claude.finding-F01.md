---
finding_id: R04-F01
severity: medium
change_type: scope
referenced_files: ["docs/qrspi/2026-06-04-v073-release/plan.md"]
artifact: plan
round: 4
reviewer: security-claude
---

T28 (`VERSION` + `tools/build-plugin.mjs`) requires VERSION to be non-empty and single-line, but the test expectations include no case for a VERSION string containing JSON metacharacters (`"`, `\`, or control characters within the line). Because `tools/build-plugin.mjs` writes the raw VERSION string directly into the `"version"` JSON field of all five consumer manifests, a VERSION line such as `0.7.3", "injected": "` is structurally valid under the existing checks (non-empty, single-line) but produces broken or adversarially-shaped JSON in all five output files. The CI gate (`build-then-diff.yml`) detects drift between the committed and freshly-built trees but cannot detect that the freshly-built output is itself malformed JSON.

This gap is distinct from the semver allowlist deferred by the prior security-claude R2-F02 finding. The design.md deferred "stricter validation" (enforcing `\d+\.\d+\.\d+` format) on the grounds that "it can land later if it matters." JSON metacharacter safety is not format strictness — it is a minimum precondition for writing into any JSON string value, and the design.md's stated rationale ("just reads the line and writes it through") does not address this character class.

**Required addition to T28 test expectations:** A test case asserting that a VERSION file containing a JSON metacharacter (at minimum: `"` — a bare double-quote as the sole content, or a version string embedding a `"`) triggers the `version-source-missing-or-malformed:` named diagnostic and exits non-zero. The validation rule in the description should be updated to: "single non-empty line containing no JSON metacharacters (`"`, `\`, or control characters)."

