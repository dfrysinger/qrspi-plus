---
reviewer: sr-claude
round: 1
task: task-03
status: clean
---

All spec requirements verified against diff (`9cc284b`→`c05cde0`) and HEAD files.

## Checklist

### Completeness
- `extract_section_fence_aware` added to `tests/helpers/skill-markdown.bash` (lines 200–295) ✅
- Awk implementation uses fence-state tracking (`fence = !fence`) per spec ✅
- Both call sites in `tests/unit/test-skill-md-content-patterns.bats` migrated (lines 168, 189 at HEAD) ✅
- Inline `extract_review_round` definition removed from `test-skill-md-content-patterns.bats` ✅

### Spec test-expectation bullets — all 10 covered
1. **Anchor inclusive, stop at out-of-fence boundary** → `[fence-aware-extractor] basic extraction` ✅
2. **### / ## inside fence not a boundary** → `H3 and H2 heading-shaped lines inside a code fence` ✅
3. **Closing fence restores boundary detection** → `closing triple-backtick fence restores` ✅
4. **Section to EOF** → `section extending to EOF` ✅
5. **Error paths: exit non-zero, prefix, anchor in message, distinguishable** → 3 tests: missing-anchor, empty-region, distinguishable messages ✅
6. **Whitespace-only region → no-content error** → `whitespace-only region` ✅
7. **Anchor line included in output** → co-covered in basic extraction test ✅
8. **Migrated call sites produce identical output** → `fenced-code fixture output matches parity contract` ✅
9. **Removing inline causes no failures** → `inline extract_review_round definition removed` (structural check) ✅
10. **Pre-existing extract_section tests unchanged** → no pre-existing test lines removed in diff (passive satisfaction) ✅

### Error message contracts
- Missing anchor: `"extract_section_fence_aware: %s: not found in %s"` — contains "not found" ✅
- Empty region: `"extract_section_fence_aware: %s: anchor located but region contains no content lines"` — does NOT contain "not found" ✅
- Both include function-name prefix and anchor value ✅

### Scope
- Only the three specified target files modified ✅
- No extra functions, files, or features added ✅
- Bash 3.2 portability: implementation uses only `[ ]`, local variables, awk ✅
