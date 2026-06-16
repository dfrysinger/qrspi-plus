
Each QRSPI run creates an artifact directory. All paths are relative to the **project root** (the repository where QRSPI is being used, NOT the plugin install directory):

```
docs/qrspi/YYYY-MM-DD-{slug}/
├── config.md
├── goals.md
├── questions.md
├── research/
│   ├── summary.md
│   ├── q01-codebase.md
│   └── ...
├── design.md
├── phasing.md
├── roadmap.md
├── future-goals.md                (optional — Phasing-managed cross-phase scope)
├── future-questions.md            (optional — Phasing-managed cross-phase scope)
├── future-research-summary.md     (optional — Phasing-managed cross-phase scope)
├── future-design.md               (optional — Phasing-managed cross-phase scope)
├── structure.md
├── plan.md
├── parallelization.md
├── tasks/
│   ├── task-01.md
│   └── ...
├── fixes/
│   ├── integration-round-01/
│   ├── ci-round-01/
│   └── test-round-01/
├── feedback/
│   └── ...
└── reviews/
    ├── goals/
    │   ├── round-01/
    │   │   ├── quality-claude.finding-F01.md
    │   │   ├── quality-claude.finding-F02.md   (one file per finding)
    │   │   ├── scope-claude.clean.md            (zero findings → clean sentinel)
    │   │   ├── quality-codex.finding-F01.md
    │   │   └── scope-codex.clean.md
    │   ├── round-01.diff                      (orchestrator-emitted; reviewer dispatches Read it via `<diff_file_path>`)
    │   ├── round-01-scope-set.txt             (tagger-emitted per-round scope_tag list)
    │   ├── round-01-verified.md               (main-chat-authored: verifier assembly)
    │   └── round-01-dispositions.md           (main-chat-authored: what was fixed this round)
    ├── questions/                 (same shape; no scope reviewer for questions)
    ├── research/                  (same shape; no scope reviewer for research)
    ├── design/                    (same shape as goals/)
    ├── phasing/                   (same shape as goals/)
    ├── structure/                 (same shape as goals/)
    ├── plan/                      (same shape as goals/)
    ├── parallelize/               (same shape as goals/)
    ├── replan/                    (same shape as goals/)
    ├── baseline-failures.md       (Implement baseline)
    ├── tasks/
    │   └── ...
    ├── integration/
    │   ├── round-NN/
    │   │   ├── integration-claude.finding-F01.md
    │   │   ├── security-claude.finding-F01.md
    │   │   ├── integration-codex.finding-F01.md
    │   │   ├── security-codex.clean.md
    │   │   ├── implement-gate-claude.finding-F01.md   (when "Re-run all reviews" at Implement batch gate)
    │   │   └── implement-gate-codex.finding-F01.md    (same condition; only when second_reviewer: true)
    │   └── round-NN-dispositions.md
    ├── ci/
    │   └── round-NN-review.md
    └── test/
        ├── round-NN/
        │   ├── spec-claude.finding-F01.md
        │   ├── code-quality-claude.clean.md
        │   ├── goal-traceability-claude.finding-F01.md
        │   ├── spec-codex.finding-F01.md
        │   ├── code-quality-codex.clean.md
        │   └── goal-traceability-codex.finding-F01.md
        ├── round-NN-results.md            (main-chat-authored test results)
        └── baseline-failures.md           (Test baseline)
```

The slug is generated during the Goals step: take the user's first description, extract 2-4 key words, convert to lowercase kebab-case (e.g., "user-auth", "product-search-api").
