---
finding_id: R13-F03
severity: medium
change_type: correctness
referenced_files: [/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L788-L789,/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L826-L831]
artifact: design
round: 13
reviewer: quality-codex
---

G17 overstates what the bash-3.2 portability gate can rely on. The design repeatedly frames the verification as shellcheck-based ("shellcheck under bash 3.2 dialect rules"), but shellcheck does not provide a true Bash-version compatibility mode that can enforce "works on 3.2" for constructs like `mapfile`, associative arrays, or `${var,,}`. As written, this can produce a CI surface that looks like a 3.2 gate while missing exactly the syntax class the goal is trying to block. Fix: name a real verification mechanism for the version check that is distinct from ordinary shellcheck linting, or explicitly say shellcheck is only one input and that a separate 3.2 parser/runtime check is required.
