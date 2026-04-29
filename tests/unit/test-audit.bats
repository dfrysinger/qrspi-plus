#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

setup() {
  export TEST_ROOT
  TEST_ROOT=$(mktemp -d)
  cd "$TEST_ROOT"

  # Fake repo layout: artifact dir + worktree
  mkdir -p "docs/qrspi/2026-04-26-fakeproj"
  mkdir -p ".worktrees/fakeproj/task-02/src"
  mkdir -p ".worktrees/fakeproj/baseline"

  source "$(cd "$BATS_TEST_DIRNAME/../.." && pwd)/hooks/lib/worktree.sh"
  source "$(cd "$BATS_TEST_DIRNAME/../.." && pwd)/hooks/lib/audit.sh"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

# ── audit_resolve_artifact_dir ────────────────────────────────────

@test "resolve: single matching slug → returns absolute path" {
  result=$(audit_resolve_artifact_dir "fakeproj")
  [[ "$result" == *"docs/qrspi/2026-04-26-fakeproj" ]]
}

@test "resolve: zero matches → returns nonzero" {
  run audit_resolve_artifact_dir "no-such-slug"
  [ "$status" -ne 0 ]
}

@test "resolve: multiple matches → returns nonzero" {
  mkdir -p "docs/qrspi/2026-05-01-fakeproj"
  run audit_resolve_artifact_dir "fakeproj"
  [ "$status" -ne 0 ]
}

@test "[Important #1] resolve: zero matches → silent (no stderr)" {
  run --separate-stderr audit_resolve_artifact_dir "no-such-slug"
  [ "$status" -ne 0 ]
  [ -z "$stderr" ]
}

@test "[Important #1] resolve: ambiguous slug → fail-loud diagnostic on stderr" {
  mkdir -p "docs/qrspi/2026-05-01-fakeproj"
  run --separate-stderr audit_resolve_artifact_dir "fakeproj"
  [ "$status" -ne 0 ]
  [[ "$stderr" == *"ambiguous"* ]]
  [[ "$stderr" == *"fakeproj"* ]]
}

@test "[Important #1] resolve: ambiguous slug stderr names both directories" {
  mkdir -p "docs/qrspi/2026-05-01-fakeproj"
  run --separate-stderr audit_resolve_artifact_dir "fakeproj"
  [[ "$stderr" == *"2026-04-26-fakeproj"* ]]
  [[ "$stderr" == *"2026-05-01-fakeproj"* ]]
}

@test "[Important #1+3] integration: diagnostic propagates through audit_log_event call chain" {
  # Proves Item C delivers on its premise: when audit_resolve_artifact_dir
  # writes a diagnostic, audit_log_event must NOT swallow it. Otherwise the
  # 2>/dev/null drop in pre-tool-use's block()/allow() is theater.
  mkdir -p "docs/qrspi/2026-05-01-fakeproj"
  local target="$TEST_ROOT/.worktrees/fakeproj/task-02/src/foo.ts"
  local envelope='{"agent_id":"sub-1","tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  run --separate-stderr audit_log_event "$envelope" "allow" ""
  [[ "$stderr" == *"ambiguous"* ]]
  [[ "$stderr" == *"fakeproj"* ]]
}

# ── audit_log_event ───────────────────────────────────────────────

@test "[F-19] log: subagent Edit inside task-07a worktree audits to artifact_dir" {
  # Pins the cross-file regex invariant: pre-tool-use accepts task-07a, AND
  # worktree_extract_slug must too — otherwise audit silently drops the row
  # (Codex round-2 finding; was missed by both Claude reviewers).
  mkdir -p "$TEST_ROOT/.worktrees/fakeproj/task-07a/src"
  local target="$TEST_ROOT/.worktrees/fakeproj/task-07a/src/foo.ts"
  local envelope='{"agent_id":"sub-1","agent_type":"implementer","tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  run audit_log_event "$envelope" "allow" ""
  [ "$status" -eq 0 ]

  local audit_file="$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj/.qrspi/audit.jsonl"
  [ -f "$audit_file" ]
  [[ "$(cat "$audit_file")" == *"task-07a"* ]]
}

@test "[F-19] log: subagent Bash detected write under task-07b audits to artifact_dir" {
  mkdir -p "$TEST_ROOT/.worktrees/fakeproj/task-07b"
  local target="$TEST_ROOT/.worktrees/fakeproj/task-07b/build.log"
  local envelope='{"agent_id":"sub-1","agent_type":"implementer","tool_name":"Bash","tool_input":{"command":"echo done > '"$target"'"}}'

  run audit_log_event "$envelope" "allow" ""
  [ "$status" -eq 0 ]

  local audit_file="$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj/.qrspi/audit.jsonl"
  [ -f "$audit_file" ]
  [[ "$(cat "$audit_file")" == *"task-07b"* ]]
}

@test "log: subagent Edit inside worktree writes line to artifact_dir audit.jsonl" {
  local target="$TEST_ROOT/.worktrees/fakeproj/task-02/src/foo.ts"
  local envelope='{"agent_id":"sub-1","agent_type":"implementer","tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  run audit_log_event "$envelope" "allow" ""
  [ "$status" -eq 0 ]

  local audit_file="$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj/.qrspi/audit.jsonl"
  [ -f "$audit_file" ]

  local line
  line=$(cat "$audit_file")
  [[ "$line" == *"\"tool\":\"Edit\""* ]]
  [[ "$line" == *"\"outcome\":\"allow\""* ]]
  [[ "$line" == *"\"agent_id\":\"sub-1\""* ]]
  [[ "$line" == *"\"target\":\"$target\""* ]]
}

@test "log: main chat Edit on artifact_dir file writes audit line" {
  local target="$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj/goals.md"
  local envelope='{"tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  run audit_log_event "$envelope" "allow" ""
  [ "$status" -eq 0 ]

  local audit_file="$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj/.qrspi/audit.jsonl"
  [ -f "$audit_file" ]
}

@test "log: target outside QRSPI scope → no audit, return 0" {
  local target="$TEST_ROOT/some/random/file.ts"
  mkdir -p "$TEST_ROOT/some/random"
  local envelope='{"tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  run audit_log_event "$envelope" "allow" ""
  [ "$status" -eq 0 ]

  # No audit file created anywhere
  [ ! -f "$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj/.qrspi/audit.jsonl" ]
}

@test "log: block outcome includes reason field" {
  local target="$TEST_ROOT/.worktrees/fakeproj/task-02/.qrspi/audit.jsonl"
  local envelope='{"agent_id":"sub-1","tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  run audit_log_event "$envelope" "block" "subagent cannot write artifact .qrspi"
  [ "$status" -eq 0 ]

  # Block was attempting to write a (non-QRSPI) target — but path string contains
  # ".worktrees/fakeproj/" so the slug resolves and the artifact_dir gets the line.
  local audit_file="$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj/.qrspi/audit.jsonl"
  [ -f "$audit_file" ]
  local line
  line=$(cat "$audit_file")
  [[ "$line" == *"\"outcome\":\"block\""* ]]
  [[ "$line" == *"\"reason\":\"subagent cannot write artifact .qrspi\""* ]]
}

@test "log: Bash with detected write target inside worktree audits" {
  local envelope='{"agent_id":"sub-1","tool_name":"Bash","tool_input":{"command":"echo hi > '"$TEST_ROOT"'/.worktrees/fakeproj/task-02/foo.txt"}}'

  run audit_log_event "$envelope" "allow" ""
  [ "$status" -eq 0 ]

  local audit_file="$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj/.qrspi/audit.jsonl"
  [ -f "$audit_file" ]
  local line
  line=$(cat "$audit_file")
  [[ "$line" == *"\"tool\":\"Bash\""* ]]
  [[ "$line" == *"\"command\":"* ]]
}

@test "log: Bash with no parseable target → no audit" {
  local envelope='{"agent_id":"sub-1","tool_name":"Bash","tool_input":{"command":"ls -la"}}'

  run audit_log_event "$envelope" "allow" ""
  [ "$status" -eq 0 ]

  [ ! -f "$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj/.qrspi/audit.jsonl" ]
}

# ── Worktree-CWD audit (S-N3 fix) ──────────────────────────────────

@test "log: subagent CWD inside worktree resolves artifact_dir via state.json fallback" {
  # Simulate CWD inside the worktree (the bug scenario): docs/qrspi/ is NOT
  # visible relative to PWD, so the local-glob resolver fails. State.json
  # at the parent repo root carries the canonical artifact_dir.
  local repo_root="$TEST_ROOT"
  local artifact_dir="$repo_root/docs/qrspi/2026-04-26-fakeproj"
  mkdir -p "$repo_root/.qrspi"
  printf '{"version":1,"artifact_dir":"%s"}\n' "$artifact_dir" > "$repo_root/.qrspi/state.json"

  cd "$repo_root/.worktrees/fakeproj/task-02"

  local target="$repo_root/.worktrees/fakeproj/task-02/src/foo.ts"
  local envelope='{"agent_id":"sub-1","agent_type":"implementer","tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  run audit_log_event "$envelope" "allow" ""
  [ "$status" -eq 0 ]

  local audit_file="$artifact_dir/.qrspi/audit.jsonl"
  [ -f "$audit_file" ]
  local line
  line=$(cat "$audit_file")
  [[ "$line" == *"\"agent_id\":\"sub-1\""* ]]
  [[ "$line" == *"\"target\":\"$target\""* ]]
}

@test "log: worktree-scope target with no resolvable artifact_dir → orphan log + nonzero" {
  # Worktree CWD, NO docs/qrspi/ glob match anywhere, NO state.json. Target is
  # clearly in QRSPI scope (worktree path) but neither resolver succeeds.
  # Expectation: row goes to <repo_root>/.qrspi/audit-orphan.jsonl and the
  # function returns non-zero so callers know the canonical path failed.
  local repo_root="$TEST_ROOT/orphan-repo"
  mkdir -p "$repo_root/.worktrees/lostproj/task-09"
  cd "$repo_root/.worktrees/lostproj/task-09"

  local target="$repo_root/.worktrees/lostproj/task-09/src/x.ts"
  local envelope='{"agent_id":"sub-9","tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  run audit_log_event "$envelope" "allow" ""
  [ "$status" -ne 0 ]

  local orphan_file="$repo_root/.qrspi/audit-orphan.jsonl"
  [ -f "$orphan_file" ]
  local line
  line=$(cat "$orphan_file")
  [[ "$line" == *"\"agent_id\":\"sub-9\""* ]]
  [[ "$line" == *"\"target\":\"$target\""* ]]
}

@test "log: state.json fallback preserves canonical audit.jsonl location even when local glob would also work" {
  # Sanity guard: when CWD has docs/qrspi/ AND state.json exists, the canonical
  # location wins (no regression for main-chat usage).
  local artifact_dir="$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj"
  mkdir -p "$TEST_ROOT/.qrspi"
  printf '{"version":1,"artifact_dir":"%s"}\n' "$artifact_dir" > "$TEST_ROOT/.qrspi/state.json"

  local target="$TEST_ROOT/.worktrees/fakeproj/task-02/src/y.ts"
  local envelope='{"agent_id":"sub-1","tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  run audit_log_event "$envelope" "allow" ""
  [ "$status" -eq 0 ]

  local audit_file="$artifact_dir/.qrspi/audit.jsonl"
  [ -f "$audit_file" ]
}

# ── Symlink hardening (S-3 + L-sec-2) ──────────────────────────────

@test "log: symlinked audit.jsonl → refused, returns nonzero, target untouched" {
  # An attacker plants a symlink at the audit-file path pointing outside the
  # artifact_dir (e.g. at a sibling workspace's state file). audit_log_event
  # must detect the symlink BEFORE append and fail closed rather than
  # dereferencing the write through the symlink.
  local artifact_dir="$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj"
  mkdir -p "$artifact_dir/.qrspi"
  local outside_target="$TEST_ROOT/outside-target.txt"
  : > "$outside_target"
  ln -s "$outside_target" "$artifact_dir/.qrspi/audit.jsonl"

  local target="$TEST_ROOT/.worktrees/fakeproj/task-02/src/foo.ts"
  local envelope='{"agent_id":"sub-1","tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  run audit_log_event "$envelope" "allow" ""
  [ "$status" -ne 0 ]

  # Outside symlink target must remain empty — function must not have
  # dereferenced the symlink.
  local outside_size
  outside_size=$(wc -c < "$outside_target" | tr -d '[:space:]')
  [ "$outside_size" = "0" ]
}

@test "log: symlinked .qrspi/ directory under artifact_dir → refused, returns nonzero" {
  # An attacker plants a symlink at <artifact_dir>/.qrspi -> /elsewhere/.qrspi
  # so any append would route into the attacker's directory. audit_log_event
  # must refuse and fail closed.
  local artifact_dir="$TEST_ROOT/docs/qrspi/2026-04-26-fakeproj"
  local attacker_dir="$TEST_ROOT/attacker-qrspi"
  mkdir -p "$attacker_dir"
  : > "$attacker_dir/audit.jsonl"
  # NB: artifact_dir already exists; just symlink .qrspi into the attacker dir.
  ln -s "$attacker_dir" "$artifact_dir/.qrspi"

  local target="$TEST_ROOT/.worktrees/fakeproj/task-02/src/foo.ts"
  local envelope='{"agent_id":"sub-1","tool_name":"Edit","tool_input":{"file_path":"'"$target"'"}}'

  run audit_log_event "$envelope" "allow" ""
  [ "$status" -ne 0 ]

  # Attacker file must remain empty — not appended to via symlinked .qrspi/.
  local attacker_size
  attacker_size=$(wc -c < "$attacker_dir/audit.jsonl" | tr -d '[:space:]')
  [ "$attacker_size" = "0" ]
}

@test "find_repo_root: symlinked .qrspi/ directory → not followed (CWE-59)" {
  # Plant a fake repo with a symlinked .qrspi/ directory pointing at another
  # repo's .qrspi/. _audit_find_repo_root walks via [[ -f ]] which would
  # otherwise follow the symlink and return the wrong repo root, allowing
  # audit rows to cross-write into the wrong repo's state.
  local victim_repo="$TEST_ROOT/victim-repo"
  local attacker_repo="$TEST_ROOT/attacker-repo"
  mkdir -p "$victim_repo/.qrspi"
  printf '{"version":1}\n' > "$victim_repo/.qrspi/state.json"
  mkdir -p "$attacker_repo"
  ln -s "$victim_repo/.qrspi" "$attacker_repo/.qrspi"

  # Walking from inside attacker-repo must NOT silently resolve to attacker_repo
  # (which would only "succeed" via the symlinked .qrspi/state.json).
  run _audit_find_repo_root "$attacker_repo"
  if [ "$status" -eq 0 ]; then
    # If resolver returns success, the resolved path MUST NOT be the attacker
    # path (which is only reachable via the symlink). It must be either the
    # canonical victim repo (if hardened with realpath) or some real ancestor
    # — never the attacker's planted symlink dir.
    [ "$output" != "$attacker_repo" ]
  fi
  # status -ne 0 is also acceptable (rejection-style hardening).
}

@test "find_repo_root: symlinked state.json file → not followed (CWE-59)" {
  # Plant a fake repo with a symlinked state.json pointing into another repo's
  # state.json. The walk must not silently resolve the attacker's repo via the
  # symlinked file.
  local victim_repo="$TEST_ROOT/victim-repo2"
  local attacker_repo="$TEST_ROOT/attacker-repo2"
  mkdir -p "$victim_repo/.qrspi"
  printf '{"version":1}\n' > "$victim_repo/.qrspi/state.json"
  mkdir -p "$attacker_repo/.qrspi"
  ln -s "$victim_repo/.qrspi/state.json" "$attacker_repo/.qrspi/state.json"

  run _audit_find_repo_root "$attacker_repo"
  if [ "$status" -eq 0 ]; then
    [ "$output" != "$attacker_repo" ]
  fi
}

@test "find_repo_root: canonical real .qrspi/state.json still resolves" {
  # Sanity guard: no regression on the canonical case.
  local repo_root="$TEST_ROOT/canon-repo"
  mkdir -p "$repo_root/.qrspi"
  printf '{"version":1}\n' > "$repo_root/.qrspi/state.json"

  run _audit_find_repo_root "$repo_root"
  [ "$status" -eq 0 ]
  [[ "$output" == *"canon-repo" ]]
}

# ── Sentinel preservation (M4-2: __OPAQUE_WRITE__ contract) ────────

@test "log: Bash with __OPAQUE_WRITE__ sentinel → target preserved verbatim (canonical path)" {
  # Cross-task contract (task-43 + task-44): when bash_detect_file_writes
  # returns the literal sentinel "__OPAQUE_WRITE__", audit_log_event MUST
  # preserve that sentinel verbatim in the audit row's `target` field. The
  # PWD-prepend branch (line ~196) must NOT fire and produce a fake in-
  # worktree path like `<pwd>/__OPAQUE_WRITE__` — that would defeat the
  # audit-trail compensating control by writing forensically misleading rows
  # at exactly the moments the wall fired.
  #
  # Canonical-path variant: state.json exists upstream, so the row lands in
  # the canonical artifact_dir/.qrspi/audit.jsonl.
  local repo_root="$TEST_ROOT"
  local artifact_dir="$repo_root/docs/qrspi/2026-04-26-fakeproj"
  mkdir -p "$repo_root/.qrspi"
  printf '{"version":1,"artifact_dir":"%s"}\n' "$artifact_dir" > "$repo_root/.qrspi/state.json"

  cd "$repo_root/.worktrees/fakeproj/task-02"

  # Inline interpreter triggers __OPAQUE_WRITE__ from bash_detect_file_writes.
  local cmd='python3 -c "open('"'"'/etc/passwd'"'"','"'"'w'"'"').write('"'"'x'"'"')"'
  local envelope
  envelope=$(jq -cn --arg cmd "$cmd" '{agent_id:"sub-1",agent_type:"implementer",tool_name:"Bash",tool_input:{command:$cmd}}')

  run audit_log_event "$envelope" "block" "opaque write blocked"
  [ "$status" -eq 0 ]

  local audit_file="$artifact_dir/.qrspi/audit.jsonl"
  [ -f "$audit_file" ]

  # Strong assertion: extract the target field via jq and require it to be
  # the literal sentinel — no PWD prefix, no path mangling.
  local target_field
  target_field=$(jq -r '.target' "$audit_file")
  [ "$target_field" = "__OPAQUE_WRITE__" ]
}

@test "log: Bash with __OPAQUE_WRITE__ sentinel → target preserved verbatim (orphan path)" {
  # Same contract on the orphan fallback branch: when no state.json exists
  # upstream of PWD, the orphan row in audit-orphan.jsonl must still record
  # the literal sentinel.
  local repo_root="$TEST_ROOT/orphan-repo-sentinel"
  mkdir -p "$repo_root/.worktrees/lostproj/task-09"
  cd "$repo_root/.worktrees/lostproj/task-09"

  local cmd='node -e "require('"'"'fs'"'"').writeFileSync('"'"'/tmp/x'"'"','"'"'y'"'"')"'
  local envelope
  envelope=$(jq -cn --arg cmd "$cmd" '{agent_id:"sub-9",tool_name:"Bash",tool_input:{command:$cmd}}')

  run audit_log_event "$envelope" "block" "opaque write blocked"
  # Orphan-path resolution failure is signalled by non-zero return.
  [ "$status" -ne 0 ]

  local orphan_file="$repo_root/.qrspi/audit-orphan.jsonl"
  [ -f "$orphan_file" ]

  local target_field
  target_field=$(jq -r '.target' "$orphan_file")
  [ "$target_field" = "__OPAQUE_WRITE__" ]
}

@test "log: Bash with ordinary relative target → PWD-prepend regression unchanged" {
  # Regression check: non-sentinel relative-path Bash writes must continue
  # to receive a PWD prefix in the audit row's target field. The sentinel
  # special-case must not break this branch.
  local repo_root="$TEST_ROOT"
  local artifact_dir="$repo_root/docs/qrspi/2026-04-26-fakeproj"
  mkdir -p "$repo_root/.qrspi"
  printf '{"version":1,"artifact_dir":"%s"}\n' "$artifact_dir" > "$repo_root/.qrspi/state.json"

  # CWD inside the worktree so that "foo.txt" is a worktree-scope target
  # after PWD-prepend (otherwise it would orphan-log).
  cd "$repo_root/.worktrees/fakeproj/task-02"

  local envelope='{"agent_id":"sub-1","tool_name":"Bash","tool_input":{"command":"echo hi > foo.txt"}}'

  run audit_log_event "$envelope" "allow" ""
  [ "$status" -eq 0 ]

  local audit_file="$artifact_dir/.qrspi/audit.jsonl"
  [ -f "$audit_file" ]

  local target_field
  target_field=$(jq -r '.target' "$audit_file")
  [ "$target_field" = "$repo_root/.worktrees/fakeproj/task-02/foo.txt" ]
}

# ── Structural meta-tests ─────────────────────────────────────────

@test "audit.sh uses set -euo pipefail" {
  grep -q "set -euo pipefail" "$BATS_TEST_DIRNAME/../../hooks/lib/audit.sh"
}

@test "audit.sh sources exactly worktree.sh and bash-detect.sh (intentional exception)" {
  # Other libs are self-contained per the structural rule. audit.sh is the
  # documented exception because it needs slug extraction and bash write detection.
  local sources
  sources=$(grep -E "^\s*source\s" "$BATS_TEST_DIRNAME/../../hooks/lib/audit.sh" | sed 's/.*\///' | sed 's/".*//' | sort)
  [ "$sources" = "$(printf 'bash-detect.sh\nworktree.sh')" ]
}
