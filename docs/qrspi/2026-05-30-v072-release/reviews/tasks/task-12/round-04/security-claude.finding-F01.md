---
finding_id: R4-F01
reviewer_tag: security-claude
round: 4
task: 12
severity: low
change_type: correctness
referenced_files:
  - scripts/await-round.sh
---

# F01 — `tag` field used in `glob.glob` without validation; glob metacharacters corrupt round-complete accounting

## Location

`scripts/await-round.sh` lines 325–332 (Python block — `glob.glob` call).

## Adversarial-trace summary (R3 fix d3114e3, parse_and_validate)

Verified the R3 RCE fix is structurally sound. Walked 10 adversarial inputs through `parse_and_validate`; all 10 produce the expected REJECT or ACCEPT verdict:

| # | Input | Expected | Actual |
|---|-------|----------|--------|
| 1 | `/bin/sh -c 'touch /tmp/pwn'` | REJECT | REJECT (realpath bounds) |
| 2 | `/bin/bash -c 'evil'` | REJECT | REJECT (realpath bounds) |
| 3 | `/usr/bin/python3 -c 'os.system(...)'` | REJECT | REJECT (realpath bounds) |
| 4 | `/usr/bin/touch /tmp/pwn` | REJECT | REJECT (realpath bounds) |
| 5 | `../../../tmp/attack.sh` | REJECT | REJECT (explicit `../` prefix) |
| 6 | `./codex --reviewer x` | REJECT | REJECT (explicit `./` prefix) |
| 7 | `touch /tmp/pwn` | REJECT | REJECT (bare-name allowlist miss) |
| 8 | `codex --reviewer x` | ACCEPT | ACCEPT (bare-name allowlist hit) |
| 9 | `<repo>/scripts/run-codex-review.sh ...` | ACCEPT | ACCEPT (under EXEC_ROOTS) |
| 10 | Symlink → `<repo>/scripts/` | ACCEPT | ACCEPT (realpath resolves on both sides) |

Tested edge shapes for remaining bypasses: empty argv, `-foo`, `foo/bar` relative, null-byte injection, U+2215 unicode-fake-slash, `/repo/scripts/../../../etc/passwd`, `/repo/scripts-evil/x` adjacent-directory confusion. **No remaining bypass shapes found.** `_under_root` correctly appends `os.sep` before the prefix test (line 169), blocking adjacent-directory confusion.

`QRSPI_AWAIT_EXEC_ROOTS` env var: production-safe when unset (`"".split(":")` → `[""]` filtered by `if p:` → zero extra roots). Documented in header as "test fixtures + explicit dev override".

`git rev-parse --show-toplevel` invoked once at module level — no per-entry TOCTOU.

## New finding

The R3 fix closed the `await_cmd` / `split_cmd` RCE via `parse_and_validate`. But the manifest carries one more field that flows into a filesystem operation without validation: `tag`.

```python
# scripts/await-round.sh ~ line 325
findings = glob.glob(os.path.join(round_dir, "%s.finding-F*.md" % tag))
sentinel  = os.path.exists(os.path.join(round_dir, "%s.NO_FINDINGS" % tag))
```

`tag` is read directly from the manifest JSON (`entry.get("tag", "<no-tag>")`) and is never validated before being interpolated into a `glob.glob` pattern. On POSIX, `glob.glob` expands `*`, `?`, and `[...]` metacharacters in the path argument. `os.path.exists` does NOT expand globs, so that line is safe; only the `glob.glob` call is affected.

## Attack scenario (manifest-write access required — same threat model as the R3 RCE)

An attacker who controls `.dispatch-manifest.json` sets:

```json
{"tag": "security-claude*", "mode": "background", "status": "pending",
 "await_cmd": "codex --reviewer-tag security-claude ...", "split_cmd": "..."}
```

1. When this entry is processed, `glob.glob(<round_dir>/security-claude*.finding-F*.md)` matches finding files legitimately written by the **real** `security-claude` reviewer in the same round directory.
2. This entry is counted in `with_findings` even though its own `split_cmd` emitted nothing. Its `status` is set to `"complete-with-findings"` in the manifest.
3. `.round-complete.json` records `with_findings += 1` for this entry based on files it did not produce.
4. The orchestrator's convergence logic and round-termination decisions consume `.round-complete.json` — crafted accounting could suppress real findings or trigger premature round-closure.

Path-traversal variant: `tag = "../../other-round/attacker*"` causes the glob to search outside the round directory entirely, matching any `.finding-F*.md` files in sibling paths the process can read.

No code execution. This is a manifest integrity / accounting integrity attack — a real reviewer's findings could be silently absorbed and miscounted, causing the orchestrator to conclude "round CLEAN" when KEPT findings actually exist.

## Severity rationale

LOW: requires the same manifest-write capability as the closed RCE (so the attacker needs to be inside the trust boundary already), and the impact is integrity-of-accounting rather than code execution or filesystem write. Still meaningful because the orchestrator's batch-gate decisions depend on `.round-complete.json` being accurate; silently suppressing a security finding could cause real vulnerabilities to ship as "clean."

## Suggested remediation (informational — budget exhausted, accepted-with-issues)

Validate `tag` at manifest load time (alongside existing `mode`/`status` checks ~ lines 239–245) against a strict allowlist pattern: `re.match(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$', tag)`. Reject the entry if `tag` does not match. Apply the validation BEFORE any filesystem lookup or command execution — same defense pattern `parse_and_validate` uses for `await_cmd`/`split_cmd`.

This is a v0.7.3 candidate fix — same fix-pattern as R3, applied to the one manifest field that was missed.
