---
finding_id: R3-F01
reviewer_tag: stitching-audit
severity: high
change_type: correctness
gap_class: missing-wiring
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: [195, 202]
---

# Interface §3 missing `--verifier-fanout` mode invocation form

## Gap description

Interface §3 ("Universal dispatch CLI") at structure.md lines 195–202 documents only the
**reviewer dispatch** invocation form of `scripts/dispatch-agent.sh`:

```bash
scripts/dispatch-agent.sh --step <step> --round <N> --output-dir <round-dir> \
  --artifact <artifact-name> \
  --agents tag1=agent-name-1,tag2=agent-name-2,... \
  [--task-branch <worktree-path> --implementer-commit <40-char-SHA>] \
  [--tier-override tag1=high,tag2=medium,...]
# Stdout: M lines of form: MODE=first_party TAG=<tag> SUBAGENT_TYPE=<agent-name> MODEL=<resolved-model> PROMPT_FILE=<absolute-path>
```

The `--verifier-fanout` mode is entirely absent from Interface §3. This mode is a first-class
CD-4 deliverable specified in design.md CD-4 §H (lines ~464–503), which locks a distinct
invocation form with a different argument set:

```bash
scripts/dispatch-agent.sh --verifier-fanout \
  --step <step> --round <N> --output-dir <round-dir> \
  [--tier-override <tier>]
```

The two modes differ significantly in semantics: `--agents` is not used; `--artifact` is
not used; the script auto-enumerates findings under `--output-dir` instead of taking an
explicit agent list. The stdout contract is also different: one spec line per **finding**
(not per reviewer tag).

## Why this is high severity

Interface §3 is the implementer's contract for `dispatch-agent.sh`. Without `--verifier-fanout`
in the interface, an implementer who reads only structure.md will build a script that handles
only reviewer dispatch. CD-4's verifier dispatch path — which eliminates the per-finding
orchestrator loop and is a core G12 acceptance criterion — will either be omitted entirely or
implemented inconsistently with the design.

CD-4 G12 acceptance criteria (design.md lines ~708) explicitly require:
> "`scripts/dispatch-agent.sh --verifier-fanout` exists and emits one spec line per finding"

The structure.md File Map row for `dispatch-agent.sh` in Slice 1.4 (line 60) also omits any
mention of the `--verifier-fanout` mode, listing only: "Universal batched dispatch entrypoint:
resolve tier/model, prepare rounds, write manifests, and emit first-party task specs." The
omission is consistent across both the file map row and Interface §3, meaning the implementer
has no structural.md signal that this mode exists.

## Stitching chain broken

The verifier fan-out forms a dedicated chain:

```
orchestrator → dispatch-agent.sh --verifier-fanout → spec lines (per finding)
→ parallel Task batch (one per spec line) → verifier sidecars
→ await-round.sh → verifier-fan-in.sh → kept-findings.txt
```

Without the `--verifier-fanout` mode in Interface §3, the seam between **orchestrator prose**
(which will call this mode per `skills/_shared/verifier-dispatch-prose.md`) and the
**script implementation** is broken: the prose calls a mode the implementer was never told
to build.

## Minimal-altitude fix

Add a second invocation block to Interface §3 documenting the `--verifier-fanout` form with:
- its distinct flag set (`--verifier-fanout`, `--step`, `--round`, `--output-dir`,
  `[--tier-override <tier>]`)
- its auto-enumeration behavior ("script globs `<round-dir>/*.finding-F*.md` to enumerate
  findings; `--agents` is not used")
- its stdout contract ("one spec line per finding: `MODE=first_party TAG=<reviewer-tag>.F<NN>
  SUBAGENT_TYPE=qrspi-finding-verifier MODEL=<resolved-model> PROMPT_FILE=<absolute-path>`")

Also extend the Slice 1.4 `dispatch-agent.sh` Create row responsibility to mention the
`--verifier-fanout` mode explicitly.
