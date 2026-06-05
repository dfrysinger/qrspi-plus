# Spec review — Task 21 round 9 — clean

R9 fix-cycle (commit 2202d83) faithfully closes the R8 findings without scope
expansion or spec drift:

- **sf-claude R8 F01 (broken-symlink boundary)**: `scripts/lib/path-guard.sh`
  line 558 changes the ancestor walk loop condition to
  `while [ ! -e "$probe" ] && [ ! -L "$probe" ]`, terminating on symlinks so a
  broken in-repo symlink whose target is out-of-repo is submitted to the
  canonical boundary check before `mkdir -p` can follow it. New regression
  test `companion launch: in-repo broken symlink with out-of-repo target
  rejected without creating filesystem state` (test-dispatch-agent.bats lines
  1226-1256) asserts both rejection AND `[ ! -e "$oor_root/notyet" ]` —
  proving no partial filesystem state is materialised through the link.
- **cq-claude R8 F01 / cq-codex R8 F02 (dead MARKER_LITERAL + tombstone)**:
  the legacy single-marker `MARKER_LITERAL=...` declaration is gone; the
  marker-injection guard now iterates `FORBIDDEN_MARKERS` (dispatch-agent.sh
  lines 284-322) with no orphaned scalar.
- **cq-codex R8 F01 (R7 F02 token in test comment)**: stripped — the only
  remaining `R5 F04`/`T09 R2`/`R7` references are gone or rewritten as
  topic-only descriptors.

DoD-by-DoD check against tasks/task-21.md lines 39-46:

1. Out-of-repo paths rejected with `resolves outside repository` —
   path-guard.sh lines 605-609 ✓ ; tests 782-848.
2. Symlink-canonical-out rejection before any prompt emission —
   tests 852-872 (asserts `<<<AGENT-BODY-END>>>` and
   `<<<UNTRUSTED-ARTIFACT-START` are absent on rejection).
3. Readable out-of-repo `--companion` fails by boundary, not missing-file —
   test 819-834 explicitly probes `[ -r ... ]` first.
4. All four path families pass through the same guard — single-mode at
   dispatch-agent.sh lines 212/237/245/253/263; batch-mode at 122/147;
   valid repo-local dry-runs at tests 902-930.
5. Canonicalization fails closed; no raw cat before guard — test 876-898
   asserts a unique sentinel inside the subject file is absent from output.
6. Implementer allowlist section — agents/qrspi-implementer.md lines 9-45
   carries the `## Orchestrator-Only Scripts (Bash Allowlist)` heading at
   top-of-body, names both post-rename scripts, and explicitly covers
   relative, absolute, alias, and shell-expansion shapes.
7. dispatch-companion.sh audit — lines 351-375 either invoke the guard
   (launch `--prompt-file`, launch/`await` `--round-dir`) or document the
   stdin-only legacy `--provider/--artifact-dir` surface as no-raw-path.

Test expectations on task-21.md lines 49-56 all map to bats cases (88/88
green per dispatch). No code, files, or features outside the Target files
list ; the new `scripts/lib/path-guard.sh` is a necessary auxiliary shared
library called out as legitimate scaffolding under the advisory check.

R8 deferrals (spec-codex marker-injection scope amendment + the carried-
forward R7 set: `QRSPI_REPO_ROOT` env override, TOCTOU symlink swap,
mktemp+mv non-atomic, `_resolve-lib.sh || true`, batch `_path` no-WARN,
reviewer-protocol/emission-override asymmetry, per-agent launch-failure
batch exit-0, split-bats refactor, scope/path-guard target-files
amendments) are explicitly not re-flagged.

No findings.
