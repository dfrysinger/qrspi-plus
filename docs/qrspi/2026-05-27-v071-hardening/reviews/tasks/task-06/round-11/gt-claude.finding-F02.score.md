score: 75
reason: TE14 dispatch-surface tests set COPILOT_CLI=1 without ensuring trusted gh is present; detect_host requires BOTH conditions, so tests will fail in CI environments lacking trusted gh (first test: [transport: task-tool] count=0; second test: passes wrongly because shell-pipeline path actually taken). Clear fix pattern demonstrated in F01 (test-codex-review-source-guard.bats).
