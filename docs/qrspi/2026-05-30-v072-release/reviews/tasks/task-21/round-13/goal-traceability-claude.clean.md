# Goal Traceability — Task 21 — Round 13 — CLEAN

Reviewer: goal-traceability-claude
Phase: Implement (deep-mode thoroughness fan-out, first run for T21)
Verdict: CLEAN — no traceability gaps, no orphan code attributable to T21.

## Trace verified end to end

**Goal anchor.** `tasks/task-21.md` frontmatter declares `goal_ids: [G16]`,
mapping the task to the G16 goal in `goals.md` (sanctioned-channel exfil
through arbitrary wrapper path inputs).

**Forward trace (goal → criterion → test → impl).** Each Definition-of-done
and Test-expectations bullet in `tasks/task-21.md` is covered by at least
one bats test that exercises a concrete production-code site:

1. *DoD: rejects canonicalized paths outside `$REPO_ROOT/` with `resolves
   outside repository`* →
   tests `--subject-code outside repo root rejected …` (bats L1566),
   `--subject-code /etc/hosts rejected` (L1579),
   `--artifact-body outside repo root rejected` (L1590),
   `batch --artifact /etc/hosts rejected` (L1773),
   `batch --agents /etc/hosts rejected` (L1808) →
   impl: `scripts/lib/path-guard.sh::assert_path_under_repo_root`
   (L111–150) called from `scripts/dispatch-agent.sh` for PRIMARY
   (L1059), task-def (L1067), companion (L1076), diff-file (L1086),
   agent-file (L1009), skill paths (L1051), BATCH_ARTIFACT (L664),
   `_agent_file` (L732).

2. *DoD: symlink-to-outside rejected before prompt files emitted* →
   tests `symlink under repo whose canonical target is outside repo …`
   (L1636) and `batch --artifact symlink-to-outside rejected` (L1789) /
   `batch --agents symlink-to-outside rejected` (L1822). The first asserts
   `<<<AGENT-BODY-END>>>` and `<<<UNTRUSTED-ARTIFACT-START` markers are
   absent in the output, pinning the before-emission contract → impl: the
   guard runs before `compose_prompt`/`emit_untrusted_artifact` and before
   the batched `cat "$BATCH_ARTIFACT_ABS"` in dispatch-agent.sh L790.

3. *DoD: readable out-of-repo `--companion` fails by boundary check, not
   missing-file* → test `--companion outside repo root rejected (boundary,
   not missing-file)` (L1603) explicitly asserts `[ -r ... ]` on the OOR
   file before invoking the wrapper, then asserts the boundary diagnostic.

4. *DoD: all four flag families (subject-code, artifact-body, companion,
   diff-file) share the same enforcement point, valid repo-local inputs
   pass dry-run* → tests `--diff-file outside repo root rejected` (L1620),
   `repo-local --subject-code dry-run preserves spec-line / prompt-file
   contract` (L1686), `repo-local --artifact-body / --companion /
   --diff-file dry-run all pass` (L1700) → impl: PRIMARY array merges
   subject-code and artifact-body into a single guarded loop (L1055–1061),
   companion (L1070–1078), diff-file (L1080–1087).

5. *DoD: canonicalization failure fails closed; no raw path read first* →
   test `unresolvable $REPO_ROOT fails closed before any path is read`
   (L1660) writes a sentinel into the subject file and asserts it is NOT
   echoed in the dry-run output, pinning the no-cat-before-guard contract
   → impl: `_qrspi_canonicalize` returns 1 on empty stdout
   (path-guard.sh L67–69) and `assert_path_under_repo_root` exits 1 with
   `cannot canonicalize $REPO_ROOT` before any caller-side read.

6. *DoD: implementer.md allowlist covers all four shapes* → test
   `agents/qrspi-implementer.md carries the Orchestrator-Only Scripts
   allowlist` (L1722) greps for the heading, both post-rename script
   names, and the four shape keywords → impl:
   `agents/qrspi-implementer.md` L9–43 carries the section with explicit
   relative, absolute, alias, and shell-expansion bullets.

7. *DoD: dispatch-companion audit* → test `dispatch-companion.sh either
   shares the guard or documents no-raw-path surface` (L1735) →
   impl: `scripts/dispatch-companion.sh` L45–58 carries the documented
   no-raw-path comment for the legacy stdin-only surface AND sources
   the shared guard for the launch subcommand's `--prompt-file` raw-path
   entry point. Both sides of the audit decision are satisfied.

## Backward trace (impl → tests → spec → goal)

Every behavior added in `path-guard.sh` (canonicalize, ancestor walk,
trailing-slash anchored prefix match, fail-closed canonicalization) and
every guard call site in `dispatch-agent.sh` (agent-file, skills,
PRIMARY, task-def, companion, diff-file, BATCH_ARTIFACT, `_agent_file`)
maps back to a Test-expectations bullet in `tasks/task-21.md` and from
there to G16. The trailing-slash anchor (`case "$canon/" in
"$canon_root"/*) ...`) is defensive code documented in the file header
and exercised implicitly by the `/etc/hosts` and OOR-tmp tests; while
no test pins a `/repo-evil/`-prefix-vs-`/repo/` separator regression
specifically, the design.md G16 strict-canonicalization clause covers
this defense and the existing tests would catch a regression that
removed the trailing slash for the common cases. **Not a finding** —
trailing-slash is a defense-in-depth tactic, not a goal-level
requirement.

The `assert_ancestor_under_repo_root` helper in path-guard.sh L85–109
is used by other dispatch-time mkdir sites (not directly by T21) and
its presence in the shared library is justified by the cross-script
contract noted in the file header. **Not a T21 orphan.**

## Gap analysis

No required Test-expectations bullet from `tasks/task-21.md` is missing
a corresponding bats test. No production-code branch in the path-guard
library or its T21 call sites lacks goal traceability.

## Scope-spillover note (advisory, not a finding)

The R13 cumulative diff (b17538e..40fe6de, 133 files) includes large
swaths of content unrelated to G16 (reviewer-agent `tier:` frontmatter,
`DISPATCH_FILE=<path>` prologue prose, await-round.sh, splitter,
config.md migrations, etc.). Per the R13 dispatch context and
`task-21.md` Out-of-scope list, these belong to predecessor tasks
(T20 dispatch rename, earlier broker/await/splitter work) that landed
on the same branch — they are not T21 orphan code. T21's own surface
is exactly: `scripts/dispatch-agent.sh`, `scripts/lib/path-guard.sh`,
`scripts/dispatch-companion.sh` audit comment, `agents/qrspi-implementer.md`
allowlist insertion, and `tests/unit/test-dispatch-agent.bats` G16
section (L1525–1898) plus the batch-mode mirror cases. All five
surfaces trace cleanly to G16.

NO_FINDINGS
