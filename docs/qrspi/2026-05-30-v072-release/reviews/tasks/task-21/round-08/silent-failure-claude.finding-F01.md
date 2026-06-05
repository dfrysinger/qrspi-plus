---
finding_id: R8-F01
severity: medium-low
change_type: correctness
referenced_files: [scripts/lib/path-guard.sh]
status: closed-cycle-9
---
assert_ancestor_under_repo_root used [ ! -e ] which follows symlinks. Broken
in-repo symlink → out-of-repo target was walked past, ancestor check passed
on a higher in-repo dir, mkdir -p followed symlink and created out-of-repo
subtree (defeating cycle-7 partial-state guard). Closed by 2202d83 via
[ ! -e "$probe" ] && [ ! -L "$probe" ] in walk loop. Regression test added.
