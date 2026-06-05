---
reviewer: test-coverage-claude
finding_id: F03
severity: medium
change_type: correctness
references:
  - tools/build-plugin.mjs#L91-L108
  - tools/build-plugin.mjs#L314-L317
  - tools/build-plugin.mjs#L419-L423
  - tests/unit/test-build-gate.bats
---

# F03 — `SECRET_BASENAME_PATTERNS` denylist is production-code defense-in-depth that is never exercised by tests

## Observation

`tools/build-plugin.mjs` ships a non-trivial defense-in-depth surface:
the `SECRET_BASENAME_PATTERNS` list (lines 91–101) plus its
`isSecretBasename()` checker (lines 103–108), wired into both the
recursive walk (lines 314–317) and the top-level manifest-files copy
(lines 419–423). The walk fail-louds with:

```
${rel}: refused — basename matches secret/backup denylist
```

The patterns cover `.env*`, `.envrc`, `.npmrc`, `.netrc`, SSH keys,
credentials, `*.pem`/`*.key`/`*.p12`/`*.pfx`, backup suffixes
(`.bak`/`.orig`/`.rej`/`.swp`/`.swo`), and editor `~`-suffix files.

**No test in the suite exercises this path.** Searches across
`tests/unit/test-build-gate.bats` and the acceptance suites turn up
zero fixtures that stage a `.env`, `id_rsa`, or `*.bak` file under a
manifest dir and assert the build fails with the denylist diagnostic.

The two production-code call sites (recurseDir vs copyManifest top-
level) also have **distinct error messages** — the walk site says
"basename matches secret/backup denylist (.env / *.pem / *.key / id_rsa
/ *.bak / *~ / *.swp / etc.)" while the top-level site says
"basename matches secret/backup denylist". An untested branch can
diverge silently.

## Impact

- Any regression that breaks the regex set (e.g., a future refactor
  flipping the polarity of `isSecretBasename`, dropping a pattern, or
  applying the check only to `.md` files) ships unnoticed. The whole
  point of the denylist is contributor-mistake protection; an unused
  denylist is a false sense of security.
- The two call sites can drift out of sync without any test catching it.
- Per the production-code comment ("Catches the 'contributor accidentally
  checks in `.env` under scripts/' mistake path that the manifest alone
  wouldn't stop"), the denylist is the **only** line of defense — the
  manifest allows scripts/, so the denylist is what actually keeps
  scripts/.env out of build/.

## Suggested remediation

Add fail-loud unit tests for at least three categories of denylist
hit, exercising both call sites:

```bats
@test "[T39/G32] fail-loud: .env file under a manifest dir is rejected" {
  local root="$BATS_TEST_TMPDIR/secret-env"
  _t39_stage_root "$root" "# clean"$'\n'
  printf 'TOKEN=hunter2\n' > "$root/scripts/.env"
  run _t39_run_build "$root"
  [ "$status" -ne 0 ]
  echo "$output" | grep -F 'scripts/.env'
  echo "$output" | grep -E -i 'denylist|secret'
  # Ensure the secret never reached build/.
  [ ! -f "$root/build/scripts/.env" ]
}

@test "[T39/G32] fail-loud: id_rsa under a manifest dir is rejected" {
  local root="$BATS_TEST_TMPDIR/secret-id-rsa"
  _t39_stage_root "$root" "# clean"$'\n'
  printf 'PRIVATE KEY\n' > "$root/scripts/id_rsa"
  run _t39_run_build "$root"
  [ "$status" -ne 0 ]
  echo "$output" | grep -F 'id_rsa'
}

@test "[T39/G32] fail-loud: *.bak / *~ editor backup rejected" {
  local root="$BATS_TEST_TMPDIR/secret-backup"
  _t39_stage_root "$root" "# clean"$'\n'
  printf 'OLD\n' > "$root/scripts/helper.sh.bak"
  run _t39_run_build "$root"
  [ "$status" -ne 0 ]
  echo "$output" | grep -F 'helper.sh.bak'
}
```

Also worth a top-level call-site test (a `LICENSE.bak` in repo root)
to pin the second invocation site at lines 419–423.
