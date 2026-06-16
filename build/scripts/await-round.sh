#!/usr/bin/env bash
# scripts/await-round.sh — manifest-driven async drain for reviewer/verifier
# fan-out rounds (G3 + G4).
#
# Usage:
#   await-round.sh --round-dir <abs-round-dir>
#
# Reads <round-dir>/.dispatch-manifest.json. For every entry with
# `mode=background` and `status=pending`:
#   1. Run the entry's `await_cmd` to capture the third-party stdout into
#      <round-dir>/.dispatch/<tag>.raw.
#   2. Run the entry's `split_cmd` (typically `third-party-finding-splitter.sh`)
#      to materialise per-finding files under <round-dir>/<tag>.finding-F<NN>.md.
#   3. Update the manifest entry's `status` field on disk.
#
# Then write <round-dir>/.round-complete.json with per-tag status + summary
# counts, and remove the round-scoped <round-dir>/.dispatch/ subdir.
#
# Output-bound contract (CD-1 #4): MUST NOT echo captured third-party stdout
# (or any substring) to stdout or stderr. Terminal output is bounded to a
# short status summary (one line) plus diagnostics on failure. Captured raw
# payloads stay in tempfiles consumed only by `split_cmd`.
#
# Exit codes:
#   0  round drained successfully (.round-complete.json written)
#   1  unrecoverable transport failure on a background entry, or invalid args
#
# Bash 3.2 compatible (macOS system /bin/bash).
#
# Trust boundary — manifest exec model (shell+git injection hardening):
#   The .dispatch-manifest.json fields `await_cmd` and `split_cmd` are read
#   verbatim from disk. They are NEVER passed to a shell. The embedded Python
#   helper below parses each command via shlex.split, validates argv[0] in
#   one of two ways, and execs with `shell=False` and
#   `cwd=<round-dir>/.dispatch/`:
#     - Bare-name argv[0] (no '/'): must appear in BARE_NAME_ALLOWLIST. Only
#       names resolved via $PATH and audited as safe interpreters of their
#       own argv (e.g. `codex`) belong here.
#     - Path-shaped argv[0] (contains '/'): MUST resolve via os.path.realpath
#       (relative paths are resolved against DISPATCH_CWD; symlinks are
#       followed) under one of the permitted EXEC_ROOTS. EXEC_ROOTS is the
#       union of <repo-root>/scripts/ (looked up via `git rev-parse
#       --show-toplevel` from <round-dir>) and any colon-separated paths in
#       $QRSPI_AWAIT_EXEC_ROOTS (test fixtures + explicit dev override).
#   This rejects the canonical shell-RCE shapes (`/bin/sh -c '...'`,
#   `/bin/bash`, `/usr/bin/python3`), parent-traversal escapes
#   (`../../../tmp/attack.sh`), and relative-cwd masquerades (`./codex`
#   resolving under .dispatch/) — all of which previously bypassed a
#   bare-name-only allowlist because they contain '/'.
#   See parse_and_validate() in the inline python block.

set -u

ROUND_DIR=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --round-dir) ROUND_DIR="${2:-}"; shift 2 ;;
    *) echo "await-round: unknown flag: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$ROUND_DIR" ]; then
  echo "await-round: required flag missing: --round-dir <abs-round-dir>" >&2
  exit 1
fi

if [ ! -d "$ROUND_DIR" ]; then
  echo "await-round: --round-dir does not exist: $ROUND_DIR" >&2
  exit 1
fi

MANIFEST="$ROUND_DIR/.dispatch-manifest.json"
COMPLETE="$ROUND_DIR/.round-complete.json"

# Treat a missing manifest as "no dispatches were registered this round" —
# emit an empty round-complete summary and exit cleanly. This keeps await-
# round no-op-safe under any orchestrator path that calls it unconditionally.
if [ ! -f "$MANIFEST" ]; then
  printf '%s\n' '{"awaited":0,"with_findings":0,"clean":0,"entries":[]}' > "$COMPLETE"
  rm -rf "$ROUND_DIR/.dispatch"
  echo "await-round: no manifest; round complete (0 dispatches)." >&2
  exit 0
fi

# Drain pending background entries via python (manifest mutation + per-entry
# execution sequencing). Captured payloads are NEVER printed — only summary
# counts and per-entry status lines are emitted, and only to a temp file we
# then size-cap before forwarding any non-fatal errors to stderr.
RC_FILE="$(mktemp)"
SUM_FILE="$(mktemp)"
ERR_FILE="$(mktemp)"

ROUND_DIR_E="$ROUND_DIR" \
MANIFEST_E="$MANIFEST" \
COMPLETE_E="$COMPLETE" \
RC_FILE_E="$RC_FILE" \
SUM_FILE_E="$SUM_FILE" \
ERR_FILE_E="$ERR_FILE" \
python3 - <<'PYEOF'
import glob, json, os, shlex, subprocess, sys

round_dir = os.environ["ROUND_DIR_E"]
manifest_path = os.environ["MANIFEST_E"]
complete_path = os.environ["COMPLETE_E"]
rc_file = os.environ["RC_FILE_E"]
sum_file = os.environ["SUM_FILE_E"]
err_file = os.environ["ERR_FILE_E"]

# Trust boundary — manifest exec model (shell+git injection hardening):
# `await_cmd` and `split_cmd` are read VERBATIM from
# <round-dir>/.dispatch-manifest.json, which is on disk and writable by
# anything that has the round-dir path. We MUST NOT pass these strings to a
# shell. The validator below enforces:
#   1. Parse via shlex.split → argv list, exec with shell=False.
#   2. argv[0] starting with '-' is rejected (option-shaped — never a real
#      executable; could feed unintended flags to a downstream wrapper).
#   3. Bare-name argv[0] (no '/') must appear in BARE_NAME_ALLOWLIST. The
#      allowlist permits only audited interpreters of their own argv that
#      we have explicit reason to invoke via $PATH (currently `codex`).
#   4. Path-shaped argv[0] (contains '/') must resolve via os.path.realpath
#      — relative paths against DISPATCH_CWD, symlinks followed — under one
#      of EXEC_ROOTS. This rejects shell interpreters invoked as argv[0]
#      (`/bin/sh -c '...'`, `/bin/bash`, `/usr/bin/python3`), parent-
#      traversal escapes (`../../../tmp/attack.sh`), and relative-cwd
#      masquerade (`./codex`). EXEC_ROOTS is the union of
#      <repo-root>/scripts/ (from `git rev-parse --show-toplevel` of
#      round_dir, when round_dir is inside a git workspace) and any
#      colon-separated paths in $QRSPI_AWAIT_EXEC_ROOTS (test fixtures and
#      explicit dev override).
#   5. Run with cwd=<round-dir>/.dispatch/ so any relative-path writes from
#      legitimate callers stay confined to the round-scoped dispatch
#      directory which is removed on completion.
BARE_NAME_ALLOWLIST = {"codex"}
DISPATCH_CWD = os.path.join(round_dir, ".dispatch")

def _compute_exec_roots():
    roots = []
    # Best-effort repo-scripts root via git toplevel of round_dir.
    try:
        r = subprocess.run(
            ["git", "-C", round_dir, "rev-parse", "--show-toplevel"],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=False,
        )
        top = r.stdout.decode("utf-8", "replace").strip()
        if top:
            roots.append(os.path.realpath(os.path.join(top, "scripts")))
    except Exception:
        pass
    extra = os.environ.get("QRSPI_AWAIT_EXEC_ROOTS", "")
    for p in extra.split(":"):
        p = p.strip()
        if p:
            roots.append(os.path.realpath(p))
    # De-dup while preserving order.
    seen = set()
    out = []
    for r in roots:
        if r not in seen:
            seen.add(r)
            out.append(r)
    return out

EXEC_ROOTS = _compute_exec_roots()

def _under_root(resolved_path, root):
    if resolved_path == root:
        return True
    sep = os.sep
    return resolved_path.startswith(root + sep)

def _has_finding_artifacts(rdir, t):
    """True if per-finding files OR a clean sentinel exist on disk for this tag.
    Used by the universal stdout-fallback (Bug 3, v0.7.2.5) to decide whether
    to splitter-fallback on a raw capture."""
    if glob.glob(os.path.join(rdir, "%s.finding-F*.md" % t)):
        return True
    if os.path.isfile(os.path.join(rdir, "%s.clean.md" % t)):
        return True
    if os.path.exists(os.path.join(rdir, "%s.NO_FINDINGS" % t)):
        return True
    return False

def _try_stdout_fallback(rdir, t, errs_list):
    """Universal stdout-fallback (Bug 3, v0.7.2.5): if the subagent emitted its
    findings to stdout (FINDING-BOUNDARY format) rather than writing per-finding
    files via the Write tool, the orchestrator captured the Task return value to
    <round-dir>/.dispatch/<tag>.raw. Run the splitter on that capture so per-
    finding files materialize on disk regardless of which emission path the
    subagent took. Returns True on successful split, False if no fallback was
    possible (no raw capture present) or the splitter failed.

    Triggered universally — not gated on mode (first_party vs background) or on
    any vendor field — because the underlying invariant is "did the artifact
    land on disk", not "which dispatch path was used"."""
    raw_path = os.path.join(rdir, ".dispatch", "%s.raw" % t)
    if not os.path.isfile(raw_path):
        return None  # no raw to split; no-op (not a failure)
    # Resolve the splitter under the repo's scripts/ root (already a permitted
    # exec root in EXEC_ROOTS) so we don't reintroduce the manifest-exec trust
    # boundary for an internally-invoked helper.
    splitter = None
    for root in EXEC_ROOTS:
        candidate = os.path.join(root, "third-party-finding-splitter.sh")
        if os.path.isfile(candidate):
            splitter = candidate
            break
    if splitter is None:
        errs_list.append("await-round: stdout-fallback splitter not found under exec roots for %r" % t)
        return False
    try:
        r = subprocess.run(
            [splitter, "--round-dir", rdir, "--tag", t],
            shell=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except Exception as e:
        errs_list.append("await-round: stdout-fallback splitter exec error for %r: %s" % (t, type(e).__name__))
        return False
    if r.returncode != 0:
        errs_list.append("await-round: stdout-fallback splitter failed for %r (rc=%d)" % (t, r.returncode))
        return False
    return True

def parse_and_validate(cmdstr, kind, tag):
    """Return (argv, err_or_None). kind ∈ {"await_cmd","split_cmd"}."""
    try:
        argv = shlex.split(cmdstr)
    except ValueError as e:
        return None, "await-round: %s parse error for %r: %s: %s" % (kind, tag, type(e).__name__, e)
    if not argv:
        return None, "await-round: %s empty after parse for %r" % (kind, tag)
    exe = argv[0]
    # Reject any argv[0] that begins with '-' (option-style — never a real
    # executable; could feed unintended flags to a downstream wrapper).
    if exe.startswith("-"):
        return None, "await-round: %s rejected for %r: argv[0] must not start with '-'" % (kind, tag)
    if "/" not in exe:
        # Bare-name argv[0] (resolved via $PATH): only allowlisted basenames.
        if exe not in BARE_NAME_ALLOWLIST:
            return None, ("await-round: %s rejected for %r: bare-name executable %r "
                          "not in allowlist %r; manifest commands must use a path "
                          "(absolute or relative under permitted exec roots) or an "
                          "explicitly allowlisted bare name."
                          % (kind, tag, exe, sorted(BARE_NAME_ALLOWLIST)))
        return argv, None
    # Explicit-cwd-relative argv[0] (./foo, ../foo) is never legitimate from
    # a manifest entry: the dispatch cwd is the round-scoped .dispatch/
    # directory which is removed on completion, and any legitimate caller
    # uses an absolute path or an in-tree scripts/ path. Reject these
    # outright to block the `./codex` masquerade where an attacker stages a
    # binary under .dispatch/ and bypasses the system PATH lookup.
    if exe.startswith("./") or exe.startswith("../"):
        return None, ("await-round: %s rejected for %r: argv[0] %r begins with "
                      "'./' or '../'; manifest commands must use an absolute "
                      "path or a name resolved via $PATH (allowlist)."
                      % (kind, tag, exe))
    # Path-shaped argv[0]: realpath-resolve against DISPATCH_CWD (so relative
    # paths and parent-traversal collapse the same way subprocess.run would
    # see them) and require the resolved path to lie under one of EXEC_ROOTS.
    # This blocks /bin/sh, /bin/bash, /usr/bin/python3, ../../../tmp/x,
    # ./codex masquerade, and any other path that escapes the permitted tree.
    try:
        resolved = os.path.realpath(os.path.join(DISPATCH_CWD, exe))
    except Exception as e:
        return None, ("await-round: %s rejected for %r: realpath resolution failed for %r: %s: %s"
                      % (kind, tag, exe, type(e).__name__, e))
    for root in EXEC_ROOTS:
        if _under_root(resolved, root):
            return argv, None
    return None, ("await-round: %s rejected for %r: argv[0] %r resolves to %r "
                  "which is outside permitted exec roots %r."
                  % (kind, tag, exe, resolved, EXEC_ROOTS))

errs = []
with open(manifest_path) as f:
    manifest = json.load(f)

awaited = 0
with_findings = 0
clean = 0
final_rc = 0

if not isinstance(manifest, list):
    errs.append("await-round: manifest must be a JSON array")
    final_rc = 1
    manifest = []

for entry in manifest:
    if not isinstance(entry, dict):
        continue
    mode = entry.get("mode")
    status = entry.get("status")
    tag = entry.get("tag", "<no-tag>")

    # Background pending entries: execute await_cmd + split_cmd before the
    # universal fallback + finding-detection below. Other entries (first_party,
    # or background entries with a non-pending status) skip this block — they
    # either drained at dispatch time (first_party Task return) or were drained
    # by a prior await-round invocation. They still pass through the universal
    # stdout-fallback + finding-detection below (Bug 3, v0.7.2.5).
    if mode == "background" and status == "pending":
        awaited += 1
        await_cmd = entry.get("await_cmd")
        split_cmd = entry.get("split_cmd")
        if not await_cmd:
            errs.append("await-round: entry %r missing await_cmd" % tag)
            entry["status"] = "failed"
            final_rc = 1
            continue

        # Execute await_cmd. shell=False + parsed argv. Captured stdout/stderr
        # remain DEVNULL — they may carry raw third-party payload fragments that
        # must not surface (CD-1 #4).
        argv, perr = parse_and_validate(await_cmd, "await_cmd", tag)
        if argv is None:
            errs.append(perr)
            entry["status"] = "failed"
            final_rc = 1
            continue
        # Ensure the confinement directory exists so cwd= doesn't blow up on
        # already-cleaned rounds; any prior `rm -rf .dispatch` leaves a clean
        # slate, and we want await_cmd's relative writes to land here. Failing
        # to create the dir is recorded explicitly so a downstream FileNotFound /
        # NotADirectory is not misattributed to a missing await_cmd binary.
        try:
            os.makedirs(DISPATCH_CWD, exist_ok=True)
        except Exception as e:
            errs.append("await-round: failed to create dispatch cwd %r for %r: %s: %s"
                        % (DISPATCH_CWD, tag, type(e).__name__, e))
            entry["status"] = "failed"
            final_rc = 1
            continue
        try:
            r = subprocess.run(
                argv, shell=False,
                cwd=DISPATCH_CWD,
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            )
        except Exception as e:
            errs.append("await-round: await_cmd execution error for %r: %s" % (tag, type(e).__name__))
            entry["status"] = "failed"
            final_rc = 1
            continue
        if r.returncode != 0:
            errs.append("await-round: await_cmd failed for %r (rc=%d)" % (tag, r.returncode))
            entry["status"] = "failed"
            final_rc = 1
            continue

        # Execute split_cmd if present (shell=False + parsed argv).
        if split_cmd:
            argv_s, perr_s = parse_and_validate(split_cmd, "split_cmd", tag)
            if argv_s is None:
                errs.append(perr_s)
                entry["status"] = "failed"
                final_rc = 1
                continue
            try:
                rs = subprocess.run(
                    argv_s, shell=False,
                    cwd=DISPATCH_CWD,
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                )
            except Exception as e:
                errs.append("await-round: split_cmd execution error for %r: %s" % (tag, type(e).__name__))
                entry["status"] = "failed"
                final_rc = 1
                continue
            if rs.returncode != 0:
                errs.append("await-round: split_cmd failed for %r (rc=%d)" % (tag, rs.returncode))
                entry["status"] = "failed"
                final_rc = 1
                continue

    # Universal stdout-fallback (Bug 3, v0.7.2.5): if per-finding files do
    # NOT exist on disk for this tag but the orchestrator captured a raw
    # stdout payload to <round-dir>/.dispatch/<tag>.raw, run the splitter
    # on it so per-finding files materialize regardless of which emission
    # path the subagent took. The invariant is "did the artifact land on
    # disk", not "which dispatch path was used", so this runs for both
    # first_party and background entries.
    #
    # Tri-state return from _try_stdout_fallback:
    #   None  → no raw present; nothing to do (NOT a failure on its own —
    #           a downstream apply-fix step's "expected tag produced no
    #           output" diagnostic will surface a truly missing reviewer).
    #   True  → splitter ran ok; per-finding files / clean sentinel
    #           materialized (success).
    #   False → splitter was attempted (raw present) but FAILED (missing
    #           splitter, exec error, non-zero rc). This is a real failure
    #           and must not silently flow to clean — even if the raw was
    #           garbage, it represents a reviewer that emitted output and
    #           the orchestrator must surface it.
    fallback_failed = False
    if not _has_finding_artifacts(round_dir, tag):
        fb = _try_stdout_fallback(round_dir, tag, errs)
        if fb is False:
            fallback_failed = True

    # Detect findings: any <round-dir>/<tag>.finding-F*.md file (and not a
    # NO_FINDINGS sentinel). The splitter is the authority here; we just
    # count files for the summary. Preserve any pre-existing "failed" status
    # (set upstream by dispatch-agent.sh when a background launch failed, or
    # set above by the await/split error paths) UNLESS the stdout-fallback
    # recovered finding artifacts from a captured raw payload — in which
    # case the failure was transport-level and the recovered output stands.
    # Likewise, a stdout-fallback that was ATTEMPTED but FAILED (raw payload
    # present, splitter could not produce artifacts) must surface as failed
    # rather than silently flowing to clean — the reviewer emitted something
    # the orchestrator must not discard.
    findings = glob.glob(os.path.join(round_dir, "%s.finding-F*.md" % tag))
    sentinel = os.path.exists(os.path.join(round_dir, "%s.NO_FINDINGS" % tag))
    was_failed = (entry.get("status") == "failed")
    if findings:
        with_findings += 1
        entry["status"] = "complete-with-findings"
    elif was_failed:
        # No recoverable artifacts on a previously-failed entry. Keep the
        # failure visible in the manifest + summary so the orchestrator
        # diagnostic surfaces it instead of silently counting it clean.
        errs.append("await-round: entry %r remained failed with no recovered findings" % tag)
        final_rc = 1
    elif fallback_failed:
        # Stdout-fallback was attempted (.dispatch/<tag>.raw existed) but
        # the splitter could not produce per-finding files. Mark failed so
        # the round does not silently look clean while losing reviewer output.
        entry["status"] = "failed"
        final_rc = 1
    else:
        clean += 1
        entry["status"] = "complete-clean" if sentinel else "complete"

# Atomic-mv manifest update.
mtmp = manifest_path + ".tmp"
with open(mtmp, "w") as f:
    json.dump(manifest, f, indent=2, sort_keys=True)
    f.write("\n")
os.replace(mtmp, manifest_path)

# Round-complete summary.
summary = {
    "awaited": awaited,
    "with_findings": with_findings,
    "clean": clean,
    "entries": [
        {"tag": e.get("tag"), "status": e.get("status")}
        for e in manifest if isinstance(e, dict)
    ],
}
ctmp = complete_path + ".tmp"
with open(ctmp, "w") as f:
    json.dump(summary, f, indent=2, sort_keys=True)
    f.write("\n")
os.replace(ctmp, complete_path)

# Persist control surfaces for the bash wrapper.
with open(rc_file, "w") as f:
    f.write(str(final_rc))
with open(sum_file, "w") as f:
    f.write("await-round: drained %d background dispatch(es); %d with findings, %d clean.\n"
            % (awaited, with_findings, clean))
# Bound err_file to a small size cap to honor the output-bound contract even
# in pathological subprocess error storms.
with open(err_file, "w") as f:
    text = "\n".join(errs)
    if len(text) > 1024:
        text = text[:1024] + "\n[await-round: diagnostics truncated to 1KiB]"
    f.write(text)
PYEOF

py_rc=$?
if [ "$py_rc" -ne 0 ]; then
  echo "await-round: internal drain failure (python rc=$py_rc)" >&2
  rm -f "$RC_FILE" "$SUM_FILE" "$ERR_FILE"
  exit 1
fi

# Forward bounded summary to stderr (so stdout stays empty for output-bound
# parity with dispatch-companion `await`). Per structure.md §14: stdout is
# the short status line.
if [ ! -f "$RC_FILE" ]; then
  echo "await-round: internal error — RC_FILE not found after python drain" >&2
  rm -f "$SUM_FILE" "$ERR_FILE"
  exit 1
fi
RC_VALUE="$(cat "$RC_FILE")"
SUM_LINE="$(cat "$SUM_FILE" 2>/dev/null | head -c 4096 || true)"
ERR_TEXT="$(cat "$ERR_FILE" 2>/dev/null || true)"

# Strip any errant payload-shaped material that might somehow have leaked
# into the diagnostic file. We only allow short ASCII diagnostics; if the
# err file exceeds 1 KiB we truncate again as a defense in depth.
if [ -n "$ERR_TEXT" ]; then
  printf '%s\n' "$ERR_TEXT" | head -c 1024 >&2
  printf '\n' >&2
fi

# Short status line on stdout.
printf '%s' "$SUM_LINE"

# Always remove the round-scoped dispatch subdir AFTER the summary is on
# disk. Per structure.md L1023 + §14.
rm -rf "$ROUND_DIR/.dispatch"

rm -f "$RC_FILE" "$SUM_FILE" "$ERR_FILE"

exit "$RC_VALUE"
