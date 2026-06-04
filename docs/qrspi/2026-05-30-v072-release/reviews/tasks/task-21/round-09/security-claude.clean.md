# Security Review — Task 21, Round 9 — security-claude — CLEAN

## Scope

Reviewed `round-09.diff` against `scripts/dispatch-agent.sh`,
`scripts/dispatch-companion.sh`, `scripts/lib/path-guard.sh`,
`agents/qrspi-implementer.md`, and `tests/unit/test-dispatch-agent.bats`.

Round-8 closed the broken-symlink partial-state regression
(sf-claude R8 F01); the cycle-9 patch (2202d83) is the convergence fix
plus comment-only cleanups. The orchestrator-supplied deferral list
(QRSPI_REPO_ROOT env override, TOCTOU symlink swap, mktemp+mv
non-atomic job record) is honored — not re-flagged here.

## Surfaces examined

1. **Broken-symlink ancestor walk** (path-guard.sh:558,
   `assert_ancestor_under_repo_root`). The `! -e "$probe" && ! -L
   "$probe"` predicate now terminates the upward walk on any
   symlink — broken or live — so the canonical boundary check fires
   on the symlink itself before `mkdir -p` follows it. The matching
   bats regression (`in-repo broken symlink with out-of-repo target
   rejected without creating filesystem state`) asserts no
   filesystem trace under the out-of-repo target. Closed.

2. **`await`-mode job-record re-validation** (dispatch-companion.sh:
   549-561). Both `_job_tag` (shell-glob allowlist
   `*[!a-z0-9_-]*|[^a-z]*`, semantically equivalent to the launch
   regex `^[a-z][a-z0-9_-]*$` on bash 3.2+ where `^` negates inside
   bracket classes) and `_job_round_dir` (full canonical boundary
   check) are re-checked before `_raw_dir`/`_raw_file` are
   constructed from them. Empty `_job_tag` is rejected by the prior
   `-z` guard. A crafted job record cannot redirect raw-output writes
   outside the canonical repo tree.

3. **Batch `--agents` tag allowlist** (dispatch-agent.sh:134). The
   per-pair tag now passes the same `^[a-z][a-z0-9_-]*$` regex as
   single-mode `--reviewer-tag`, blocking traversal tags like
   `../../etc/cron` from redirecting the `<output-dir>/.dispatch/
   <tag>.prompt` write target. Pinned by the new `batch --agents tag
   with path traversal rejected by tag allowlist` regression.

4. **Expanded `FORBIDDEN_MARKERS`** (dispatch-agent.sh:1023-1029)
   covers `<<<AGENT-BODY-END>>>`, `<<<UNTRUSTED-SCOPE-HINT-{START,
   END}`, and `<<<UNTRUSTED-ARTIFACT-{START,END}` for both file-body
   and scalar-value inputs. Three new marker-injection regressions
   pin the SCOPE-HINT-END, UNTRUSTED-ARTIFACT-START, and
   `--field`-value vectors. Closes the previously-flagged
   scope-hint / scalar-field marker carve-out gap.

5. **`OUTPUT_DIR` interpolation into the Dispatch parameters
   block** (`round_subdir: %s\n`). `_validate_output_dir`'s
   allowlist `^/[A-Za-z0-9_./:@-]+$` excludes `<>`, so wrapper
   markers cannot be smuggled via `--output-dir`.
   `--reviewer-tag` and `--model` carry their own grammars; the
   `ROUND`/`DIFF_FILE` interpolations are the canonical path or a
   numeric round and do not introduce a marker-injection risk under
   the threat model (attacker without filesystem-write inside the
   repo).

6. **`launch` two-stage round-dir guard**
   (dispatch-companion.sh:625-636). Pre-mkdir
   `assert_ancestor_under_repo_root` blocks materialising
   directories outside the repo on rejected inputs; post-mkdir
   `assert_path_under_repo_root` plus `_qrspi_canonicalize` of
   `L_ROUND_DIR` catch symlink-resolution attacks where the leaf
   canonicalises out-of-repo. Stored `round_dir` in the persisted
   job record is the canonical absolute path, eliminating cwd-drift
   between launch and await. Pinned by `out-of-repo --round-dir
   rejected without creating filesystem state` and the symlink
   regression.

7. **Fail-closed `path-guard.sh` source guard** (dispatch-agent.sh:
   74-75; dispatch-companion.sh:372-375). If sourcing succeeds but
   the guard function is absent (corrupt/empty lib), the script
   exits non-zero with a clear diagnostic before any prompt-ingested
   path is read. Pinned by the corrupt-lib bats regression.

8. **`--prompt-file` raw-path surface in `launch`**
   (dispatch-companion.sh:629). Boundary-checked via
   `assert_path_under_repo_root` before being recorded or passed to
   the upstream transport. The raw value (not canonical) is what is
   later passed to `codex-companion-bg.sh`; since boundary check
   resolved canonically inside the repo, following the symlink at
   transport time still terminates inside the repo. (TOCTOU
   symlink-swap is on the deferral list.)

9. **Implementer allowlist** (agents/qrspi-implementer.md). The new
   `## Orchestrator-Only Scripts (Bash Allowlist)` section forbids
   `scripts/dispatch-{agent,companion}.sh` invocation under
   relative, absolute, alias, and shell-expansion shapes. This is a
   defense-in-depth advisory layer — the runtime guards above are
   load-bearing. Acceptable.

## Verdict

No new security findings. The R8 broken-symlink boundary leak is
closed without regressing any previously-cleared marker-injection,
tag-allowlist, await-record-revalidation, fail-closed-source, or
boundary surface. All re-flag candidates fall inside the dispatch
deferral list.
