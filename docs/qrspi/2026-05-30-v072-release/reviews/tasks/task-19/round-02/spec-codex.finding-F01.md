---
finding_id: F01
reviewer_tag: spec-codex
round: 2
severity: high
change_type: correctness
referenced_files:
  - scripts/second-reviewer-available.sh:43-55
  - docs/qrspi/2026-05-30-v072-release/tasks/task-19.md:42
---

The probe incorrectly treats a known vendor override as available even on an
`unknown` host. With no known host signals set and an override argument of
`openai-codex` (a recognized matrix vendor), `second-reviewer-available.sh
openai-codex`:

1. `_host="$(detect_host)"` resolves to `unknown`.
2. The override branch (L43-44) sets `_vendor="openai-codex"`, BYPASSING the
   host-default lookup `lookup_default_second_reviewer "$_host"`.
3. The availability guard (L51) is `[ "$_vendor" = "none" ] || !
   second_reviewer_vendor_known "$_vendor"`. Since `openai-codex` is a known
   flat-allowlist vendor and is not `none`, the guard is FALSE.
4. The script reaches L58-59 and exits 0.

This violates task-19.md DoD L42: "Unknown host, missing default vendor,
unknown vendor, and unavailable vendor all exit non-zero with exactly one
stderr line beginning `[second-reviewer-unavailable]` and naming the detected
host plus requested/default vendor." "Unknown host" is an independent
must-exit-non-zero condition with no override carve-out (DoD L53's override
boundary disclaims only `model_routing:` reading and primary/second
distinctness — NOT host reachability). It also contradicts the script's own
header contract: "Exit 0: the requested/default second-reviewer vendor is
potentially available FOR THE DETECTED HOST." On an unknown host no vendor is
reachable.

Fix: guard on the host having no default second-reviewer vendor
(`lookup_default_second_reviewer "$_host" = none`, which is exactly the
unknown/unsupported-host condition) BEFORE honoring the override, so unknown
host exits 1 with the `[second-reviewer-unavailable]` diagnostic naming host
and requested vendor. Known hosts (copilot-cli/claude-code/codex-cli) continue
to honor the override unchanged.
