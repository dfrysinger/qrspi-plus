---
finding_id: R5-F07
severity: low
change_type: clarity
referenced_files: [scripts/_resolve-lib.sh]
---
Header comment overclaims scope re trusted_path. The `_resolve-lib.sh` header calls the library the "Single source of truth for the resolution algorithm" while the documented architecture (implement/SKILL.md:537, using-qrspi ~508) places the `trusted_path:` short-circuit at the MAIN-CHAT dispatch site, BEFORE and OUTSIDE the tier chain — the resolver intentionally does not implement it. The overclaim invited two security reviewers (sec-claude F02, sec-codex F1) to flag a missing trusted_path enforcement that is architecturally not this library's responsibility. Fix (comment-only): scope the header wording to "the tier-resolution algorithm (agent tier: parsing, precedence chain, tier→(vendor,model) lookup, host×vendor matrix, none-halt)" and add a one-line note that `trusted_path:` is a dispatch-site short-circuit evaluated before this library is consulted. (Deep enforcement deferred — see DECLINED-NOTES; no executable dispatcher sources this lib yet.)
