---
reviewer: security-claude
task: 33
round: 3
status: clean
---

# Security review — clean

Round 3 strengthens the `structural_lint` execution path with three independent
defenses, all of which hold against a threat model where the attacker controls
only the task-spec file (not committed scripts):

1. **Strict ERE token regex** `^scripts/structural-lints/[A-Za-z0-9_.-]+\.sh$`
   — anchored on both ends, closed character class that excludes every shell
   metacharacter (`;`, `|`, `&`, `$`, backtick, `\`, quotes, `<`, `>`, `*`, `?`,
   `(`, `)`, `{`, `}`, whitespace, tab, newline) and excludes `/` inside the
   filename token, so `..` segments cannot traverse out of the prefix
   directory. Inline commands, absolute paths, and metacharacter-bearing
   payloads are all rejected before any execution.
2. **Existence + readability precheck** before exec forces the named script to
   be a checked-in artifact under `scripts/structural-lints/`, which has its
   own code-review surface. A spec-only author cannot point at ad-hoc shell
   nor at arbitrary system binaries.
3. **Argv-mode invocation** `bash -- <validated-path>` with the path passed as
   a single argv element (explicitly never interpolated into `bash -c`) blocks
   option injection (filenames starting with `-` are treated as positional
   after `--`) and word-splitting.

Category sweep:

- **Injection:** closed by regex + argv-mode exec.
- **AuthZ:** spec-author cannot escalate to script-author authority; missing
  script is denied, not silently passed.
- **Data exposure / crypto / deps:** N/A — prose-only changes, no secrets,
  primitives, or new dependencies.
- **Input validation:** regex is anchored and closed; empty-value and
  empty-diff vacuous-pass paths are explicitly denied upstream.
- **TOCTOU between Step 2 existence check and Step 3 exec:** swapping the file
  between check and exec would require write access to
  `scripts/structural-lints/`, which is the same authority needed to land the
  script originally — not a boundary the spec author can cross. Not an
  exploitable finding.

No security findings.
