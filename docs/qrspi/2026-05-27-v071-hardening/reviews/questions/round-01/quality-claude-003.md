---
id: quality-claude-003
artifact: questions
severity: MEDIUM
check: objectivity
---

## Finding

**Q4** asks specifically whether `.qrspi/` or `.qrspi-*` patterns appear in `.gitignore`, probing for the exact paths that G2 Candidate A proposes as a fix. This frames the research question around a pre-selected solution rather than the current state of the file.

### Offending text

> What paths and glob patterns does the repo's `.gitignore` currently match, and **does the `.qrspi/` directory or any `.qrspi-*` file pattern appear in it?**

### Problem

G2 Candidate A proposes: "Add `.qrspi-commit-msg.txt` to `.gitignore`… or move the scratch to a path already gitignored such as under `.qrspi/`." The second clause of Q4 is a direct probe for whether those specific candidate paths are already covered. A researcher answering this question is effectively executing a readiness check for Candidate A, not neutrally cataloguing `.gitignore` contents.

The neutral research need here is: "what is currently in `.gitignore`, does the scratch file's path (or any scratch-adjacent pattern) already appear, and are there any existing conventions for project-tool scratch paths?" Naming `.qrspi/` and `.qrspi-*` tells the researcher — and any observer — that those are the paths we're considering adding.

### Suggested rewrite

> What paths and glob patterns does the repo's `.gitignore` currently match, and does it contain any patterns for tool-generated scratch files or agent working-directory artifacts?

This retains the research value (auditing current `.gitignore` coverage) without exposing the specific fix candidate paths.
