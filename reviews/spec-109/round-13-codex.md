1. `finding_id`: `R13-F01`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `The spec still reintroduces the removed F00 fallback. Line 92 documents a "splitter-fallback form" of R{NN}-F00-<reviewer_tag> for malformed Codex output, but lines 122-125 and 139 say malformed/empty Codex output now writes nothing and is handled only as "expected tag produced no output". Those two contracts cannot both be true. If an implementer follows line 92, they will resurrect the fallback path that round 12 deliberately removed. Delete the F00 fallback from the reviewer-protocol amendment and keep the schema/guard aligned with the zero-output failure path only.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

2. `finding_id`: `R13-F02`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `The no-output diagnostic path is documented with an inspection location and wording that do not match the actual machinery. The spec says raw stdout lives under /tmp/codex-await/<jobid>/stdout.txt and uses the example "Reviewer quality-claude produced no output" (lines 11, 122, 220-221, 282), but the current wrapper writes audit rows under the artifact dir and the shared launch/await contract does not expose a /tmp/codex-await/.../stdout.txt path. It is also wrong for Claude reviewer failures, which have no Codex stdout to inspect. As written, the menu will tell users to inspect a path that may not exist and will blur together three different causes: Claude write failure, splitter-rejected Codex stdout, and await non-zero. Replace this with cause-accurate diagnostics: Claude/no-write should say no file was written; splitter-malformed may point at the captured await stdout only if the orchestration step actually persists it; await non-zero should cite the wrapper stderr/audit status instead of claiming a raw-stdout file exists.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","scripts/codex-companion-bg.sh","skills/_shared/codex/launch-await-pattern.md"]`
