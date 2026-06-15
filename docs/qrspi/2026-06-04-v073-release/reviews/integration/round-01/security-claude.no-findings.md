---
reviewer: security-claude
phase: integrate
round: 01
findings: 0
---

# Cross-task security integration review — no findings

No blocker/high/medium cross-task security vulnerabilities identified in the
merged code for v0.7.3 Phase 1 (45 tasks, base `af6f6e3` → stage-W7 tip
`feec574`).

## Surfaces traced end-to-end

1. **Dispatch chain — auth boundary integrity.**
   `scripts/dispatch-agent.sh` (batch + single) → `scripts/dispatch-companion.sh`
   (`launch` / `await` / legacy `--provider`) → `scripts/await-round.sh`
   (manifest exec) → `scripts/third-party-finding-splitter.sh` →
   `scripts/verifier-fan-in.sh` → fix-task fan-out. The trust hand-off uses
   compositional defenses that fail closed at every boundary:

   - `await_cmd` / `split_cmd` strings written by `dispatch-agent.sh` are
     reconstructed under validated `$OUTPUT_DIR`
     (`_validate_output_dir`, allowlist `^/[A-Za-z0-9_./:@-]+$`,
     `dispatch-agent.sh:237-245`), validated `$REVIEWER_TAG`
     (`^[a-z][a-z0-9_-]*$`, `dispatch-agent.sh:1062-1065` /
     `:880-883`), and validated `$_job_id` (`_validate_job_id`,
     `dispatch-agent.sh:253-260`). `await-round.sh:225-273` re-parses each
     command via `shlex.split` (`shell=False`), rejects bare-name argv[0]
     outside `{"codex"}`, rejects `-`-prefix argv[0], rejects `./` / `../`
     argv[0], and realpath-confines path-shaped argv[0] under
     `EXEC_ROOTS` derived from `git rev-parse --show-toplevel` of the
     round-dir. The manifest-exec model defends against shell-RCE,
     parent-traversal, and `./codex` masquerade simultaneously.

   - `dispatch-companion.sh launch` (`:606-732`) validates `--tag`
     (allowlist), control-char-rejects all 5 raw value bytes
     (`vendor`, `model`, `prompt-file`, `round-dir`, `tag`), pre-mkdir
     boundary-checks `--round-dir` via `assert_ancestor_under_repo_root`,
     post-mkdir boundary-checks via `assert_path_under_repo_root`,
     canonicalizes for the stored job record, AND re-checks the
     canonical form for newlines (defending against on-disk
     directory-name injection via symlink). `dispatch-companion.sh await`
     (`:512-598`) re-validates `tag` against the same allowlist and
     re-asserts `round_dir` under `$REPO_ROOT` — the two sides cannot
     drift across the disk-state hand-off.

2. **Prompt-injection markers across merged surfaces.**
   `FORBIDDEN_MARKERS` (`dispatch-agent.sh:564-570`) covers the closing
   AND opening tokens of all three structural wrapper pairs
   (`AGENT-BODY-END`, `UNTRUSTED-SCOPE-HINT-{START,END}`,
   `UNTRUSTED-ARTIFACT-{START,END}`). Enforcement is symmetric across
   the merged batch and single modes:

   - **Single mode** (`dispatch-agent.sh:1305-1335`): file-content
     marker rejection on `${PRIMARY_FIELD}`, `task-def`, every
     `companion`, and `diff-file`; value-emission rejection on every
     emitted path/scalar (`scope-hint`, every `--field`).
   - **Batch mode** (`dispatch-agent.sh:805-816, 765-772`): file-content
     marker rejection on `--artifact` body; value-emission rejection on
     `--output-dir`, `--artifact`, `--diff-file`, `--absorption-map`.
     The `--diff-file` content is NOT marker-content-checked, but the
     diff file is referenced by path only (`diff_file_path: %s\n`,
     `:984`) — never embedded into the prompt — and the reviewer reads
     it under explicit "untrusted data" framing per `reviewer-protocol`
     SKILL. No compose-time injection is possible.

   - **Marker `id` injection** is closed: the `id` substituted into
     `<<<UNTRUSTED-ARTIFACT-START id=%s>>>` is the validated path value
     (newline/marker-rejected), so a crafted id cannot truncate the
     wrapper. `\n` prefix before the END marker
     (`dispatch-agent.sh:968, :1350`) safely handles bodies without a
     trailing newline.

   - **Scope-hint wrapper** (`dispatch-agent.sh:1395-1397`) is on a
     single line; `SCOPE_HINT` is rejected via
     `reject_if_contains_marker_value` (`:1330-1332`) which rejects
     both `\n`/`\r` AND every forbidden marker substring. The
     `<<<UNTRUSTED-SCOPE-HINT-END` prefix is in `FORBIDDEN_MARKERS`, so
     a crafted hint cannot close its own wrapper.

3. **Third-party reviewer output as a future-prompt input.** Per-finding
   files materialised by `third-party-finding-splitter.sh` are read by
   later fix-task dispatches via the Read tool (data surface), not
   embedded as `--companion` bodies in any cross-task path I traced.
   Even if a future dispatch did embed them, the
   `reject_if_contains_marker_file` companion-side guard would
   fail-closed before any forged marker reached the prompt. No
   silent-injection path exists across the merge.

4. **SHA / phase-base validation across tasks.** `review-prep.sh` and
   `orchestration-boundary-check.sh` both apply the lowercase-hex
   7..64-char shape check (`SHA_REGEX`, `obc:51`; identical inline
   check in `review-prep.sh:162-171`) BEFORE any `git` invocation reads
   the value. `obc:209-226` (`author_name_is_malformed`) rejects
   newline / multi-whitespace / non-TAB/LF control bytes in author
   records before the `qrspi-` prefix check, so a crafted commit
   author cannot bypass the OBC commit-violation surface.
   `git log -z` (`obc:240, 260`) means NUL-separation, so a single
   record carrying an embedded newline doesn't split records — it's
   surfaced as a dispatch defect.

5. **Privilege-escalation / shared-state composition.**
   `GIT_AUTHOR_NAME=qrspi-<agent>` is exported (single:
   `dispatch-agent.sh:1218`; batch: `:910`) only AFTER
   `_validate_agent_name_charset` rejects out-of-charset values with
   the `agent-name-charset-invalid:` named diagnostic and exit 1.
   Manifest writes (`_append_manifest_entry`, `:328-427`) use a
   `mkdir`-mutex with 30s stale-lock probe + atomic `mv` of
   `mktemp`-allocated tmp files. The 3-trap (EXIT/INT/TERM) cleanup
   pattern (`:356-358`, `:296-300`) prevents stale lock or tmpfile
   orphans under signal pressure. Concurrent reviewer-tag dispatches
   in the same wave cannot interleave reads/writes against the
   manifest.

6. **Network egress guards under composition.** `dispatch-companion.sh`
   `_is_rejected_host` / `_is_loopback_only` (`:158-218`) block
   loopback, link-local (incl. cloud-metadata 169.254.169.254), RFC1918,
   CGNAT, IPv6 link-local / unique-local; `https://` URL scheme is
   required (`:836-839`); `_control_char_check` (`:239-265`) is
   POSIX-clean (catches LF, which the prior `grep -qP 2>/dev/null` was
   noted to have silently missed); NUL-byte pre-flight on the whole
   `config.md` file (`:865-877`) fails closed on non-numeric byte
   counts. None of these guards are bypassable by combining tasks —
   they all gate the legacy `--provider` path before any curl.

## Cross-cutting helpers added this phase (also clean)

- `scripts/lib/path-guard.sh` — `assert_path_under_repo_root` and
  `assert_ancestor_under_repo_root` (the pre-mkdir variant) are sourced
  symmetrically by both dispatch scripts; the canonical-form trailing-
  slash-anchored prefix match defeats the `/repo-evil/foo` masquerade.
- `scripts/upstream-paths.sh` (T01), `scripts/design-absorption-markers.sh`
  (T02), `scripts/validate-stage-commit-parents.sh` (T19c) — all read-
  only, no cross-task state mutation, no privilege grants.

## Per-task acknowledgements

Per-task security review findings (Implement phase) addressed each
task's own attack surface and were closed before integration; this
review explicitly traced the boundaries WHERE those tasks meet
(dispatch-agent ↔ dispatch-companion, dispatch-companion ↔
await-round, await-round ↔ splitter, review-prep ↔ dispatch-agent,
OBC ↔ phase-base writers). No combination created a path that the
per-task defenses fail to cover.

## Confidence note

`scope_hint` was not supplied in this dispatch (round-01 broaden), so
this review covered the full diff against `<base-branch>` with no
surface bias. The diff (707K lines across 45 tasks) was traced via
the merged on-disk files (`scripts/dispatch-agent.sh`,
`scripts/dispatch-companion.sh`, `scripts/await-round.sh`,
`scripts/third-party-finding-splitter.sh`, `scripts/review-prep.sh`,
`scripts/orchestration-boundary-check.sh`, `scripts/lib/path-guard.sh`)
rather than line-by-line through the diff body itself — the integrated
artifacts on disk ARE the merged result, and the per-task review
findings already established the per-task baseline.
