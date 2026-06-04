<!-- skills/_shared/verifier-dispatch-prose.md
     Shared verifier-dispatch snippet, `!cat`-included into:
       - skills/using-qrspi/SKILL.md   (artifact-level Apply-fix protocol)
       - skills/implement/SKILL.md     (task-level Apply-fix protocol)
     Source of truth: design.md CD-4 §H + structure.md Slice 1.1.
     Mirrors skills/_shared/reviewer-dispatch-prose.md (CD-1 §11). The two
     snippets are deliberately separate because each names a different
     `dispatch-agent.sh` mode flag at the call site (the load-bearing
     difference) — see design.md CD-4 §H rationale (L494). -->

## Verifier Dispatch

The verifier round dispatches one verifier per reviewer finding through the
universal `dispatch-agent.sh` entry point and consumes scored sidecars
through `scripts/verifier-fan-in.sh`. The orchestrator NEVER loops per
finding and NEVER chat-parses verifier output to compute the kept set —
the script is the only path (CD-4 iron rule).

The orchestrator-side flow is exactly four Bash invocations plus one
parallel `Task` batch:

1. **Dispatch.** ONE Bash call that enumerates findings under
   `<round-dir>` and prepares per-finding `PROMPT_FILE`s:

   ```sh
   scripts/dispatch-agent.sh --verifier-fanout \
     --step <step> --round <N> --output-dir <round-dir> \
     [--tier-override <tier>]
   ```

   `--tier-override` takes a bare `<tier>` value (e.g. `low`, `medium`).
   It does NOT use the reviewer-fanout `tag=tier` CSV grammar — the
   verifier is a singleton agent (`qrspi-finding-verifier`), so there is
   nothing to key the override on. The script enumerates
   `<round-dir>/*.finding-F*.md`, builds one `PROMPT_FILE` per finding
   under `<round-dir>/.dispatch/`, appends one entry to the round's
   `dispatch-manifest.json`, and emits one spec line per first-party
   verifier on stdout (background-dispatching any third-party
   verifiers).

2. **Iterate spec lines (one Task call per line).** ONE parallel `Task`
   batch — invoke the `Task` tool exactly once per emitted spec line,
   copying `SUBAGENT_TYPE`, `MODEL`, and `PROMPT_FILE` verbatim from the
   spec line. The prompt argument is literally the string
   `"DISPATCH_FILE=<absolute-path-from-PROMPT_FILE>"` and nothing else.
   Same iron law as reviewer dispatch: one Task call per emitted spec
   line, verbatim values, no inline reasoning, no per-finding loop in
   orchestrator prose. Verifier reasoning prose lives only in the
   on-disk `<reviewer-tag>.finding-F<NN>.score.md` sidecars; the
   orchestrator MUST NOT echo sidecar bodies to stdout/stderr.

3. **Await.** ONE Bash call to wait on any background entries
   (no-op-safe when the round is first-party only):

   ```sh
   scripts/await-round.sh --round-dir <round-dir>
   ```

4. **Fan in.** ONE Bash call to filter the round through the
   script-owned threshold rule and emit `kept-findings.txt`:

   ```sh
   scripts/verifier-fan-in.sh <round-dir>
   ```

   `scripts/verifier-fan-in.sh` is the canonical filter: it reads each
   reviewer finding + its paired `<reviewer-tag>.finding-F<NN>.score.md`
   sidecar, applies the threshold rule from its header constants
   (single source of truth for `change_type` enum + per-`change_type`
   floors), and writes `<round-dir>/kept-findings.txt` (one absolute
   finding-file path per kept finding, one per line) plus
   `<round-dir>/.verifier-fan-in-audit.json` (counts + threshold echo +
   halts list). Apply-fix MUST consume `kept-findings.txt` rather than
   verifier chat output.

A non-zero exit from `scripts/verifier-fan-in.sh` means the round failed
to converge (missing `change_type`, out-of-enum value, missing sidecar,
sidecar at wrong extension, or unparseable score). The orchestrator
surfaces the named halt cause from `.verifier-fan-in-audit.json` and
does NOT proceed to apply-fix.
