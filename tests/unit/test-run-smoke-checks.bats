#!/usr/bin/env bats

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
  TMP_DIR="$(mktemp -d)"
  export TMP_DIR

  # Start a tiny Node test server in the background to fixture against.
  cat > "$TMP_DIR/server.mjs" <<'EOF'
import { createServer } from 'node:http';
const server = createServer((req, res) => {
  if (req.url === '/ok') {
    res.writeHead(200, { 'content-type': 'text/html' });
    res.end('<html><head><link rel="stylesheet" href="/globals.css"/></head><body>Hello World</body></html>');
  } else if (req.url === '/redirect') {
    res.writeHead(302, { 'location': '/ok' });
    res.end();
  } else if (req.url === '/protected') {
    const cookie = req.headers.cookie ?? '';
    if (cookie.includes('test-session=valid')) {
      res.writeHead(200, { 'content-type': 'text/plain' });
      res.end('admin area');
    } else {
      res.writeHead(401, { 'content-type': 'text/plain' });
      res.end('unauthorized');
    }
  } else {
    res.writeHead(404);
    res.end();
  }
});
server.listen(0, () => {
  console.log(server.address().port);
});
EOF

  # Boot it and capture the port.
  node "$TMP_DIR/server.mjs" > "$TMP_DIR/port.txt" &
  SERVER_PID=$!
  export SERVER_PID
  # Wait briefly for port output.
  for i in 1 2 3 4 5 6 7 8 9 10; do
    if [ -s "$TMP_DIR/port.txt" ]; then break; fi
    sleep 0.1
  done
  PORT="$(cat "$TMP_DIR/port.txt")"
  export PORT
  export BASE_URL="http://localhost:$PORT"
}

teardown_file() {
  if [ -n "${SERVER_PID:-}" ]; then
    kill "$SERVER_PID" 2>/dev/null || true
  fi
  rm -rf "$TMP_DIR"
}

@test "exits 0 when all smoke checks pass" {
  cat > "$TMP_DIR/task.md" <<EOF
# Task: example

\`\`\`yaml
smoke_checks:
  - path: /ok
    auth: none
    expect_status: 200
    expect_body_contains:
      - "Hello World"
    expect_link_href_pattern: "globals\\\\.css"
\`\`\`
EOF
  run node "$REPO_ROOT/scripts/run-smoke-checks.mjs" --task-spec "$TMP_DIR/task.md" --base-url "$BASE_URL"
  [ "$status" -eq 0 ]
}

@test "exits 1 when a status assertion fails" {
  cat > "$TMP_DIR/task.md" <<EOF
\`\`\`yaml
smoke_checks:
  - path: /ok
    auth: none
    expect_status: 500
\`\`\`
EOF
  run node "$REPO_ROOT/scripts/run-smoke-checks.mjs" --task-spec "$TMP_DIR/task.md" --base-url "$BASE_URL"
  [ "$status" -eq 1 ]
}

@test "exits 1 when expect_body_contains is missing from response" {
  cat > "$TMP_DIR/task.md" <<EOF
\`\`\`yaml
smoke_checks:
  - path: /ok
    auth: none
    expect_status: 200
    expect_body_contains:
      - "Goodbye"
\`\`\`
EOF
  run node "$REPO_ROOT/scripts/run-smoke-checks.mjs" --task-spec "$TMP_DIR/task.md" --base-url "$BASE_URL"
  [ "$status" -eq 1 ]
}

@test "follows expect_location on a 302" {
  cat > "$TMP_DIR/task.md" <<EOF
\`\`\`yaml
smoke_checks:
  - path: /redirect
    auth: none
    expect_status: 302
    expect_location: /ok
\`\`\`
EOF
  run node "$REPO_ROOT/scripts/run-smoke-checks.mjs" --task-spec "$TMP_DIR/task.md" --base-url "$BASE_URL"
  [ "$status" -eq 0 ]
}

@test "uses smoke_auth cookie for auth: signed-in" {
  cat > "$TMP_DIR/task.md" <<EOF
\`\`\`yaml
smoke_auth:
  cookie_name: test-session
  cookie_value: valid
smoke_checks:
  - path: /protected
    auth: signed-in
    expect_status: 200
    expect_body_contains:
      - "admin area"
\`\`\`
EOF
  run node "$REPO_ROOT/scripts/run-smoke-checks.mjs" --task-spec "$TMP_DIR/task.md" --base-url "$BASE_URL"
  [ "$status" -eq 0 ]
}

@test "fails loudly when auth: signed-in is declared but smoke_auth is missing" {
  cat > "$TMP_DIR/task.md" <<EOF
\`\`\`yaml
smoke_checks:
  - path: /protected
    auth: signed-in
    expect_status: 200
\`\`\`
EOF
  run node "$REPO_ROOT/scripts/run-smoke-checks.mjs" --task-spec "$TMP_DIR/task.md" --base-url "$BASE_URL"
  [ "$status" -eq 1 ]
  [[ "$output" =~ smoke_auth ]]
}

@test "exits 1 when no smoke_checks block found" {
  cat > "$TMP_DIR/task.md" <<EOF
# A task with no smoke checks.
EOF
  run node "$REPO_ROOT/scripts/run-smoke-checks.mjs" --task-spec "$TMP_DIR/task.md" --base-url "$BASE_URL"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "no smoke_checks" ]]
}
