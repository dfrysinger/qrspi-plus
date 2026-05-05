**Contract Drift**

1. `finding_id`: `R3-F01`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `R1-F02 is still not actually resolved. The rewrite says the shared reviewer protocol will be bifurcated and selected by a "Reviewer-Tag Routing Table" keyed on tags like \`claude\` / \`codex\` / \`scope-codex\` (spec lines 63-65, 94-109). That selector cannot distinguish migrated artifact reviewers from deferred reviewers, because deferred reviewers still use the same \`reviewer_tag\` values today: e.g. the five deferred plan-artifact Claude reviewers all dispatch with \`reviewer_tag: claude\`, and their Codex counterparts all dispatch with \`reviewer_tag: codex\` ([skills/plan/SKILL.md] lines 234-242, 252-309). If the shared \`reviewer-protocol\` routes by tag, those deferred reviewers will be told to use the new per-finding contract even though §2 says they remain legacy. Fix by routing on reviewer family / agent type / output path pattern, not the reused \`reviewer_tag\` field.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","skills/plan/SKILL.md","skills/reviewer-protocol/SKILL.md"]`

2. `finding_id`: `R3-F02`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `The new per-expected-reviewer schema guard would hard-fail valid runs because the expected tag set is specified incorrectly. §2 step 2 says the expected set is \`claude, scope-claude, codex, scope-codex\` "for every #109-scope artifact step" (spec lines 115-117, echoed in the data-flow at lines 215-226). That is false in the current pipeline: Questions has no scope reviewer ([skills/questions/SKILL.md] lines 77-100), Research has no scope reviewer ([skills/research/SKILL.md] lines 97-122), and Codex reviewers are optional via \`config.md.codex_reviews\` ([skills/using-qrspi/SKILL.md] lines 349-350, 370, 410-418). Implemented as written, a clean Questions or Research round, or any codex-disabled run, trips the "reviewer X did not emit any output" failure even though nothing is wrong. The spec needs a per-step, config-aware expected-reviewer matrix instead of one fixed 4-tag set.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","skills/questions/SKILL.md","skills/research/SKILL.md","skills/using-qrspi/SKILL.md"]`

**State / Compatibility**

3. `finding_id`: `R3-F03`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `The \`verifier_enabled\` migration contradicts QRSPI's existing config-validation contract. The spec says a missing \`verifier_enabled\` field silently defaults to \`true\` for backward compatibility (spec lines 140-146). But the authoritative config contract explicitly says there are "No silent defaults" for fields that affect pipeline behavior, and skills must stop instead of guessing missing values ([skills/using-qrspi/SKILL.md] lines 383-420). Since \`verifier_enabled\` changes apply-fix behavior, implementers have two incompatible instructions: either abort on missing field per the current config rules, or silently proceed per the new verifier section. Resolve this by explicitly carving \`verifier_enabled\` out of the no-silent-default rule, or by adding a migration step that backfills the field before any verifier-aware apply-fix runs.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","skills/using-qrspi/SKILL.md"]`

4. `finding_id`: `R3-F04`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `The "/code-review-style backward compatibility" claim for \`round-NN-codex.md\` is not true as written. The spec says the raw Codex stdout dump is retained "as audit-trail compatibility surface for pre-#109 inspectors" (spec lines 152-177). Today that file is part of the normal per-reviewer contract: \`using-qrspi\` documents \`round-NN-codex.md\` as the reviewer file main chat and auditors expect, in the same review-file shape as other reviewers ([skills/using-qrspi/SKILL.md] lines 470-516). Post-#109, that same path becomes a delimiter stream / \`NO_FINDINGS\` sentinel transport for the splitter, not the old review-file format. Keeping the filename while changing the file's semantics does not preserve compatibility for existing inspectors or tooling that read \`round-NN-codex.md\` directly. Either drop the compatibility claim, or keep emitting a compatibility-shaped assembled Codex review artifact alongside the raw splitter input.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","skills/using-qrspi/SKILL.md"]`

5. `finding_id`: `R3-F05`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `R1-F09 is not actually resolved; the rewrite gives two incompatible outcomes for the same missing-verifier-block case. §2 step 7 says the dispatcher keeps findings when \`verifier_enabled=false\` OR when no \`## Verifier\` block is present (spec line 123), and the per-file-format section repeats that absence of the block means "keep this finding without scoring," including silent verifier failure cases (lines 313-314). But the preserve guard says a missing sentinel on any file that was supposed to be verified is a hard abort (lines 121-122, 341-346). In a verifier-enabled round where Haiku silently fails to append anything, the design both says "keep it" and "abort the protocol." Those are materially different state-machine branches. Pick one behavior and make every section agree; otherwise implementers cannot write the dispatcher correctly.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`