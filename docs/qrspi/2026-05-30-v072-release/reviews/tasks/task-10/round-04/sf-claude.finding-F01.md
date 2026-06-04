---
finding_id: R4-F01
severity: high
change_type: correctness
referenced_files: [agents/qrspi-finding-verifier.md]
---

# Malformed defect_class token — prose describes rejection but provides no recovery action

**Location:** `agents/qrspi-finding-verifier.md` step 5.5 Shape paragraph.

The Shape paragraph says "Uppercase letters, underscores, spaces, dots, slashes, and other punctuation are rejected." Passive voice describes the rule but provides NO recovery instruction. The `unspecified` fallback paragraph scopes the fallback only to absence-of-signal cases ("does not fit any meaningful defect category"), NOT to the case where the agent has a meaningful category in mind but would express it with a malformed token.

Examples of unguarded gaps:
- `defect_class: swallowed_error` (underscore instead of hyphen)
- `defect_class: Silent Fallback` (space + uppercase)
- `defect_class: fabricated-citation-in-the-original-finding` (>30 chars)
- `defect_class: -leading-hyphen` (leading hyphen)

**Why HIGH:** silent-failure category — no test performs behavioral assertion against actual verifier output (every new test is doc-shape grep against agent prose), AND `defect_class:` is "consumed by no current surface" so malformed tokens silently persist in artifact-directory sidecars with no runtime rejection. Future cluster-analysis tooling would encounter bad tokens in production sidecars without any upstream signal.

**Mitigating context for disposition:** cluster-analysis is explicitly deferred to a future release per G28; `defect_class:` has no current consumer; the unspecified-fallback prose IS documented (just not connected to the rejection clause). Practical impact is bounded to future-readiness, not active data corruption.

**Recommended fix (one sentence to Shape paragraph):**
> "… are rejected. If the token you are about to emit would fail this rule — for any reason including length, character class, or leading hyphen — emit `defect_class: unspecified` instead."
