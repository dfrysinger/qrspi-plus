---
finding_id: F01
reviewer_tag: silent-failure-claude
severity: high
change_type: correctness
referenced_files:
  - scripts/second-reviewer-available.sh:43-58
---

## Vendor override on unknown host exits 0 — host-compatibility check skipped

### What the code does

`second-reviewer-available.sh` takes an optional vendor override (`$1`). When an
override is supplied, the probe skips the default lookup entirely and jumps straight
to:

```bash
if [ "$_vendor" = "none" ] || ! second_reviewer_vendor_known "$_vendor"; then
  # emit [second-reviewer-unavailable] and exit 1
fi
printf '%s\n' "$_vendor"
exit 0
```

`second_reviewer_vendor_known` is a **flat allowlist** (`openai-codex|anthropic-claude`);
it does not consult the host × vendor matrix column at all.

### The silent failure

When the detected host is `unknown` (no `COPILOT_CLI` or `CLAUDE_PROJECT_DIR` signal)
and a caller passes a recognized vendor as an override argument, the probe exits **0**:

```
$ unset COPILOT_CLI CLAUDE_PROJECT_DIR
$ bash scripts/second-reviewer-available.sh openai-codex
openai-codex          # stdout
$ echo $?
0                     # success — but the host is unknown!
```

No `[second-reviewer-unavailable]` diagnostic is emitted, no error is signalled.

### Why this violates the contract

The probe's own header documents:

> **Exit 0**: the requested/default second-reviewer vendor is *potentially available
> for the detected host*.

On an `unknown` host the availability of any vendor is undetermined; the matrix has
no row for `unknown`. The correct result is exit 1 with `[second-reviewer-unavailable]`.
The current implementation conflates "this vendor ID is syntactically recognized" with
"this vendor is reachable on the current host" — a host-agnostic allowlist cannot
satisfy a host-specific availability contract.

### Concrete failure path

A Goals orchestrator running in a non-Copilot-CLI, non-Claude-Code environment with
`CODEX_CLI=1` (which maps to `unknown` in v0.7.2) and an explicit vendor override
will silently believe the second reviewer is available, write `second_reviewer: true`,
and dispatch a second reviewer that cannot actually be reached.

### Fix direction

Before accepting the override vendor, confirm the override vendor is reachable on the
detected host (e.g. consult the host × vendor matrix via `lookup_host_vendor_path`, or
reject overrides when `_host = "unknown"`):

```bash
if [ "$_host" = "unknown" ]; then
  printf '[second-reviewer-unavailable] host=%s vendor=%s — unrecognised host, cannot confirm vendor reachability\n' \
    "$_host" "${1:-none}" >&2
  exit 1
fi
```
