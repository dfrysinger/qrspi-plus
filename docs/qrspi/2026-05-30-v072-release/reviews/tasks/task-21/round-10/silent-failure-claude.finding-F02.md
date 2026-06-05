---
finding_id: F02
severity: medium
change_type: silent_failure
referenced_files:
  - scripts/dispatch-companion.sh
---

Job-record line-injection guard skips post-canonicalization _canon_round_dir.
The newline/CR check at launch time validates the RAW --round-dir arg;
the value WRITTEN to the job record is _canon_round_dir (realpath
result). realpath returns whatever bytes the on-disk path contains,
including \n/\r in directory names that exist on the filesystem (POSIX
permits any byte except / and NUL). Symlink-to-newline-named-dir attack
chain bypasses the launch guard.

Fix: re-run \n/\r rejection on _canon_round_dir after canonicalization,
before the printf into the job record.
