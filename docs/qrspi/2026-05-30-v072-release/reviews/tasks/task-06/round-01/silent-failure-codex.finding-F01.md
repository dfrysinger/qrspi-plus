---
finding_id: R1-F01
reviewer_tag: silent-failure-codex
round: 1
task: 6
severity: medium
change_type: test_coverage
referenced_files:
  - tests/unit/test-verifier-agent-file.bats
---

# F01 — Canonical-input assertion is vacuous (single `canonical` alternative matches anywhere)

## Location

`tests/unit/test-verifier-agent-file.bats:90`

```bash
echo "$body" | grep -qiE 'canonical|disk.*sidecar|sidecar.*canonical|fan.in.*sidecar|sidecar.*fan.in' \
  || { echo "verifier agent does not identify disk sidecar as canonical fan-in input"; return 1; }
```

## Silent-failure risk

The standalone alternative `canonical` matches ANY occurrence of the word in the agent body — including "canonical reviewer path", "canonical reviewer tag", or any unrelated future use of the word. The verifier agent could stop stating that the disk sidecar is the fan-in source of truth, and this test would still pass, masking a load-bearing contract regression.

## Fix

Require both signals concurrently — the word "canonical" AND a sidecar-fan-in pairing:

```bash
echo "$body" | grep -qiE 'sidecar.*canonical.*fan.in.*input|disk.*sidecar.*canonical.*fan.in|fan.in.*input.*sidecar.*canonical' \
  || { echo "verifier agent does not identify disk sidecar as canonical fan-in input"; return 1; }
```

Or simpler — assert the literal substring the implementer documented in Step 6 (`"the load-bearing fan-in input"` or equivalent), so a future edit removing that contract sentence breaks the test loudly:

```bash
echo "$body" | grep -qF "load-bearing fan-in input" \
  || { echo "verifier agent missing canonical disk-sidecar-as-fan-in-input contract"; return 1; }
```
