---
finding_id: R7-F03
reviewer_tag: stitching-audit
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
artifact: structure
---

## Summary

The R6 fix extended the §10 dispatch manifest schema with `host` and `vendor` fields on both the first-party and background `dispatch_spec` entries, but no test row in structure.md explicitly pins that these fields appear in the emitted manifest.

## Detail

The R6 diff adds `host`/`vendor` to both `dispatch_spec` blocks in §10:

```json
// first-party entry — gained:
"host": "copilot-cli",
"vendor": "anthropic",

// background entry — gained:
"dispatch_spec": {
  "subagent_type": "qrspi-plan-reviewer",
  "host": "copilot-cli",
  "vendor": "openai",
  "model": "gpt-4.1"
},
```

Slice 1.2 (line 37) documents the writer: `scripts/dispatch-agent.sh` | Modify | "Add host/vendor/model metadata persistence into the dispatch manifest for later observability." | G20, G29.

The Slice 1.2 test (`tests/unit/test-verified-file-shape.bats`, line 38) pins "verified-file headers, kept/dropped counts, and instrumentation fields" — this is the verifier fan-in output file, not the dispatch manifest. The Slice 1.4 tests cover routing logic (`test-routing-matrix-application.bats`, line 96) and skills-to-script dispatch plumbing (`test-dispatch-sites.bats`, line 94), but neither names dispatch manifest schema shape as a guarded property.

Without a test that pins `host` and `vendor` in manifest entries, these observability fields can regress silently: a change to `_resolve-lib.sh` that drops the fields would not be caught until a human inspects the manifest. Design.md G20/G29 accept this surface — G29 specifically mentions the manifest's role in observability — but no cross-cutting invariant in Test Architecture §§ (lines 644–665) names manifest field presence as a T1/T2 property.

## Fix

One of the two test rows that already exercises `dispatch-agent.sh` output should be extended (or a new test row added) to explicitly pin that `dispatch_spec` entries include `host` and `vendor`. The cleanest placement is Slice 1.2, where `test-verified-file-shape.bats` could broaden its scope to "instrumentation fields and dispatch manifest metadata fields (host, vendor, model)" — or a new `tests/unit/test-dispatch-manifest-schema.bats` row could be added to Slice 1.2 with Goal IDs G20, G29, covering: first-party `dispatch_spec` shape, background `dispatch_spec` shape, and presence of `host`/`vendor`/`model` in both.
