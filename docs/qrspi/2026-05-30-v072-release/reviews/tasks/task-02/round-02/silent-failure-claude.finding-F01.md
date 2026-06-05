---
finding_id: R2-F01
reviewer_tag: silent-failure-claude
round: 2
task: 02
severity: medium
change_type: correctness
referenced_files:
  - scripts/verifier-fan-in.sh
---

## F01 — Sidecar readability not guarded; unreadable sidecar silently mislabelled `score_unparseable`

`scripts/verifier-fan-in.sh` lines 221–248.

The R1 codex-F01 fix added a `[[ ! -r "$finding" ]]` guard for finding files (lines 198–203) but left the sidecar path unguarded. If the sidecar file exists but is unreadable:

1. `[[ ! -f "$sidecar" ]]` at line 221 passes (file exists).
2. `extract_frontmatter_field "$sidecar" score || true` (line 239): awk can't open the file, `|| true` swallows the error, `raw_score=""`.
3. `record_halt "$fid" score_unparseable` fires — but no "cannot read" message is emitted.

Operator sees `score_unparseable` in the audit JSON and investigates score formatting, not file permissions. Same defect class as the original codex-F01, reproduced on the sidecar.

No test exercises `chmod 000 sidecar.score.md`; this surface has no regression pin.

Fix: add a `[[ ! -r "$sidecar" ]]` readability guard after the sidecar existence check (line 232), mirroring lines 198–203 for findings. Add a parallel bats test.
