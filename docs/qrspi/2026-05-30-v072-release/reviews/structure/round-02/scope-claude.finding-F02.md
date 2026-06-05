---
finding_id: R2-F02
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
artifact: structure
line_range: [162, 391]
---

## OWNS gap — No interface contracts for `dispatch-companion.sh`, `await-round.sh`, or `third-party-finding-splitter.sh`

**What the artifact does.**  
The File Map (Slice 1.4, lines 60–96) lists three public scripts as Create actions:

| Script | Responsibility |
|---|---|
| `scripts/dispatch-companion.sh` | Launch vendor-specific third-party review jobs beneath the universal dispatcher |
| `scripts/await-round.sh` | Drain background reviewer jobs, finalize manifest state, and write round completion summaries |
| `scripts/third-party-finding-splitter.sh` | Split third-party stdout boundaries into per-finding files |

The `## Interfaces` section (lines 162–391) defines 13 numbered interface entries. None of the three scripts above has a dedicated entry.

**Why this is an OWNS gap.**  
Structure OWNS "Function/script exports and parameter shapes. Public function signatures, exported types, script entry points, CLI argument shapes — what the unit exposes at its boundary." All three scripts are non-underscored (public by naming convention), all are Create actions (newly introduced by this release), and all have distinct CLI surfaces invoked by downstream consumers:

- `dispatch-companion.sh` is invoked by `dispatch-agent.sh` to launch background third-party jobs and reappears as the `await_cmd` prefix in the dispatch manifest (Interface §10 example: `"scripts/dispatch-companion.sh await job-123"`). Its argument shapes, exit codes, and stdout format are unknown.
- `await-round.sh` is the post-dispatch drain step referenced in the shared verifier-dispatch-prose snippet (Slice 1.1 Responsibility: "`await-round.sh` follow-up"). It has no invocation signature anywhere in the Interfaces section — neither CLI shape nor exit codes.
- `third-party-finding-splitter.sh` appears in the dispatch manifest as the `split_cmd` value (Interface §10 example: `"scripts/third-party-finding-splitter.sh --round-dir /abs/path/reviews/plan/round-01"`), but the `--round-dir` argument is the only hint of its interface. Exit codes, success contract, and output paths are unspecified.

The analogous gap for `scripts/detect-interaction-mode.sh` was caught by R1 quality reviewers (R1-F04, severity high) because design.md CD-4 §I.7 had a detailed locked contract for it. The three scripts above likewise have public CLI surfaces that Plan/Implement will need interface contracts to work against.

**Partial coverage through Interface §10 is not sufficient.**  
Interface §10 (Dispatch manifest schema) embeds `dispatch-companion.sh` and `third-party-finding-splitter.sh` invocation examples as string values inside JSON. That shows invocation patterns incidentally, not as authoritative interface entries. `await-round.sh` is not present in Interface §10 at all. None of the three scripts has exit codes, output contracts, or argument-shape specifications.

**What Structure should add.**  
Three new Interfaces entries (or equivalent short-form contracts in the Section Contracts table) covering at minimum:

- CLI argument shape / required flags
- Exit code semantics (success / failure conditions)
- Stdout/side-effect outputs (e.g., what `await-round.sh` writes as a round completion summary; where `third-party-finding-splitter.sh` emits per-finding files)

Prose content under each script's implementation (what it does internally) remains DEFERS to Plan/Implement.
