---
finding_id: F01
severity: medium
change_type: security
referenced_files:
  - scripts/dispatch-agent.sh
---

Path-string injection at the prompt-emission boundary. emit_untrusted_artifact
and the surrounding scalar emitters substitute raw repo-relative path strings
into the prompt skeleton via `id=%s`, `diff_file_path: %s`, `round_subdir: %s`.
Boundary checks (assert_path_under_repo_root) accept any in-repo path,
including paths whose filenames contain embedded newline or wrapper-marker
substrings (Unix permits both). Such a path, on emission, would synthesize
structural lines that escape the surrounding untrusted-data carve-outs.

Closed in fix-cycle 10 (commit 4ec927b): added reject_if_path_unsafe_for_emission
and applied it to every raw path arg (--subject-code, --task-def, --companion,
--diff-file) before the boundary check fires. Regression test added.
