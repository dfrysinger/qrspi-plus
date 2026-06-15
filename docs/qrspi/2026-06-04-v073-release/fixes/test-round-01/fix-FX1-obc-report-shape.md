# fix-FX1: OBC report shape — align with design.md §G5(b) acceptance contract

## Source
Test phase round-01: 6 reds across test-g5 #7/#10/#11, test-integration #10, test-regressions #3/#6.

## Divergence

design.md §G5(b) and Acceptance bullet on line 386 specify:
- Two sections: `## Boundary violations` (uncommitted-edit + non-subagent-commit entries) and `## Dispatch defects`
- Each section header emitted ONLY when that section has at least one entry
- **A clean run produces a byte-empty file**

`scripts/orchestration-boundary-check.sh` lines 304-313 currently emit:
- Three sections: `## Dispatch defects`, `## Commit violations`, `## Workspace violations`
- Always-present `# Orchestration boundary report` header
- `_None._` placeholders on clean runs (not byte-empty)

## Fix

In `scripts/orchestration-boundary-check.sh`:
1. Drop the `# Orchestration boundary report\n\n` header (line 304).
2. Replace the two arrays `commit_violations` + `workspace_violations` with a single combined `boundary_violations` array; entries should distinguish themselves by content prefix (e.g. `non-subagent-commit:` vs `uncommitted-edit:`) per design's existing convention.
3. Reorder to emit `## Boundary violations` first, then `## Dispatch defects` (matches design.md ordering).
4. Ensure emit_section truly skips header when array is empty (check existing implementation; the bug may already be there — verify the resulting file is byte-empty on a clean run by `[ ! -s file ]`).

## Test scope
- Update any existing `tests/unit/*orchestration-boundary*` tests that grep for `## Commit violations` or `## Workspace violations` to match the new `## Boundary violations` shape.
- The 6 Test-phase reds will turn green automatically.

## Out of scope
- Do NOT modify the SKILL prose contracts in skills/{integrate,test,implement}/SKILL.md (they already reference the design-correct two-section names).
