---
finding_id: R2-F04
severity: medium
change_type: correctness
referenced_files:
  - skills/reviewer-protocol/third-party-emission.md:81
  - tests/unit/test-per-finding-file-emission.bats:131
artifact: task-03
round: 2
reviewer: silent-failure-claude
---

# F04 — Write-in-sandbox "fails silently" property is not pinned by any bats assertion (medium · correctness)

**Novel angle — not flagged by sf-codex.** The iron law at `third-party-emission.md:81` includes the parenthetical: *"attempts to call the Write tool (which will fail silently in this read-only sandbox)"*. This characterizes the failure mode as **silent**: third-party reviewer mistakenly calling Write receives no error signal at call time.

The bats test (line 131) pins only `expected tag produced no output` — does NOT pin the "fails silently" characterization. If a future edit changes the parenthetical to "will return a tool error" (loud instead of silent), test still passes but failure-mode category has changed; downstream guidance ("watch for a Write error") would silently become wrong.

The silent-vs-loud distinction is load-bearing for operator design: silent → defensive design ("assume Write is unavailable"); loud → reactive design ("catch and fall back").

**In-scope T03 R3 fix:** Add a one-line bats assertion to test 4:
```bash
grep -qE 'fail(s)? silently|silent(ly)? fail' "$f" \
  || { echo "third-party silent-failure characterization not pinned"; return 1; }
```
