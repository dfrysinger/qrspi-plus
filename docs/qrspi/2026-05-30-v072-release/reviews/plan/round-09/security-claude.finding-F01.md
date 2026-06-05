---
finding_id: R9-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
message: |
  T08 (G19 Cite Check) makes verifier file-reads of attacker-controllable cited
  paths mandatory and quoted-content-comparing, but does not require a
  repo-boundary canonicalization guard on those paths — leaving an
  exfil-oracle surface that T21/T39 already establish the pattern for
  elsewhere.

  ## What T08 introduces

  plan.md L528 inserts a new verifier Step 3.5 Cite Check "using the G19
  wording for file-existence, line-range, quoted-content, and named-anchor
  checks." DoD L541-L545 makes this step mandatory for every finding that
  "actually makes" a cite, and requires the verifier to compare quoted
  content against the cited location's bytes (line ranges, quoted content,
  named anchors). The acceptance fixture (L549-L553) covers fabricated
  reviewer findings that cite missing files, out-of-range lines, and
  quoted-content mismatches.

  Nowhere in T08's Scope / Definition of done / Test expectations does the
  plan require the verifier to refuse cited paths whose canonical target is
  outside `$REPO_ROOT/`. The verifier is told to read whatever the finding
  cites.

  ## Why this is a gap

  The cite-check turns the verifier sub-agent into a content oracle for
  arbitrary cited paths:

  1. A reviewer's `referenced_files:` value is attacker-influenceable.
     Third-party reviewers run under model_routing (T16/CD-1), which means a
     prompt-injection payload in a reviewed artifact body (any
     attacker-controlled doc, README, finding, or upstream artifact a
     reviewer reads) can steer a third-party reviewer to emit findings with
     `referenced_files: /etc/passwd` or `~/.ssh/id_rsa` plus a fabricated
     quoted-content line range.
  2. T08 then mandates the verifier read that cited path and compare bytes.
     If the verifier itself runs via a cloud-LLM dispatch under
     model_routing (T16 explicitly puts the verifier on `tier: low` →
     vendor-resolved), the file contents enter the cloud LLM's context
     during the comparison step.
  3. The verifier writes a `HALLUCINATED: ` sidecar `reason:` (L530, L542,
     L551). The plan does not bound what fragment of the cited content may
     appear in that reason — a verifier comparing quoted-content has the
     mismatched bytes "in hand" for the diagnostic.

  The release fixture explicitly drives "fabricated citations through the
  verifier fan-in path" (L531) — i.e. the exfil-shaped input pattern — but
  only asserts the score-0 + drop behavior, never asserts that
  out-of-repo cited paths are refused before the read.

  ## Parity with established pattern

  T21 G16 (L1258-L1289) requires `assert_path_under_repo_root <label>
  <abs-path>` on every prompt-ingested file path in `dispatch-agent.sh`,
  canonicalizing with `realpath`/`readlink -f` and rejecting canonical
  targets outside `$REPO_ROOT/` with `resolves outside repository`. T39
  (L2260, L2275) extends the same shape to `tools/build-plugin.mjs` for
  `!cat` targets, with an explicit symlink-escape regression that mirrors
  T21's diagnostic phrase.

  T08's cite check is the third file-read surface that consumes
  attacker-influenceable path strings, but is the only one without the
  matching boundary guard. The plan should either:

  (a) add to T08's Scope a requirement that Step 3.5 Cite Check canonicalize
      each cited path with `realpath`/equivalent before the file is read or
      its bytes are quoted into a sidecar, and emit `score: 0` with a
      `reason:` beginning `HALLUCINATED: ` and the literal substring
      `resolves outside repository` (or similar audit-friendly phrase
      shared with T21/T39) when the canonical path is not under
      canonical `$REPO_ROOT/`; AND
  (b) extend T08's release acceptance fixture (L531, L549-L553) with a
      symlink-escape / out-of-repo cited path case, mirroring T21's
      symlink regression in `tests/unit/test-dispatch-agent.bats` and
      T39's symlink-escape regression — asserting the verifier refuses the
      read before any byte of the cited target enters a sidecar `reason:`
      field.

  ## Suggested edits

  - plan.md T08 Scope `In` (around L527-L531): add a new bullet
    requiring the cite-check to canonicalize each cited path with
    `realpath`/equivalent and refuse out-of-repo canonical targets
    before file bytes are read. The guard must mirror T21's
    `assert_path_under_repo_root` shape (cite Task 21 explicitly so
    implementer reuses the helper rather than re-implementing).
  - plan.md T08 Definition of done (around L541-L545): add a DoD line
    requiring out-of-repo cited paths (including symlinks whose
    canonical target escapes the repo) to short-circuit Cite Check with
    `score: 0` + `HALLUCINATED: ` reason + the shared audit phrase, with
    no bytes from the cited target inlined into the sidecar.
  - plan.md T08 Test expectations (around L549-L553): add a fixture
    citing an out-of-repo absolute path AND a fixture citing a symlink
    whose canonical target is outside `$REPO_ROOT` (e.g. `/etc/passwd`
    or a tmpdir secret); assert the verifier exits 0 with a score-0
    sidecar and that no fragment of the cited target's content appears
    in the sidecar body.

  ## Scope note

  This is a NEW surface added by T08 (mandatory cite-content comparison
  on every cited path), not a pre-existing concern. The pre-T08
  "referenced-files read step" (mentioned at L528) was a context-loading
  read; T08 elevates it to a mandatory byte-level comparator that quotes
  content into a verifier-emitted sidecar — which is the surface that
  needs the boundary guard.
