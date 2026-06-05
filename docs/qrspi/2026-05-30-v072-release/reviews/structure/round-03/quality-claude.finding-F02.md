---
artifact: structure
reviewer_tag: quality-claude
finding_id: R3-F02
round: 3
severity: high
change_type: correctness
line_range: [391, 408]
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

## Interface §14 misattributes `.dispatch-manifest.json` append to `dispatch-companion.sh` — design authority assigns it to `dispatch-agent.sh`

### Location

`## Interfaces` → `### 14. Dispatch companion script`, lines 406–408:

```bash
# Side effect (launch): appends {tag, mode: background, status: pending, await_cmd, split_cmd}
#                       entry to <round-dir>/.dispatch-manifest.json
```

### Problem

Interface §14 says `dispatch-companion.sh` (launch subcommand) has the side effect of appending the manifest entry to `.dispatch-manifest.json`. This contradicts design.md CD-1 §3 PATH B, which is an authoritative behavioral description of `dispatch-agent.sh`:

> "PATH B (third-party): invoke `dispatch-companion.sh` to launch background; **capture jobId**; **append entry to `.dispatch-manifest.json`** with `mode: background`, `status: pending`, `await_cmd`, `split_cmd`."

The grammatical subject of PATH B's entire bullet is `dispatch-agent.sh` (the universal entry point whose behavior CD-1 §3 is specifying). The sequence is:
1. `dispatch-agent.sh` invokes `dispatch-companion.sh` → launches background job
2. `dispatch-agent.sh` captures `jobId` from `dispatch-companion.sh`'s stdout
3. `dispatch-agent.sh` appends the manifest entry, constructing `await_cmd` and `split_cmd`

CD-1 §5's description of `dispatch-companion.sh` further confirms: it is a "vendor-routing tier underneath dispatch-agent … routes to vendor-specific transport" — no mention of manifest writing.

The `split_cmd` field (`"scripts/third-party-finding-splitter.sh --round-dir …"`) also supports this attribution: `dispatch-companion.sh` is vendor-transport-focused and has no reason to know about `third-party-finding-splitter.sh`; `dispatch-agent.sh` is the orchestrator-layer script that knows both the splitter and the round-dir.

### Impact

Interface §14 was added in R2 (disposition item 6). If implemented as specified, `dispatch-companion.sh` would own manifest-append logic that the design assigns to `dispatch-agent.sh`. This creates a dual-write risk and mis-scopes `dispatch-companion.sh`'s responsibilities. Plan/implementer tasks derived from structure.md will build the wrong ownership boundary into the two scripts.

### Fix

Remove the manifest-append side effect from Interface §14 and replace with the correct side effect:

```bash
# Side effect (launch): returns JOB_ID on stdout (consumed by dispatch-agent.sh, which
#                       appends the manifest entry to <round-dir>/.dispatch-manifest.json)
```

The manifest-append side effect belongs in Interface §3 (Universal dispatch CLI) or in `dispatch-agent.sh`'s description prose — not in §14.
