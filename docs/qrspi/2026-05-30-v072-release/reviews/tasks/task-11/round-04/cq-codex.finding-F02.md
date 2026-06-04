---
finding_id: R4-F02
reviewer: cq-codex
severity: med
change_type: style
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats
---

# F02 — R4 Group I fix was incomplete: T11 references stripped from @test names but NOT from section header comments

**Verified on disk** (lines 2206-2217 and 2375-2400):

The R4 implementer's Group I fix correctly stripped `T11 ` prefixes from the AC1-AC5 `@test "..."` descriptors. But the section header comments above each AC block were NOT updated:

```
2206: # T11: dispatch-manifest provenance schema
2207: #
2208: # These three tests drive the dispatch_spec / mode / status / agent / job_id
2209: # / await_cmd / split_cmd fields required by the CD-1 dispatch-manifest
2210: # schema (structure.md §10).

2213: # T11 AC1 — third-party entry: nested dispatch_spec with all T11 provenance
2214: # fields plus background job metadata ...

2375: # T11 AC3 — append safety: ...
```

Similar comment headers persist before AC2, AC4, AC5, and the new AC6 block.

Per the split-rule surface of the ID-hygiene policy (test/code comments are subject to remediation, not just strict @test names / runtime strings), these section headers are in scope.

**Out-of-scope reminder:** the pre-existing `T7 / TE1`-style references throughout this file (lines 276-906+) were explicitly deferred to v0.7.3 backlog in R3 cq-claude F03's note — those are NOT this finding. F02 is specifically about T11-introduced section comments inside the new dispatch-manifest test block.

**Fix:** replace section headers with behavior descriptions:

```diff
-# T11: dispatch-manifest provenance schema
+# dispatch-manifest provenance schema
 #
 # These three tests drive the dispatch_spec / mode / status / agent / job_id
-# / await_cmd / split_cmd fields required by the CD-1 dispatch-manifest
-# schema (structure.md §10).
+# / await_cmd / split_cmd fields in the dispatch-manifest provenance schema.

-# T11 AC1 — third-party entry: nested dispatch_spec with all T11 provenance
+# AC1 — third-party entry: nested dispatch_spec with all provenance
 # fields plus background job metadata...

-# T11 AC3 — append safety: ...
+# AC3 — append safety: ...
```
