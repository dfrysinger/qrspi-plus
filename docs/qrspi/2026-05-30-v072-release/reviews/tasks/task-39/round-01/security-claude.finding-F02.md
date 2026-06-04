# F02 — Strip-list is a name-allowlist; secret files outside the listed names ship to `build/`

**Severity:** Medium
**Category:** Data Exposure / Secret Leakage
**Location:** `tools/build-plugin.mjs:60–91` (`STRIP_TOPLEVEL`, `shouldStripRel`)

## Finding

`shouldStripRel` excludes content from the shipped `build/` tree using a
**closed set of exact top-level names** (`STRIP_TOPLEVEL`, line 60) plus
two special cases (`.claude-plugin/marketplace.json` and any `.DS_Store`).
Anything not in that set is copied verbatim into `build/`, which is
committed, pushed to `main`, and pointed at by `marketplace.json`'s
`source: ./build` field as the install root every plugin consumer
materializes.

The list does not strip well-known secret-bearing patterns:

- Top-level dotfiles other than the six listed: `.env`, `.envrc`,
  `.npmrc`, `.netrc`, `.aws/`, `.ssh/`, `.docker/`, `.cache/`,
  `.direnv/`, `.python-version` etc.
- Conventional secret files at any depth: `credentials.json`,
  `*.pem`, `*.key`, `id_rsa`, `*.p12`, `service-account*.json`,
  `.env.local`.
- Backup/swap files dropped by editors: `*.bak`, `*~`, `*.swp`,
  `*.orig`, `*.rej` — these can contain pre-edit secrets or
  conflict-merged credentials.
- *Nested* occurrences of the listed names. `STRIP_TOPLEVEL` only
  matches when `segs.length === 1` (line 87). A directory named
  `tests/` under `skills/` (`skills/foo/tests/`) is **not** stripped —
  if a contributor checks fixtures with embedded test secrets there,
  they ship.

## Attack scenario

1. Contributor working on a feature locally uses `direnv` / `dotenv` and
   runs `node tools/build-plugin.mjs` from a worktree where `.env`
   contains an Anthropic API key, GitHub PAT, or signing key.
2. The build copies `.env` into `build/.env` (it is not in
   `STRIP_TOPLEVEL`, it is not under a stripped dir).
3. The CI build-sync gate (`git diff --exit-code build/`, workflow
   line 133) **passes** on the PR — the gate enforces that
   `build/` matches the resolver's output, which it does, including
   the leaked file. There is no positive denylist on the *content* of
   `build/`.
4. The PR merges. `build/` is the published install tree (marketplace
   `source: ./build`); every Claude plugin consumer that installs the
   marketplace package fetches the secret. Public Git history retains
   it indefinitely; rotation requires invalidating the credential at
   the issuer.

Variants:
- An attacker who lands a PR adding a shipped `.npmrc` with an
  attacker-controlled `_authToken` URL can poison plugin-consumer
  npm fetches if any downstream tooling uses `npm` from inside the
  installed tree.
- A `.bak` file from an interrupted edit of a config containing
  embedded credentials slips through silently.

## Why this is exploitable in practice

- The build runs locally on contributor machines; the contributor's
  home-directory ergonomics (dotenv, IDE backups) bleed into the
  worktree routinely.
- `git status` clean ≠ tracked-only — a contributor who **does**
  `git add .env` (or whose pre-commit doesn't catch it) gets the
  file into the source tree and then into `build/`.
- `.gitignore` is in the strip list, but `.gitignore` only governs
  *tracking*, not what `build-plugin.mjs` copies once a file is
  tracked.
- The CI gate enforces *consistency*, not *content safety*.

## Recommended fix

Switch from a fixed name-allowlist to either:

1. **Manifest-driven copy.** Task-39 §Definition of done already
   specifies the runtime include list: `scripts/`, `templates/`,
   `LICENSE`, `README.md`, optional `AGENTS.md`/`CLAUDE.md`, and
   `.claude-plugin/`. Walk *those* explicitly instead of walking
   the whole repo and subtracting strip names. This is the
   recommended posture for a "ship only what's listed" build and
   eliminates the entire class of accidental-leak.
2. **Defense-in-depth denylist** in addition to the current logic:
   reject (fail-loud) any file in the walk whose basename matches
   `/^\.(env|envrc|npmrc|netrc)$/`, `/\.(pem|key|p12|pfx)$/i`,
   `id_(rsa|ed25519|ecdsa)`, `*.bak`, `*~`, `*.swp`, etc. A
   diagnostic like `<rel>: refused — looks like a secret/backup
   file (denylisted basename)` keeps with the fail-loud style.

Option (1) is the structural fix; option (2) catches the
contributor-mistake path even if the manifest grows.
