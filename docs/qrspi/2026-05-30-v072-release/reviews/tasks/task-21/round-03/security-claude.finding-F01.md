---
finding_id: F01
reviewer: security-claude
severity: medium
change_type: correctness
referenced_files: [scripts/dispatch-agent.sh:942-944, scripts/dispatch-agent.sh:1087-1090]
---
**Skill paths missing assert_path_under_repo_root.** Same as sf-claude F02. Path-traversal via agent `skills:` frontmatter cats out-of-repo file into LLM prompt. ACT.
