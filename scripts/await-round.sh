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
# Trust boundary (R2 hardening — security-claude R2-F01/F02):
#   The .dispatch-manifest.json fields `await_cmd` and `split_cmd` are read
#   verbatim from disk. They are NEVER passed to a shell. The embedded Python
#   helper below parses each command via shlex.split, validates argv[0]
#   against an executable allowlist (path-shaped OR `codex`), and execs with
#   `shell=False` and `cwd=<round-dir>/.dispatch/`. This blocks the canonical
#   RCE shape (`touch /tmp/pwned`) and confines relative-path writes to the
#   round-scoped dispatch directory which is removed on completion.
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
import json, os, shlex, subprocess, sys

round_dir = os.environ["ROUND_DIR_E"]
manifest_path = os.environ["MANIFEST_E"]
complete_path = os.environ["COMPLETE_E"]
rc_file = os.environ["RC_FILE_E"]
sum_file = os.environ["SUM_FILE_E"]
err_file = os.environ["ERR_FILE_E"]

# Trust boundary (R2 hardening — security-claude R2-F01/F02):
# `await_cmd` and `split_cmd` are read VERBATIM from
# <round-dir>/.dispatch-manifest.json, which is on disk and writable by
# anything that has the round-dir path. We MUST NOT pass these strings to a
# shell. Instead:
#   1. Parse via shlex.split → argv list, exec with shell=False.
#   2. Validate argv[0]: must contain '/' (relative or absolute path) OR be
#      a bare basename in BARE_NAME_ALLOWLIST. This blocks bare commands like
#      `touch`, `curl`, `rm` while permitting real callers (scripts/<name>.sh
#      and the `codex` CLI).
#   3. Run with cwd=<round-dir>/.dispatch/ so any relative-path writes from
#      legitimate callers stay confined; absolute-path writes outside the
#      workspace are still possible only if the executable allowlist permits
#      them (and our allowlist permits no general-purpose write tools).
# Documented in script header comments above (see "Trust boundary").
BARE_NAME_ALLOWLIST = {"codex"}
DISPATCH_CWD = os.path.join(round_dir, ".dispatch")

def parse_and_validate(cmdstr, kind, tag):
    """Return (argv, err_or_None). kind ∈ {"await_cmd","split_cmd"}."""
    try:
        argv = shlex.split(cmdstr)
    except ValueError as e:
        return None, "await-round: %s parse error for %r: %s" % (kind, tag, type(e).__name__)
    if not argv:
        return None, "await-round: %s empty after parse for %r" % (kind, tag)
    exe = argv[0]
    # Reject any argv[0] that begins with '-' (option-style — never a real
    # executable; could feed unintended flags to a downstream wrapper).
    if exe.startswith("-"):
        return None, "await-round: %s rejected for %r: argv[0] must not start with '-'" % (kind, tag)
    # Bare-name (no '/') executables are rejected unless explicitly allowed.
    # This blocks the canonical RCE shape: `touch /tmp/pwned`, `curl ...`, etc.
    if "/" not in exe and exe not in BARE_NAME_ALLOWLIST:
        return None, ("await-round: %s rejected for %r: bare-name executable %r "
                      "not in allowlist; manifest commands must use a path "
                      "(e.g. 'scripts/foo.sh') or an allowed binary (codex)."
                      % (kind, tag, exe))
    return argv, None

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
    if mode != "background":
        # First-party entries are already drained at dispatch time; nothing
        # to do here. We still count them in the summary as "clean" if their
        # status is not "pending".
        continue
    if status != "pending":
        continue

    awaited += 1
    await_cmd = entry.get("await_cmd")
    split_cmd = entry.get("split_cmd")
    if not await_cmd:
        errs.append("await-round: entry %r missing await_cmd" % tag)
        entry["status"] = "failed"
        final_rc = 1
        continue

    # Execute await_cmd. shell=False + parsed argv (R2 hardening). Captured
    # stdout/stderr remain DEVNULL — they may carry raw third-party payload
    # fragments that must not surface (CD-1 #4).
    argv, perr = parse_and_validate(await_cmd, "await_cmd", tag)
    if argv is None:
        errs.append(perr)
        entry["status"] = "failed"
        final_rc = 1
        continue
    # Ensure the confinement directory exists so cwd= doesn't blow up on
    # already-cleaned rounds; any prior `rm -rf .dispatch` leaves a clean
    # slate, and we want await_cmd's relative writes to land here.
    try:
        os.makedirs(DISPATCH_CWD, exist_ok=True)
    except Exception:
        pass
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

    # Detect findings: any <round-dir>/<tag>.finding-F*.md file (and not a
    # NO_FINDINGS sentinel). The splitter is the authority here; we just
    # count files for the summary.
    import glob
    findings = glob.glob(os.path.join(round_dir, "%s.finding-F*.md" % tag))
    sentinel = os.path.exists(os.path.join(round_dir, "%s.NO_FINDINGS" % tag))
    if findings:
        with_findings += 1
        entry["status"] = "complete-with-findings"
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
RC_VALUE="$(cat "$RC_FILE" 2>/dev/null || echo 0)"
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
