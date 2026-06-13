# Release runbook

## Release flow

`VERSION` at the repo root is the only file an author edits to bump the plugin version. It holds a single non-empty version string with no trailing newline beyond the standard one. Nothing else is hand-edited for the bump.

After editing `VERSION`, run the propagation step:

```
node tools/build-plugin.mjs
```

`node tools/build-plugin.mjs` reads `VERSION` and writes the value into the `"version"` field of all five consumer manifests:

1. `.claude-plugin/plugin.json`
2. `.claude-plugin/marketplace.json`
3. `.github/plugin/plugin.json`
4. `.github/plugin/marketplace.json`
5. `build/.claude-plugin/plugin.json` (regenerated under `build/` from the just-stamped source manifest)

The command also regenerates the full `build/` tree. Malformed or missing `VERSION` halts with `version-source-missing-or-malformed:` and no consumer file is written.

## Release-commit shape

The release ships as one commit containing exactly:

- the `VERSION` edit;
- the propagated `"version"` stamps in the five consumer files listed above;
- the regenerated `build/` content produced by the same `node tools/build-plugin.mjs` run.

Do not split these into separate commits. Do not commit a `VERSION` edit without the propagated stamps and the regenerated `build/`; the `build-then-diff` CI gate (`node tools/build-plugin.mjs && git diff --exit-code`) fails the PR on any divergence between the freshly-built tree and the committed tree.
