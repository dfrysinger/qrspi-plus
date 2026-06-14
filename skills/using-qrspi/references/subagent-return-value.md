**Subagent return value (brief).** After writing per-finding files, the reviewer subagent returns a single brief summary string to main chat. The summary MUST NOT include the finding text — main chat reads the files when it needs the details. Required summary form:

```
Round NN {reviewer-tag} review complete.
Findings: N (high=X, medium=Y, low=Z)
Auto-apply: A | Paused: P
Written to: reviews/{step}/round-NN/
```

This brevity is load-bearing: cache-read savings across subsequent main-chat turns depend on the return text being ~30 tokens, not 3K-30K.
