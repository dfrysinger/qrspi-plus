---
finding_id: R1-F01
severity: high
change_type: security
referenced_files: [scripts/run-codex-review.sh, agents/qrspi-implementer.md, agents/qrspi-test-writer.md]
artifact: integration
round: 1
reviewer: security-codex
---

## Bash tool grant enables arbitrary local-file exfiltration via Codex wrapper

**Surface:**
- `scripts/run-codex-review.sh:321-327` — `resolve_path()` accepts absolute paths unchanged and does no repo-boundary enforcement
- `scripts/run-codex-review.sh:462-467` — `emit_untrusted_artifact()` reads with `cat "$path"` and embeds content in dispatch prompt
- `scripts/run-codex-review.sh:557-560` — dispatcher forwards assembled body to `run-third-party-llm.sh --provider codex`
- `agents/qrspi-implementer.md:4` — `tools: Read, Write, Bash, Edit, Grep, Glob`
- `agents/qrspi-test-writer.md:5` — `tools: Read, Write, Edit, Bash, Grep, Glob` (Bash newly granted by Hotfix A)

**Threat model:**
With Hotfix A granting Bash to qrspi-implementer + qrspi-test-writer, a prompt-injection
attack on either agent (via untrusted artifact body in `task_definition`,
`companion_codebase_context`, etc.) can invoke `run-codex-review.sh` with arbitrary
absolute paths as `--subject-code` or `--companion`. The wrapper accepts them, reads
the files via `cat`, and ships the content over the sanctioned Codex review channel —
a trusted exfil path that may bypass network controls that would block attacker URLs.

**Reproduction:** Run from repo root with --dry-run flag (no network):
```bash
scripts/run-codex-review.sh --agent-file agents/qrspi-design-reviewer.md \
  --reviewer-tag test --output-dir /tmp/x --round 99 \
  --subject-code /etc/hosts \
  --companion companion_design=docs/qrspi/2026-05-27-v071-hardening/design.md \
  --dry-run
```
Output embeds `/etc/hosts` content inside `<<<UNTRUSTED-ARTIFACT-START id=/etc/hosts>>>`
markers — verified live in the round-01 review (full hosts file contents leaked into
the prompt buffer).

**Why integration-emergent:** The wrapper's path laxity is pre-existing in T6's hardened
script (T6 hardened `detect_host`/`check_codex_available` but did not touch
`resolve_path`/`emit_untrusted_artifact`). Hotfix A added a NEW reachable attack vector
by granting Bash to two in-the-loop agents whose untrusted input surface (per-task
dispatches) is large. Per-task security review of T6 covered only T6's host-detection
hardening; per-task review of Hotfix A's tool grant did not cross-reference all
wrapper scripts the granted agents could invoke. The composition is integration-scope.

**Suggested fix:**
1. In `scripts/run-codex-review.sh`, canonicalize all `--subject-code`/`--companion` paths via `readlink -f` (or `realpath`) and reject paths not under `$REPO_ROOT`. Fail closed on canonicalization failure (consistent with T6's pattern at lines ~165-180).
2. Tighten `resolve_path()` to enforce the same allowlist.
3. Add a bats test that confirms `--subject-code /etc/hosts` is rejected with non-zero exit and a clear error message.

**Severity rationale:** HIGH because (a) attack is trivially reproducible with --dry-run,
(b) trusted exfil channel (Copilot CLI -> OpenAI is allowlisted by infrastructure),
(c) two production agent surfaces newly hold the prerequisite Bash grant,
(d) no other layer of the wrapper enforces path containment.
