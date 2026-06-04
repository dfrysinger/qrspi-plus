---
finding_id: R3-F01
reviewer_tag: silent-failure-codex
round: 3
severity: high
change_type: correctness
referenced_files:
  - scripts/second-reviewer-available.sh:L37-L62
---

`second-reviewer-available.sh` can silently report success when a critical helper
fails. The script sources `_resolve-lib.sh` and captures
`lookup_default_second_reviewer` via command substitution, but does not check
either command's exit status (`scripts/second-reviewer-available.sh:L37`, `L41`).
If sourcing or lookup fails (e.g., unreadable/syntax-broken `_resolve-lib.sh`),
`_default_vendor` can be empty; with a recognized override vendor, the guard at
`L54` passes and the script exits 0 at `L62`, masking the failure instead of
failing loud with `[second-reviewer-unavailable]`. Add explicit status checks
after sourcing and after default-vendor resolution (and treat empty default as
failure).
