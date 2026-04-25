# Fix Task Routing

Read this file only when handling fix tasks from integration, CI, or test failures (i.e., `fixes/{type}-round-NN/*.md` exists for the current dispatch). On a fresh phase dispatch, skip — fix-task routing does not apply.

## Routing Rules

- Read tasks from `fixes/{type}-round-NN/*.md` instead of `tasks/*.md`. Fix task files follow the same format as regular task files.
- For fix-task dispatches, append new branch entries directly to the Branch Map in `parallelization.md`. These are net-new tasks, not modifications to existing rows, so they belong in the Branch Map — not in `## Runtime Adjustments`, which is reserved for *changes to the effective base of a previously-approved task*.
- Fix-task additions are informational and do not require re-approval of `parallelization.md`.
- Reuse `review_depth` and `review_mode` from `config.md` — do not re-ask the user.
