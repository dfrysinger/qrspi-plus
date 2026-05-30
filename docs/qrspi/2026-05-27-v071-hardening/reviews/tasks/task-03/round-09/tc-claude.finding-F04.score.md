score: 75
reason: Both issues are confirmed in the code: (A) `|| true` masks function failures and prevents regression detection for normal extraction correctness; (B) symlink at `/tmp/skill-md-fence-signal-$$` is cleaned up in test body, not teardown, creating a resource leak if the test aborts mid-execution—both are real problems that impact test reliability and security verification.
