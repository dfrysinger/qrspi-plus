---
checkout: false
engine:
  command: /bin/true
  id: copilot
metadata:
  gaw_app_id: gaw-end-to-end-proof
  gaw_backend: github-sdk
  gaw_deployment_key: 7cd7799c47041c954591e1dab1ddcc0ff1f4b283f3edaf09e8eeb83dc2f2770a
  gaw_deployment_sha256: 9f2585993231011b91a0a270dd4399939bc19f1449a131c0ad72816f1814392c
  gaw_engine_bundle_path: .gaw/nexus-engine/gaw-engine.bundle
  gaw_engine_bundle_sha256: cbe6dbb912e7a6de261fb5af4ffac82089c87b70a958fd89e2dcdffbc2d64f39
  gaw_engine_ref: 07e6a67091302586aa88630f32516e9d289df156
  gaw_engine_seed_ref: refs/heads/gaw-nexus/engine/cbe6dbb912e7a6de261fb5af4ffac82089c87b70a958fd89e2dcdffbc2d64f39
  gaw_engine_source_mode: embedded
  gaw_engine_target_repository: dfrysinger/qrspi-plus
  gaw_mode_id: actions
  gaw_mode_sha256: 5bf5870f13e3f2e0403fdd5cdd70ae9feee33233dea5c6ced2723fefb3896caa
  gaw_source_sha256: 3a24679e9dc3e9cbe079ad94d776f72bad7f2b2b7490e98d115fe5d68546f4fc
name: GAW deployment 7cd7799c47041c95
network:
  allowed:
  - api.github.com
  - api.githubcopilot.com
  - github.com
  - github.ghe.com
'on':
  workflow_call:
    inputs:
      gaw_run_input:
        required: true
        type: string
    secrets:
      COPILOT_GITHUB_TOKEN:
        required: true
  workflow_dispatch:
    inputs:
      gaw_run_input:
        description: Canonical GAW run-input envelope
        required: true
        type: string
permissions:
  actions: read
  contents: read
  copilot-requests: write
  id-token: write
safe-outputs:
  activation-comments: false
  add-comment:
    max: 3
  create-pull-request:
    max: 1
  noop:
    report-as-issue: false
  report-failure-as-issue: false
  report-incomplete: false
sandbox:
  agent:
    sudo: false
steps:
- name: Checkout trusted target deployment source
  uses: actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803
  with:
    persist-credentials: false
    ref: ${{ job.workflow_sha }}
    repository: ${{ job.workflow_repository }}
- name: Checkout embedded GAW engine seed
  uses: actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803
  with:
    path: .gaw/engine-seed
    persist-credentials: false
    ref: refs/heads/gaw-nexus/engine/cbe6dbb912e7a6de261fb5af4ffac82089c87b70a958fd89e2dcdffbc2d64f39
    repository: dfrysinger/qrspi-plus
- name: Verify and extract embedded GAW engine
  run: 'set -euo pipefail

    EXPECTED_TARGET_REPOSITORY="dfrysinger/qrspi-plus"

    test "${GITHUB_REPOSITORY,,}" = "${EXPECTED_TARGET_REPOSITORY,,}"

    SEED_DIR="$GITHUB_WORKSPACE/.gaw/engine-seed"

    BUNDLE_PATH="$SEED_DIR/.gaw/nexus-engine/gaw-engine.bundle"

    EXPECTED_SHA256="cbe6dbb912e7a6de261fb5af4ffac82089c87b70a958fd89e2dcdffbc2d64f39"

    ACTUAL_SHA256="$(sha256sum "$BUNDLE_PATH" | awk ''{print $1}'')"

    test "$ACTUAL_SHA256" = "$EXPECTED_SHA256"

    git -c core.hooksPath=/dev/null clone "$BUNDLE_PATH" "$GITHUB_WORKSPACE/gaw"

    git -C "$GITHUB_WORKSPACE/gaw" -c core.hooksPath=/dev/null checkout --detach "07e6a67091302586aa88630f32516e9d289df156"

    test "$(git -C "$GITHUB_WORKSPACE/gaw" rev-parse HEAD)" = "07e6a67091302586aa88630f32516e9d289df156"

    rm -rf -- "$SEED_DIR"

    '
- name: Install pinned GAW runtime
  run: 'set -euo pipefail

    python3 -m venv "$RUNNER_TEMP/gaw-deployment-venv"

    $RUNNER_TEMP/gaw-deployment-venv/bin/python -m pip install --disable-pip-version-check -r "$GITHUB_WORKSPACE/gaw/requirements.txt"

    npm --prefix "$GITHUB_WORKSPACE/gaw" ci --ignore-scripts

    '
- env:
    GAW_RUN_INPUT_B64: ${{ inputs.gaw_run_input }}
  name: Verify source and prepare deterministic deployment input
  run: 'set -euo pipefail

    PYTHONPATH="$GITHUB_WORKSPACE/gaw" $RUNNER_TEMP/gaw-deployment-venv/bin/python -m src.backends.deployment_runtime prepare --contract-b64 eyJhcmdzU2hhMjU2IjoiNDQxMzZmYTM1NWIzNjc4YTExNDZhZDE2ZjdlODY0OWU5NGZiNGZjMjFmZTc3ZTgzMTBjMDYwZjYxY2FhZmY4YSIsImJhY2tlbmQiOiJnaXRodWItc2RrIiwiYmluZGluZ3NTaGEyNTYiOiI0ZjUzY2RhMThjMmJhYTBjMDM1NGJiNWY5YTNlY2JlNWVkMTJhYjRkOGUxMWJhODczYzJmMTExNjEyMDJiOTQ1IiwiY29uY3VycmVuY3kiOm51bGwsImRlcGxveW1lbnRTaGEyNTYiOiI5ZjI1ODU5OTMyMzEwMTFiOTFhMGEyNzBkZDQzOTk5MzliYzE5ZjE0NDlhMTMxYzBhZDcyODE2ZjE4MTQzOTJjIiwiZW5naW5lUmVmIjoiMDdlNmE2NzA5MTMwMjU4NmFhODg2MzBmMzI1MTZlOWQyODlkZjE1NiIsImlucHV0QXV0aG9yaXR5IjoiY2FsbGVyIiwiaW50ZXJmYWNlIjp7ImlucHV0cyI6eyJhZGRpdGlvbmFsUHJvcGVydGllcyI6ZmFsc2UsInByb3BlcnRpZXMiOnt9LCJ0eXBlIjoib2JqZWN0In0sIm91dHB1dHMiOnt9LCJzY2hlbWFWZXJzaW9uIjoxfSwibW9kZSI6eyJpZCI6ImFjdGlvbnMiLCJpbnB1dHMiOnsiYXV0aG9yaXR5IjoiY2FsbGVyIn0sImxhYmVsIjoiUnVuIGZyb20gR2l0SHViIEFjdGlvbnMiLCJydW50aW1lIjp7InBsYWNlbWVudCI6ImNsb3VkIiwicHJvdmlkZXIiOiJnaXRodWItYWN0aW9ucyJ9LCJ0YXJnZXQiOnsia2luZCI6InJlcG9zaXRvcnkifSwidHJpZ2dlciI6eyJraW5kIjoibWFudWFsIn19LCJtb2RlSWQiOiJhY3Rpb25zIiwibW9kZVNoYTI1NiI6IjViZjU4NzBmMTNlM2YyZTA0MDNmZGQ1Y2RkNzBhZTlmZWVlMzMyMzNkZWE1YzZjZWQyNzIzZmVmYjM4OTZjYWEiLCJzY2hlbWFWZXJzaW9uIjoyLCJzb3VyY2VCaW5kaW5ncyI6W10sInNvdXJjZVBhdGgiOiIuZ2F3L2RlcGxveW1lbnRzLzdjZDc3OTljNDcwNDFjOTU0NTkxZTFkYWIxZGRjYzBmZjFmNGIyODNmM2VkYWYwOWU4ZWViODNkYzJmMjc3MGEvd29ya2Zsb3cuanMiLCJzb3VyY2VTaGEyNTYiOiIzYTI0Njc5ZTlkYzNlOWNiZTA3OWFkOTRkNzc2ZjcyYmFkN2YyYjJiNzQ5MGU5OGQxMTVmZTVkNjg1NDZmNGZjIiwidHJpZ2dlciI6eyJraW5kIjoibWFudWFsIn19 --target-root "$GITHUB_WORKSPACE" --gaw-root "$GITHUB_WORKSPACE/gaw" --event-path "$GITHUB_EVENT_PATH" --github-env "$GITHUB_ENV"

    '
- env:
    GAW_ENTERPRISE_MANAGED: ${{ vars.GAW_ENTERPRISE_MANAGED }}
    GAW_ENTERPRISE_POLICY_B64: ${{ vars.GAW_ENTERPRISE_POLICY_B64 }}
    RUN_ATTEMPT: ${{ github.run_attempt }}
    RUN_ID: ${{ github.run_id }}
    RUN_REPOSITORY: ${{ github.repository }}
  name: Resolve enterprise governance mode
  run: "set -euo pipefail\nif [ \"$GAW_ENTERPRISE_MANAGED\" = \"true\" ]; then\n  [ -n \"$GAW_ENTERPRISE_POLICY_B64\" ] || { echo '::error::Managed mode requires GAW_ENTERPRISE_POLICY_B64'; exit 1; }\n  PYTHONPATH=\"$GITHUB_WORKSPACE/gaw\" $RUNNER_TEMP/gaw-deployment-venv/bin/python -m src.policy.enterprise_artifact issue-oidc --source \"$GITHUB_WORKSPACE/.gaw/deployments/7cd7799c47041c954591e1dab1ddcc0ff1f4b283f3edaf09e8eeb83dc2f2770a/workflow.js\" --repository \"$RUN_REPOSITORY\" --run-id \"$RUN_ID\" --run-attempt \"$RUN_ATTEMPT\" --output \"$RUNNER_TEMP/gaw-enterprise-policy-artifact.json\"\n  echo 'GAW_MANAGED_CLOUD_MODE=managed' >> \"$GITHUB_ENV\"\n  echo \"GAW_ENTERPRISE_POLICY_ARTIFACT_FILE=$RUNNER_TEMP/gaw-enterprise-policy-artifact.json\" >> \"$GITHUB_ENV\"\nelif [ \"$GAW_ENTERPRISE_MANAGED\" = \"false\" ]; then\n  echo 'GAW_MANAGED_CLOUD_MODE=unmanaged' >> \"$GITHUB_ENV\"\nelse\n  echo '::error::GAW_ENTERPRISE_MANAGED must be exactly true or false'\n  exit 1\nfi\n"
- env:
    AZURE_CLIENT_ID: ${{ vars.AZURE_CLIENT_ID }}
    AZURE_SUBSCRIPTION_ID: ${{ vars.AZURE_SUBSCRIPTION_ID }}
    AZURE_TENANT_ID: ${{ vars.AZURE_TENANT_ID }}
    COPILOT_GH_HOST: github.com
    ENTERPRISE_POLICY_B64: ${{ vars.GAW_ENTERPRISE_POLICY_B64 }}
    GAW_COPILOT_TOKEN: ${{ secrets.COPILOT_GITHUB_TOKEN }}
    GAW_FOUNDRY_ENDPOINT: ${{ vars.GAW_FOUNDRY_ENDPOINT }}
    GAW_FOUNDRY_MODEL_MAP: ${{ vars.GAW_FOUNDRY_MODEL_MAP }}
    GAW_FOUNDRY_PYTHON: ${{ runner.temp }}/gaw-deployment-venv/bin/python
    GH_AW_SAFE_OUTPUTS: ${{ steps.set-runtime-paths.outputs.GH_AW_SAFE_OUTPUTS }}
    RUN_TAG: ${{ github.run_id }}-${{ github.run_attempt }}
  name: Run exact governed OWS deployment
  run: 'set -euo pipefail

    PYTHONPATH="$GITHUB_WORKSPACE/gaw" $RUNNER_TEMP/gaw-deployment-venv/bin/python -m src.backends.deployment_runtime emit --source-path "$OWS_BODY_PATH" --source-sha256 "$OWS_BODY_SHA256" --engine-ref 07e6a67091302586aa88630f32516e9d289df156 --gaw-root "$GITHUB_WORKSPACE/gaw" --target-root "$GITHUB_WORKSPACE" --output "$GH_AW_SAFE_OUTPUTS"

    '
---

# Governed OWS deployment

The deterministic steps above verify the checked-out GAW engine and managed OWS source, resolve every literal or GitHub event binding, construct the versioned run-input contract, and execute the exact OWS through GAW. The emitted SafeOutputs item short-circuits the gh-aw AI engine; gh-aw remains the trigger, sandbox, and scoped-output compiler.

