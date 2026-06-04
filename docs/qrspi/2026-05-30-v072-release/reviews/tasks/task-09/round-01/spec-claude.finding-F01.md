---
finding_id: F01
severity: minor
change_type: style
referenced_files:
  - scripts/run-codex-review.sh
---

## Manifest entry includes fields outside task-09 scope; `subagent_type` overlaps T11 ownership

**What the spec says**

The task-09 "Out of scope" section states (emphasis added):

> G3 dispatch-manifest provenance fields (`subagent_type`/`host`/`vendor`/`model`/`prompt_file`) on pre-rename `scripts/run-codex-review.sh` — T11 owns; **this task touches the same dispatch manifest only for the `actual_model:` flow**.

The "In scope" description for the script is:

> Update `scripts/run-codex-review.sh` dispatch manifest persistence so each dispatch entry records **host, vendor, and resolved model metadata**.

**What was implemented**

`emit_dispatch_manifest_entry` (added at `scripts/run-codex-review.sh` line 558) emits entries with this shape:

```json
{
  "tag": "<REVIEWER_TAG>",
  "agent": "<agent_name>",
  "mode": "third_party",
  "status": "dispatched",
  "dispatch_spec": {
    "subagent_type": "<agent_name>",
    "host": "<detected_host>",
    "vendor": "openai-codex",
    "model": "<MODEL>"
  }
}
```

Fields beyond what the spec authorises for this task:
- `subagent_type` — explicitly listed under T11/G3 ownership in the out-of-scope.
- `tag`, `agent`, `mode`, `status` — not in the in-scope description ("host, vendor, and resolved model metadata") and not needed for the `actual_model:` flow the task is bounded to.

**Why it matters**

1. **T11 boundary conflict**: The spec explicitly assigns `subagent_type` to T11 (G3). Adding it here means T11 will find the field already present with a specific format choice it did not control. At minimum this complicates T11's diff and review; at worst it creates a conflicting schema commitment if T11's G3 design chose a different value shape for `subagent_type`.

2. **"only for the `actual_model:` flow" constraint**: The spec uses the word "only", which is a hard scope boundary. A minimal G20-compliant manifest entry only needs `host`, `vendor`, and `model` (so the manifest `model` value can be greppable alongside host/vendor and matched to reviewer-emitted `actual_model:` values).

**Suggested fix**

Slim the manifest entry to the fields the spec authorises:

```bash
printf -v entry '{"host":"%s","vendor":"openai-codex","model":"%s"}' \
  "$detected_host" "$MODEL"
```

or with minimal dispatch-identification context that doesn't pre-empt T11:

```bash
printf -v entry '{"tag":"%s","host":"%s","vendor":"openai-codex","model":"%s"}' \
  "$REVIEWER_TAG" "$detected_host" "$MODEL"
```

`tag` is the reviewer-tag identifier used in file globs throughout this pipeline, so including it is reasonable (it's not in T11's listed ownership and it directly enables host×vendor×model×tag greppability). Drop `agent`, `mode`, `status`, `subagent_type`, and the `dispatch_spec` nesting layer.

The acceptance test AC5 only asserts the presence of `"host"`, `"vendor"`, `"model"` fields and the model value — so slimming the entry will not break the test.
