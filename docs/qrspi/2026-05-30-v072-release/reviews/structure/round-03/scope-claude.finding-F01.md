---
finding_id: R3-F01
reviewer_tag: scope-claude
artifact: structure
change_type: scope
severity: minor
line_range: [546, 550]
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - .github/workflows/ci.yml
---

## Finding

**`## CI Pipeline` Build-sync gate bullet embeds implementation commands inside a section-list contract.**

### Location

`## CI Pipeline` → Build-sync gate bullet, lines 546–550.

```markdown
- **Build-sync gate inside PR CI**: after checkout and Node setup, run
  `node tools/build-plugin.mjs` and then
  `git diff --exit-code build/ .claude-plugin/marketplace.json`;
  any stale built tree or malformed `!cat` stops the PR.
  This is the G32 release-integrity gate.
```

### Why it drifts

Structure OWNS section-list contracts at **heading-level granularity, not prose content** (OWNS rule: "Which top-level sections each file must contain… Heading-level granularity, not prose content"). For `.github/workflows/ci.yml`, the three bullets correctly name three CI job/section boundaries (lint, build-sync gate, BATS execution shape). That naming is within OWNS.

The **Build-sync gate bullet body**, however, goes further:

- it specifies the exact commands to execute inside the job (`node tools/build-plugin.mjs`, `git diff --exit-code build/ .claude-plugin/marketplace.json`),
- it imposes the step ordering within the job ("after checkout and Node setup, run X and then Y"),
- it describes what the step does when it fails ("any stale built tree or malformed `!cat` stops the PR").

These are the **implementation steps inside a CI job body** — the plan/implement task spec for G32, not the section-list contract for the file. The other two bullets stay at the right level (they name the section and reference which test files or coverage it adds, without specifying job-body commands). This bullet breaks the pattern.

Counterpart note: the lint and BATS-shape bullets do reference specific test-file paths — that is consistent with OWNS "test file layout" — so those bullets are fine. Only the Build-sync gate bullet drifts.

### Required fix

Trim the Build-sync gate bullet to heading-level: name the job section and the property it validates (G32 build-sync integrity), remove the commands and step sequencing. The exact `node tools/build-plugin.mjs` + `git diff` invocation belongs in the Plan task spec for G32, Slice 1.7.

**Before (drift):**
```
- **Build-sync gate inside PR CI**: after checkout and Node setup, run
  `node tools/build-plugin.mjs` and then
  `git diff --exit-code build/ .claude-plugin/marketplace.json`; …
```

**After (within OWNS):**
```
- **Build-sync gate inside PR CI**: guards that the committed `build/`
  tree matches source; blocks PRs when the built plugin is stale or
  `!cat` expansion has drifted. G32 release-integrity gate.
```
