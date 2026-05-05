**Protocol / Contract**
1. `finding_id`: `R2-F01`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `R1-F01 is still not actually resolved. The rewrite says the shared reviewer protocol’s \`## Disk-Write Contract\` is globally “REPLACED” (spec lines 61-63), but #109 explicitly leaves 16 reviewers on the legacy single-file shape (lines 160, 356-359). Those deferred reviewers still preload the same shared \`skills/reviewer-protocol/SKILL.md\` today, including implement/integrate/gate reviewers and the 5 plan-artifact reviewers, so replacing the contract without a fully-specified dual mode gives unchanged reviewers contradictory instructions as soon as step 4 lands. The spec hand-waves a “legacy single-file emission … addendum” (lines 160, 378-379) but never defines its text or the selector that tells a reviewer which branch applies. Fix this by specifying an explicit bifurcated contract in \`reviewer-protocol\` keyed to reviewer family, or by deferring the shared-skill replacement until every reviewer that preloads it migrates.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","skills/reviewer-protocol/SKILL.md","agents/qrspi-plan-spec-reviewer.md","agents/qrspi-implement-gate-reviewer.md","agents/qrspi-integration-reviewer.md"]`

2. `finding_id`: `R2-F02`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `The missing-delimiter Codex fallback creates non-unique finding IDs. On malformed stdout, the splitter synthesizes \`finding_id: R{NN}-F00\` (spec line 139). If both artifact-Codex and scope-Codex hit this path in the same round, or if a future multi-template site reuses it, multiple findings in one round will share the same ID. That violates the current reviewer-protocol contract, which uses \`finding_id\` as the stable identifier “within the current review round” for pause-gate threading (reviewer-protocol lines 21-27). The fallback needs a uniqueness rule, e.g. include reviewer tag/template in the synthetic ID or define per-reviewer uniqueness instead of round-wide uniqueness.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","skills/reviewer-protocol/SKILL.md"]`

**State Machine / Dispatch**
3. `finding_id`: `R2-F03`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `Crash-file handling is internally inconsistent. Apply-fix step 1 only lists \`*.finding-*.md\` and \`*.clean.md\` (spec lines 96-100), but later sections rely on \`*.crash.md\` being discovered, assembled, and routed to the pause gate (lines 141, 192-195, 218-239, 285-291). In a reviewer-crash round, the step-1 command can see “no findings and no clean markers” and trigger the schema-violation path instead of the intended reviewer-failure pause path. Fix the discovery step so crash files are part of the primary enumeration from the start, and define clear precedence between “crashed reviewer” and “missing output” cases.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

4. `finding_id`: `R2-F04`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `R1-F08 is still not fully resolved: the preserve-guard / disabled-mode sequence is contradictory. The numbered Apply-fix protocol has no explicit checksum-snapshot step at all, and says \`verifier_enabled=false\` skips steps 3-4 (lines 97-100). But the data-flow diagram adds a pre-dispatch snapshot as step 4 before reading \`verifier_enabled\` (lines 184-190), then compares against that snapshot at assembly time (lines 225-228), while §4 says the guard runs only in verifier-enabled rounds (line 293). Those three statements cannot all be true, so an implementer cannot tell whether disabled rounds should snapshot anything or where the snapshot is taken. Make the snapshot a real numbered step after the verifier-enabled gate and before verifier dispatch, and keep the disabled path entirely outside the guard.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

**Migration**
5. `finding_id`: `R2-F05`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `The revised migration plan reintroduces a shippability hazard. Step 4 already lands the Apply-fix protocol revision and the failure-menu-related tests (spec lines 377-382), and the protocol text already says option 1 mutates \`config.md\` and writes the disable audit note (lines 297-315). Step 5 then says the “mutation logic” and footer land later as a separate commit (lines 386-392). Because QRSPI’s skills are the runtime behavior contract, splitting those commits leaves main in a contradictory state: either step 4 already made the behavior live, or step 4 documents behavior that does not exist yet. This is the same class of “independently shippable” problem raised in R1-F02, just moved later in the sequence. Fold step 5 into step 4, or remove the option-1 mutation semantics from step 4 until the same commit that introduces them.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`