---
finding_id: R17-F03
severity: high
change_type: correctness
referenced_files: [design.md:L806-L810, design.md:L853-L855]
artifact: design
round: 17
reviewer: quality-codex
---

The G17 bash-3.2 CI design overstates what the proposed load-bearing gate can prove. `bash --posix -n` on macOS Bash 3.2 is only a parse check; it does not execute builtins, so constructs like `declare -A` parse successfully even though they are not supported at runtime on Bash 3.2. The design currently says the `declare -A` rejection “MUST originate” from Option A and gives `${!array[@]}` as a non-ban-list example that Option A would catch, but both assumptions are incorrect for a parser-only check. As written, the CI contract would claim stronger bash-3.2 coverage than it actually provides. Fix by revising Option A’s guarantee to “parse-time compatibility only” and either broadening Option B / adding targeted execution probes for runtime-only incompatibilities, or choosing a different load-bearing compatibility check.
