---
score: 85
change_type: correctness
verdict: real
reason: mktemp failure is unchecked on line 240; when mktemp fails, signal_tmp becomes empty and downstream awk errors produce misleading diagnostics instead of identifying the root cause. The bug is real (filesystem failures happen), introduced in this task's code, and verified in practice—none of the three existing tests exercise mktemp failure because they all use real mktemp which succeeds.
---
