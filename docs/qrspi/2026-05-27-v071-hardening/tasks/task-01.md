---
status: approved
task: 1
phase: 1
pipeline: full
goal_ids: [G1]
task_type: code
model: sonnet
---

# Task 1: Rewrite control-char detection to POSIX-clean function in third-party LLM dispatcher

- **Target files:** `scripts/run-third-party-llm.sh` (modify), `tests/unit/test-run-third-party-llm.bats` (modify)
- **Dependencies:** none
- **LOC estimate:** ~90
- **Description:** The control-char detection routine inside the `openai-chat-completions` security pre-flight block is replaced by a dedicated internal helper function that is POSIX-clean and produces correct results on BSD grep (macOS system grep without PCRE). The replacement catches all 33 control bytes -- the 32 C0 characters (0x00-0x1F) plus DEL (0x7F) -- including LF, which the prior `grep -qP` pattern missed silently. The current `2>/dev/null` suppression that caused the detection to become a no-op when grep lacks `-P` support is eliminated. Every header name and every header value is screened before any network call; any control-character match causes the script to abort with the existing die-path diagnostic naming the offending provider and (for all non-NUL bytes) the header name. NUL bytes are carved out from the header-name requirement because bash strips NUL at variable-assignment time, so the implementation must detect NUL via a file-scope pre-flight scan that runs before the awk parse — at that point the offending header name is not extractable from the bash variable space. For NUL the diagnostic names the provider and identifies the failure class ("contains NUL bytes in header configuration") but not the specific header name. Extended test coverage pins each of the 33 control bytes as a die-path trigger and adds an explicit LF regression guard that would have caught the prior false-negative. The shell-pipeline transport path for Codex dispatch has no configurable `default_headers` surface and is therefore out of scope for this task. Dispatch order: test-writer first, implementer second (RED-verification gate between).
- **Test expectations:**
  - Every C0 control byte (0x00 through 0x1F) supplied as a header value causes the script to exit before reaching any network dispatch call
  - Every C0 control byte supplied as a header name causes the script to exit before reaching any network dispatch call
  - DEL (0x7F) in a header value causes the script to exit before any network dispatch
  - DEL (0x7F) in a header NAME (not just value) causes the script to exit before any network dispatch
  - LF (0x0A / 0x0a) in a header value causes the script to exit -- this is the explicit regression guard for the prior grep gap where LF was silently missed because it is grep's record delimiter
  - NUL (0x00) in a header value causes exit, not a silent skip or binary-mode false negative
  - An empty header name and an empty header value do not trigger the die path (no false positive on empty input)
  - A header containing only printable ASCII characters (0x20 through 0x7E) does not trigger the die path and allows execution to continue
  - A header value containing printable text immediately followed by a control byte (e.g., a value composed of printable ASCII then CR or LF then more printable text, representing a canonical header-injection payload) causes the script to exit before any network dispatch
  - A header NAME containing printable ASCII immediately followed by a control byte then more printable ASCII (canonical name-side injection payload like `Header-Name\r\nInjected`) causes the script to exit before any network dispatch
  - The `_control_char_check` helper is implemented without any `grep -P` invocation (structural code-pattern assertion)
  - For all non-NUL control-byte detections, the die message identifies the offending provider and header name, matching the existing message format. For NUL specifically, the die message identifies the offending provider and the failure class but not the header name, because bash strips NUL at variable-assignment so the header name is not extractable from the file-scope pre-flight scan that must run before the awk parse.
