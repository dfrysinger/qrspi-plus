---
finding_id: R1-F02
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L69-L74]
artifact: structure
round: 1
reviewer: quality-claude
---

`agents/qrspi-parallelize-scope-reviewer.md` is listed in the Slice 4 file map with `Action: Modify` but the Responsibility column states "Consumes the updated `owns-defers.md`; no body edit beyond regenerated runtime reads. (Listed because the scope reviewer is the consumer whose false-positive behavior the OWNS change fixes; the file body itself only changes if vocab references exist.)"

A file that receives no changes should not appear in the file map as `Action: Modify`. The file map's purpose is to enumerate every file that implementation tasks will CREATE or MODIFY in this release. Listing a no-change file causes Plan/Implement to generate a task for it — and that task will produce either an empty diff or spurious cosmetic changes added to justify the task's existence.

The design (§G8) owns edits to `skills/parallelize/owns-defers.md` and `agents/qrspi-parallelize-reviewer.md`. The scope reviewer is a consumer of `owns-defers.md` at runtime (it reads the file via its preload chain), but that consumption is handled by the runtime read — no edit to `agents/qrspi-parallelize-scope-reviewer.md` is needed. The parenthetical in the Responsibility column acknowledges this but does not resolve the problem: including the file with `Action: Modify` misleads downstream agents regardless of the explanatory note.

Fix: remove `agents/qrspi-parallelize-scope-reviewer.md` from the Slice 4 file map. If the intent is to document that the scope reviewer's behavior changes as a consequence of the `owns-defers.md` update, that can be captured in the Responsibility column of the `skills/parallelize/owns-defers.md` row as a note ("the scope reviewer's false-positive behavior is fixed as a result of this OWNS addition") rather than as a separate file entry.
