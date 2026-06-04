---
reviewer_tag: spec-claude
round: 7
verdict: CLEAN
---

# T21 R7 spec-claude — CLEAN

All 7 DoD items pass:
1. Out-of-repo path rejection (assert_path_under_repo_root on all prompt-ingested families)
2. Symlink canonical-target check before emission (no <<<AGENT-BODY-END>>> leak)
3. Readable out-of-repo --companion rejected by boundary, not missing-file
4. All four path families guarded (subject-code, artifact-body, companion, diff-file)
5. Canonicalization failures fail closed; no cat before guards (sentinel absent on QRSPI_REPO_ROOT override)
6. agents/qrspi-implementer.md Orchestrator-Only Scripts allowlist present (L9–44)
7. dispatch-companion.sh audited (launch:--prompt-file L634, launch:--round-dir L647; stdin-only legacy form documented L45–58)

All round-06 findings resolved: ID-hygiene (G16 tokens stripped), batch _validate_job_id gap closed, stale L613 citation removed, mkdir-before-assert ordering, canonical round_dir storage, no unreachable "" arm.

Round-07 changes minimally scoped — every diff line traceable to a closed R5 or R6 finding.
