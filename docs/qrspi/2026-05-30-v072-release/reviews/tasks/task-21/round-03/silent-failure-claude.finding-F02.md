---
finding_id: F02
reviewer: silent-failure-claude
severity: high
change_type: correctness
referenced_files: [scripts/dispatch-agent.sh:937-944, scripts/dispatch-agent.sh:1087-1091]
---
**Skill paths from agent frontmatter `skills:` bypass boundary guard.** `extract_skill_names` AWK doesn't strip `/.`, so `skills: [../../outside]` resolves to outside-repo SKILL.md and `strip_frontmatter` cats into LLM prompt. Spec line 19 violation. Fix: add `assert_path_under_repo_root "skill[$skill_name]" "$skill_path"` after assert_file_exists in skill-loading loop. Convergent with sec-claude F01.
