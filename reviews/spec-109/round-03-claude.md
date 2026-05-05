# Round 3 review — spec-109 (claude)

Scope: NEW issues from the round-2 rewrite (commit `1c25da8`), or round-2 issues
not actually resolved. Pedantic nitpicks skipped.

---

1. finding_id: R3-F01
   severity: high
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: Boundary-sentinel preserve-guard contract has an asymmetric
   newline-handling rule that can cause spurious aborts. §2 step 6 (lines 50–58)
   says the verifier composes "original content (preserved byte-identically) +
   a single newline + the boundary sentinel ... + the `## Verifier` block."
   §4 (line 344) says `check` "splits at the first occurrence of the unique
   sentinel ... takes everything before the sentinel (excluding the trailing
   newline), sha256s it, and compares." Apply-fix step 4 (line 118) snapshots
   "the entire file content" via sha256. The two checksums match ONLY if every
   pre-dispatch finding file ends with exactly one trailing newline. A reviewer
   who Writes a file with NO trailing newline (or two) produces a snapshot that
   `check` cannot reproduce — the verifier's mandatory "+ a single newline +"
   normalizes to a one-newline form before the sentinel, so `check`'s "everything
   before the sentinel (excluding the trailing newline)" recovers a one-newline-
   stripped prefix that does not equal the snapshot bytes when the original had
   zero or two trailing newlines. Define the contract: either (a) reviewer-
   protocol mandates exactly one trailing newline on per-finding files (and a
   schema-violation guard rejects others), or (b) `snapshot` normalizes by
   stripping trailing whitespace before hashing AND `check` does the same on
   the recovered prefix. Without this the preserve guard is a flake source.

2. finding_id: R3-F02
   severity: high
   change_type: clarity
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: The expected-tag-set declaration mechanism is undefined.
   §2 (line 116) and §4 (line 333) say "the dispatching skill (e.g.
   `skills/goals/SKILL.md`) declares the expected reviewer-tag set for the
   step." Today's dispatching skills have no machine-readable expected-tag
   declaration. The Apply-fix step-2 guard cannot be implemented without one
   of: (a) a YAML/fenced block added to each of the 9 dispatching skills with
   a known parser, (b) a hardcoded mapping table in `using-qrspi/SKILL.md` or
   `reviewer-protocol/SKILL.md`, or (c) a convention-based grep over each
   dispatching skill's reviewer-launch list. The spec must pick one and say
   where it lives, or the cutover commit can't be implemented unambiguously.
   Recommend (b): a single mapping table in `reviewer-protocol/SKILL.md`
   adjacent to the Reviewer-Tag Routing Table, with one row per artifact step
   listing the four expected tags. Update §2 line 116 / §4 line 333 / §9 step 4
   accordingly.

3. finding_id: R3-F03
   severity: high
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: Routing-Table extensibility has no default route or fail-loud rule.
   §2 (lines 94–107) lists the routing for the 4 #109 tags and the 16 deferred
   tags by name. There is no rule for what happens when a future PR adds a
   reviewer with a tag not present in either list. Today the routing table is
   static; tomorrow someone adds `qrspi-altitude-reviewer.md` with tag
   `claude-altitude` and the skill's behavior is silently undefined — the
   reviewer either follows neither contract (if the agent file's preload
   reads no matching route), follows whichever contract the reviewer's
   author silently assumed, or trips a runtime guard that doesn't exist.
   Add an explicit "unrouted tag → loud failure with message 'reviewer-tag
   <X> is not listed in the Reviewer-Tag Routing Table; add it to the
   appropriate contract before dispatch.'" rule to §2 (around line 107).
   The Apply-fix step-2 guard is the natural enforcement point — extend its
   per-expected-tag check to also fail loud on any tag emitted by the
   dispatch step that is unrouted.

4. finding_id: R3-F04
   severity: high
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: Discrete rubric snap-to-nearest tie-break is undefined.
   §2 step 8 (line 58) says "If the agent's reasoning would land off-bucket,
   snap to the NEAREST bucket (e.g. 80 → 75; 60 → 50; 90 → 100)." Buckets
   are 0/25/50/75/100 (gap = 25, half-bucket = 12.5). Examples 80, 60, 90
   are unambiguous. But Haiku can plausibly emit values exactly on the
   half-bucket — 12.5, 37.5, 62.5, 87.5 — or close enough that floating
   parsing rounds there. 87 → which bucket? With nearest-rounds-up it's 100;
   with nearest-rounds-down it's 75; that's a 25-point swing crossing the
   ≥80 threshold. The threshold IS load-bearing for auto-apply. Define the
   tie-break: "ties round DOWN to the lower bucket" (conservative — favors
   pause/keep over auto-apply) or "round UP". Recommend round-down: a
   borderline finding should reach the user, not silently auto-apply. Cite
   in agent-file body so the parser can rely on it.

5. finding_id: R3-F05
   severity: high
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: Crash-precedence corner case leaves polluted audit rows.
   §2 step 2 (line 116) and §4 (line 333) say: tag with both crash file
   AND finding files → route to pause via crash path; do NOT verifier-
   dispatch the finding files. But §2 step 7 (line 123) Bash assembly
   does `cat reviews/{step}/round-NN/*.finding-*.md *.clean.md *.crash.md
   > round-NN-verified.md` — this globs ALL finding files including those
   from the crashed tag. They land in `round-NN-verified.md` with no
   `## Verifier` block. The dispatcher (step 9) sees them as "no Verifier
   block → keep" and routes them to the apply path or the pause gate per
   their `change_type`. That's not the documented behavior; the documented
   behavior is that the crashed tag goes to pause via the reviewer-failure
   path AS A WHOLE. Either:
   (a) exclude the crashed tag's finding files from the cat globbing
       (requires per-tag awareness in the assembly step, not just glob), OR
   (b) the totals header explicitly tags those rows "skipped due to crash"
       and the dispatcher's filter ignores them, OR
   (c) before assembly, move the crashed tag's finding files to a sibling
       `round-NN/.crash-skipped/` subdir so the glob doesn't pick them up.
   Spec must pick one. Recommend (c) — keeps the audit trail intact, keeps
   `round-NN-verified.md` clean, and makes the "as a whole" routing
   trivially correct. Update §2 step 7 and §4 accordingly.

6. finding_id: R3-F06
   severity: high
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: Partial-verify state on option-1 fall-through has undefined
   preserve-guard semantics. §3 (lines 250–252) and §2 step 6 (line 121)
   say option 1 → "set verifier_enabled=false and fall through to step 7."
   §2 step 7 will then assemble per-finding files into `round-NN-verified.md`.
   But by the time the user picks option 1, SOME verifiers have already
   succeeded — those finding files have `## Verifier` blocks and the
   sentinel; OTHER verifiers VERIFY_FAILED and their finding files are
   pre-verify shape. The preserve guard at step 6 is the enforcement point
   that catches a verifier that wrote garbage; option-1 fall-through skips
   step 6 ("Verifier-disabled rounds skip this guard entirely" per line 122),
   but the run was NOT verifier-disabled — the un-failed verifiers DID run
   and DID Write. Skipping the guard means a corrupted prefix from a
   succeeded verifier silently makes it into `round-NN-verified.md`.
   Define: on option-1 mid-protocol, run the preserve guard against the
   un-failed verifiers' files (those have snapshots and sentinels) BEFORE
   falling through to step 7; failed-verifier files have no sentinel so are
   skipped from the guard naturally. Update §2 step 6 line 121 / §3 line 251
   / §4.

7. finding_id: R3-F07
   severity: medium
   change_type: clarity
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: `verifier-preserve-guard.sh` exit-code semantics are defined for
   the script (§4 line 344: 0 / 1 / 2) but the orchestrator's behavior on
   exit 1 vs exit 2 is not specified. §2 step 6 line 122 lumps both as
   "Mismatch (or missing sentinel on a file the verifier was supposed to
   score) aborts the protocol with a hard failure surfacing the offending
   file path." Both abort, but the surfaced messages should differ:
   exit 1 = "verifier corrupted prefix on <path>"; exit 2 = "verifier did
   not write the boundary sentinel on <path>". The two failures diagnose
   different verifier bugs and the user/operator needs the distinction to
   triage. Define the message templates in §4 alongside the exit codes,
   or have the helper script print the message itself and have the protocol
   surface its stderr verbatim. Recommend the latter (simpler).

8. finding_id: R3-F08
   severity: medium
   change_type: clarity
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: Routing-Table location inside `skills/reviewer-protocol/SKILL.md`
   is ambiguous. §2 (line 63, 94) says the table goes "at the top" of the
   skill body. Today the skill has frontmatter + intro + sections. "At the
   top" could mean: (a) immediately after frontmatter and before the intro,
   (b) the first H2 inside the intro, (c) before the `## Disk-Write Contract`
   section. Implementer needs to pick one. Recommend (a) — put it
   immediately after frontmatter as a `## Reviewer-Tag Routing Table`
   second-level heading with a single sentence intro, before any other
   content. State this explicitly in §2 around line 94.

9. finding_id: R3-F09
   severity: medium
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: Re-dispatch (option 2) recursion is unbounded and has no
   defined surfacing. §3 (lines 252–259) says option 2 re-dispatches ONLY
   the failed verifiers. If one of those re-dispatched verifiers ALSO
   fails, the menu (§5) re-fires. With Haiku rate-limited or down, the user
   could pick option 2 indefinitely. Spec doesn't say:
   (a) is there a retry cap (e.g. 3 consecutive option-2 picks → option-2
       greyed out / removed from menu)? §8 line 418 EXPLICITLY rejects the
       3-retry counter as out of scope, replacing it with the always-on
       footer — but the always-on footer doesn't actually prevent infinite
       option-2 picks, it just hints at option 1.
   (b) does each re-dispatch reuse the snapshot from step 4, or take a
       fresh snapshot? Reusing the snapshot is correct (the un-failed
       verifiers' files are unchanged so their snapshots are still valid;
       the failed verifiers' files are pre-verify shape so their snapshots
       are still valid). State this explicitly: "option 2 reuses step-4
       snapshots; no re-snapshot."
   (c) does the totals header on `round-NN-verified.md` reflect retry
       count, or only the final round?
   Spec must answer (b) at minimum. (a) and (c) are nice-to-have. Update §3
   and/or §5.

10. finding_id: R3-F10
    severity: medium
    change_type: clarity
    referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
    message: §7 test #2 (line 387) says the test "explicitly skips" the 16
    deferred reviewers "with a comment citing the deferred follow-up issue."
    The follow-up issue does not exist at cutover-commit time (it's filed
    in §9 step 6, AFTER step 4). The test cannot cite a URL or issue number
    that doesn't yet exist. Three options:
    (a) the comment cites a placeholder ("TODO: follow-up issue") and a
        post-step-6 commit replaces it with the real number;
    (b) the follow-up issue is filed BEFORE the cutover (move §9 step 6
        before step 4), so the issue number is known at test-write time;
    (c) the comment cites only the §8 spec section by path
        (`docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md
        §8`) which is stable.
    Recommend (b) — cleanest sequencing, no follow-up edit. State the
    pick in §7 test #2 and §9 step ordering.

11. finding_id: R3-F11
    severity: medium
    change_type: clarity
    referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
    message: Always-on failure-menu footer text intent is ambiguous.
    §5 line 364: "A always-on footer reminds: 'If Haiku is repeatedly
    unavailable, option 1 is the recommended escape.'" "Always-on" presumably
    means "shown on every menu rendering, including the very first failure
    of the run." That biases the user toward option 1 the moment any
    verifier hiccups — which may be fine (Haiku outages are usually brief
    and option 1 is recoverable next run) or may be over-aggressive (one
    transient failure shouldn't push the user to disable verifier for the
    whole run). Clarify: is "always-on" intentional warm-priming, or is the
    intent "shown after the user has seen the menu once" (so first-failure
    UX is clean)? If the former, state it. If the latter, "always-on" is
    misleading. Recommend the former — Haiku failures are rare enough that
    when they occur, the user wants the escape hatch up front.

12. finding_id: R3-F12
    severity: medium
    change_type: clarity
    referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
    message: Test #11 sentinel-collision fixture is contrived as written.
    §7 test #11 (line 409) describes the case as "a finding's `message`
    body legitimately contains the literal string `## Verifier` (e.g., a
    reviewer quoting another verifier output)." A round-N reviewer
    physically CAN quote a round-(N-1) verifier output (round-(N-1) findings
    sit in `round-(N-1)/*.finding-*.md` with `## Verifier` blocks; a
    round-N reviewer that read those files in preparing its diff-review
    could quote the heading verbatim in its message body). State this
    explicitly in test #11's fixture description so the test author writes
    a realistic fixture (round-2 finding quoting round-1 verifier output)
    rather than a synthetic round-1 finding that quotes a heading nothing
    has yet emitted. Update §7 test #11 line 409.

---

Findings: 12 total — 6 high, 6 medium, 0 low.
