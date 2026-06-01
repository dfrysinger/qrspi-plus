---
finding_id: R4-F02
reviewer_tag: stitching-audit
severity: medium
change_type: correctness
gap_class: missing-wiring
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: [65, 65]
---

# `_resolve-lib.sh` responsibility description omits agent-frontmatter parsing, leaving the `agents/*.md` sweep output without an explicit consumer path

## Gap description

R3 added the `agents/*.md (sweep — all 41 files)` Modify row to Slice 1.4 (structure.md
line 93). That row produces agent files each carrying a `tier:` frontmatter field. The
downstream consumer is `scripts/_resolve-lib.sh`, which is called by `dispatch-agent.sh`
(and internally during `--verifier-fanout` mode) to resolve the tier → vendor → model chain.

However, structure.md's `_resolve-lib.sh` file-map row (line 65) describes its
responsibility as:

> "Own host×vendor routing, tier resolution, default-tier fallback, and fail-loud
> routing lookups."

It does **not** name agent-frontmatter parsing — the mechanism by which `_resolve-lib.sh`
reads `tier:` from `agents/<agent-name>.md` at dispatch time. Design.md is explicit about
this:

> design.md CD-1 component #7 (line 107): "`scripts/_resolve-lib.sh` — shared library:
> **agent-frontmatter parsing**, tier→vendor+model lookup against config.md's
> `model_routing:` table, `default_tier:` fallback, and fail-loud halt."

The stitching gap is: the sweep adds `tier:` fields to agent files, `_resolve-lib.sh`
says "tier resolution," but the connection — that `_resolve-lib.sh` reads
`agents/<agent-name>.md` frontmatter to get the tier — is not stated in structure.md.
An implementer reading only structure.md cannot tell what input the tier-resolution logic
consumes or where to find agent tier values at script runtime.

The gap is also present in the `--verifier-fanout` path: §3 says dispatch-agent.sh
resolves the verifier agent's tier via `_resolve-lib.sh` using hardcoded
`qrspi-finding-verifier` as the agent name, but there is no structure-level statement
that the resolution reads `agents/qrspi-finding-verifier.md` frontmatter.

## Authority (cite design.md section)

design.md CD-1, component list (lines 107–108):
> "`scripts/_resolve-lib.sh` — shared library: agent-frontmatter parsing,
> tier→vendor+model resolution, host × vendor matrix lookup. Single source of truth
> for resolution algorithm."

design.md CD-1, dispatch-agent.sh behavior step (line 70):
> "Resolve agent tier → vendor → model via `_resolve-lib.sh`."

design.md G22 deliverable 1 (lines 1950–1960): tier-assignment rubric establishes that
agent files carry `tier:` as the first-lookup value in the resolution chain
(`--tier-override` → agent `tier:` → `default_tier:` → hardcoded medium).

## Impact on implementation

Without "agent-frontmatter parsing" named explicitly in `_resolve-lib.sh`'s structure
responsibility, Plan may not assign a task to implement the file-read logic, or may place
it in `dispatch-agent.sh` instead of in the shared library. This would fragment the
"single source of truth" that design.md requires and create a seam where future
agents or override paths bypass the canonical lookup.

Additionally, the `--verifier-fanout` mode (§3) relies on the same mechanism for
`qrspi-finding-verifier`'s tier resolution; without the connection being named, that path
could be implemented with a hardcoded tier bypass rather than the frontmatter read,
silently voiding the verifier's participation in tier-assignment changes.

## Fix (Structure-altitude only)

Extend the `_resolve-lib.sh` Modify row's Responsibility column to name the
agent-frontmatter read:

> `scripts/_resolve-lib.sh` | Create | Own host×vendor routing, **agent-frontmatter
> parsing (reads `tier:` from `agents/<agent-name>.md` frontmatter at dispatch time),**
> tier→vendor+model resolution, default-tier fallback, and fail-loud routing lookups. | G22, G23, G25, G27

This connects the sweep output (agent files gain `tier:`) to the dispatch consumer
(`_resolve-lib.sh` reads `tier:`) at structure altitude — no prose content required.
