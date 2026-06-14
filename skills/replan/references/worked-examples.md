## Worked Example — Good (Minor)

Phase 1 completed. Replan subagent analyzes the phase:

```markdown
## Replan Analysis — Phase 1 Complete

### Change 1: Extra edge case test for Task 7
- **What:** Task 7 (notification delivery) needs a test for empty notification body
- **Why:** Phase 1 revealed that the notification renderer crashes on empty body — edge case not in original spec
- **Severity:** Minor — task spec wording update, no structural changes
- **Action:** Add test expectation to tasks/task-07.md

### Change 2: LOC estimate update for Task 8
- **What:** Task 8 LOC estimate should be ~400 not ~250
- **Why:** The auth middleware discovered in Phase 1 requires more boilerplate than estimated
- **Severity:** Minor — LOC estimate adjustment only
- **Action:** Update LOC estimate in tasks/task-08.md

### Change 3: Split Task 9 into 9a and 9b
- **What:** Task 9 (user profile CRUD) should split into 9a (read/list) and 9b (create/update/delete)
- **Why:** Phase 1 showed the validation layer is more complex than expected — splitting keeps tasks under 300 LOC
- **Severity:** Minor — task split within existing slice, no structural changes
- **Action:** Split tasks/task-09.md into tasks/task-09a.md and tasks/task-09b.md, update plan.md task list
```

**Result:** All changes are minor. Update `tasks/*.md` and `plan.md` in place, set `status: replan-draft`, present diffs to user. User re-approves, set `status: approved`, commit. Snapshot Phase 1 and promote (which deletes `structure.md`/`plan.md`/`tasks/` and resets goals/research/design to draft). Delete `replan-pending.md`. Invoke Goals to restart the pipeline for Phase 2.

## Worked Example — Good (Major)

Phase 1 completed. Replan subagent analyzes the phase:

```markdown
## Replan Analysis — Phase 1 Complete

### Change 1: Switch from polling to WebSockets for real-time updates
- **What:** The notification system uses polling (design.md specifies 5-second interval), but Phase 1 revealed this causes unacceptable latency for the chat feature in Phase 2
- **Why:** Chat messages delivered with 0-5 second delay breaks the UX. WebSockets provide sub-100ms delivery.
- **Severity:** Major — technology choice change affects architecture
- **Loop-back target:** Design (architecture change)

### Change 2: Extra edge case test for Task 7
- **What:** Task 7 needs a test for empty notification body
- **Why:** Phase 1 revealed the renderer crashes on empty body
- **Severity:** Minor — task spec wording update
```

**Result:** One major change present. Loop-back target is Design (earliest affected artifact).

Write feedback file:

```markdown
# feedback/replan-phase-01-round-01.md

## Phase 1 Learnings

### WebSocket requirement
- Polling at 5-second intervals causes 0-5s latency for chat messages
- Chat UX requires sub-100ms delivery
- Proposed change: replace polling with WebSocket connections for real-time features
- Affects: design.md (architecture), structure.md (new WebSocket server file), plan.md (task dependencies)

### Minor changes (incorporated by Plan during cascade)
- Task 7: add empty body edge case test
```

Reset `design.md`, `structure.md`, `plan.md`, all `tasks/task-NN.md`, and `parallelization.md` to `status: draft`. Delete `replan-pending.md`. Recommend compaction. Invoke `qrspi:design` with normal inputs + `feedback/replan-phase-01-round-01.md`. Replan exits.

Normal pipeline takes over: Design re-reviews (incorporating WebSocket requirement + minor Task 7 change from feedback) → Structure → Plan (incorporates the Task 7 edge case test when re-producing task specs) → Parallelize → Implement → Phase 2 begins.

## Worked Example — Bad

```markdown
## Replan Analysis — Phase 1 Complete

Some things need to change for Phase 2. The notification system should probably use WebSockets instead of polling. Also Task 8 might need splitting. Updated tasks/task-08.md and plan.md with the changes.
```

**Why this fails:** missing per-change severity classifications; an unclassified Major change ("WebSockets") with no loop-back target identified; changes applied to artifacts without user approval (HARD-GATE violation); no feedback file for the Major change; lumped narrative instead of per-change structure.
