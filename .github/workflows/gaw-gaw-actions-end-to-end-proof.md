---
engine:
  command: /bin/true
  id: copilot
network: defaults
'on':
  workflow_dispatch:
    inputs:
      gaw_run_input:
        description: Canonical GAW run-input envelope
        required: true
        type: string
permissions:
  contents: read
  id-token: write
safe-outputs:
  add-comment:
    discussions: false
    issues: true
    max: 1
    pull-requests: true
    target: '*'
  create-pull-request:
    max: 1
  environment: gaw-safe-outputs
  threat-detection: false
sandbox:
  agent:
    sudo: false
steps:
- name: Verify and extract packaged GAW engine
  run: "set -euo pipefail\nactual_bundle_sha256=$(sha256sum .gaw/engine/gaw-engine.bundle\
    \ | cut -d ' ' -f1)\n[ \"$actual_bundle_sha256\" = \"c465b383028be411a9be6951f1e17e6324f6a8566b05289cb194112ee86676e0\"\
    \ ] || {\n  echo \"::error::packaged GAW engine bundle digest mismatch\"\n  exit\
    \ 1\n}\nrm -rf .gaw/engine/source\ngit -c core.hooksPath=/dev/null clone -- \"\
    $(pwd)/.gaw/engine/gaw-engine.bundle\" .gaw/engine/source\ngit -C .gaw/engine/source\
    \ checkout --detach cc30687eb56a4898d1811dcedf6db7b61edcbc45\nactual_engine_ref=$(git\
    \ -C .gaw/engine/source rev-parse HEAD)\n[ \"$actual_engine_ref\" = \"cc30687eb56a4898d1811dcedf6db7b61edcbc45\"\
    \ ] || {\n  echo \"::error::checked-out GAW engine commit mismatch\"\n  exit 1\n\
    }\n"
- name: Install pinned GAW runtime
  run: 'set -euo pipefail

    python3 -m venv "$RUNNER_TEMP/gaw-deployment-venv"

    $RUNNER_TEMP/gaw-deployment-venv/bin/python -m pip install --disable-pip-version-check
    -r "$GITHUB_WORKSPACE/.gaw/engine/source/requirements.txt"

    npm --prefix "$GITHUB_WORKSPACE/.gaw/engine/source" ci --ignore-scripts

    '
- env:
    GAW_RUN_INPUT_B64: ${{ inputs.gaw_run_input }}
  name: Verify source and prepare deterministic deployment input
  run: 'set -euo pipefail

    PYTHONPATH="$GITHUB_WORKSPACE/.gaw/engine/source" $RUNNER_TEMP/gaw-deployment-venv/bin/python
    -m src.backends.deployment_runtime prepare --contract-b64 eyJhcmdzU2hhMjU2IjoiNDQxMzZmYTM1NWIzNjc4YTExNDZhZDE2ZjdlODY0OWU5NGZiNGZjMjFmZTc3ZTgzMTBjMDYwZjYxY2FhZmY4YSIsImJhY2tlbmQiOiJnaXRodWItc2RrIiwiYmluZGluZ3NTaGEyNTYiOiI0ZjUzY2RhMThjMmJhYTBjMDM1NGJiNWY5YTNlY2JlNWVkMTJhYjRkOGUxMWJhODczYzJmMTExNjEyMDJiOTQ1IiwiY29uY3VycmVuY3kiOm51bGwsImRlcGxveW1lbnRTaGEyNTYiOiI5ZjI1ODU5OTMyMzEwMTFiOTFhMGEyNzBkZDQzOTk5MzliYzE5ZjE0NDlhMTMxYzBhZDcyODE2ZjE4MTQzOTJjIiwiZW5naW5lUmVmIjoiY2MzMDY4N2ViNTZhNDg5OGQxODExZGNlZGY2ZGI3YjYxZWRjYmM0NSIsImlucHV0QXV0aG9yaXR5IjoiY2FsbGVyIiwiaW50ZXJmYWNlIjp7ImlucHV0cyI6eyJhZGRpdGlvbmFsUHJvcGVydGllcyI6ZmFsc2UsInByb3BlcnRpZXMiOnt9LCJ0eXBlIjoib2JqZWN0In0sIm91dHB1dHMiOnt9LCJzY2hlbWFWZXJzaW9uIjoxfSwibW9kZSI6eyJpZCI6ImFjdGlvbnMiLCJpbnB1dHMiOnsiYXV0aG9yaXR5IjoiY2FsbGVyIn0sImxhYmVsIjoiUnVuIGZyb20gR2l0SHViIEFjdGlvbnMiLCJydW50aW1lIjp7InBsYWNlbWVudCI6ImNsb3VkIiwicHJvdmlkZXIiOiJnaXRodWItYWN0aW9ucyJ9LCJ0YXJnZXQiOnsia2luZCI6InJlcG9zaXRvcnkifSwidHJpZ2dlciI6eyJraW5kIjoibWFudWFsIn19LCJtb2RlSWQiOiJhY3Rpb25zIiwibW9kZVNoYTI1NiI6IjViZjU4NzBmMTNlM2YyZTA0MDNmZGQ1Y2RkNzBhZTlmZWVlMzMyMzNkZWE1YzZjZWQyNzIzZmVmYjM4OTZjYWEiLCJzY2hlbWFWZXJzaW9uIjoyLCJzb3VyY2VCaW5kaW5ncyI6W10sInNvdXJjZVBhdGgiOiIuZ2F3L2RlcGxveW1lbnRzL2dhdy1hY3Rpb25zLWVuZC10by1lbmQtcHJvb2Yvd29ya2Zsb3cub3dzLmpzIiwic291cmNlU2hhMjU2IjoiYjlhZmY5MTM4YTM0OGIwYjI5NWE3MDIyM2RlYmY1YjRjNzkwNmQ5YWU5NzIxMTMxODM4MzIxZTZkODJmYWQ1NSIsInRyaWdnZXIiOnsia2luZCI6Im1hbnVhbCJ9fQ==
    --target-root "$GITHUB_WORKSPACE" --gaw-root "$GITHUB_WORKSPACE/.gaw/engine/source"
    --event-path "$GITHUB_EVENT_PATH" --github-env "$GITHUB_ENV"

    '
- env:
    GAW_ENTERPRISE_MANAGED: ${{ vars.GAW_ENTERPRISE_MANAGED }}
    GAW_ENTERPRISE_POLICY_B64: ${{ vars.GAW_ENTERPRISE_POLICY_B64 }}
    RUN_ATTEMPT: ${{ github.run_attempt }}
    RUN_ID: ${{ github.run_id }}
    RUN_REPOSITORY: ${{ github.repository }}
  name: Resolve enterprise governance mode
  run: "set -euo pipefail\nif [ \"$GAW_ENTERPRISE_MANAGED\" = \"true\" ]; then\n \
    \ [ -n \"$GAW_ENTERPRISE_POLICY_B64\" ] || {\n    echo \"::error::Managed mode\
    \ requires GAW_ENTERPRISE_POLICY_B64\"\n    exit 1\n  }\n  PYTHONPATH=\"$GITHUB_WORKSPACE/.gaw/engine/source\"\
    \ $RUNNER_TEMP/gaw-deployment-venv/bin/python -m src.policy.enterprise_artifact\
    \ issue-oidc --source \"$GITHUB_WORKSPACE/.gaw/deployments/gaw-actions-end-to-end-proof/workflow.ows.js\"\
    \ --repository \"$RUN_REPOSITORY\" --run-id \"$RUN_ID\" --run-attempt \"$RUN_ATTEMPT\"\
    \ --output \"$RUNNER_TEMP/gaw-enterprise-policy-artifact.json\"\n  echo \"GAW_MANAGED_CLOUD_MODE=managed\"\
    \ >> \"$GITHUB_ENV\"\n  echo \"GAW_ENTERPRISE_POLICY_ARTIFACT_FILE=$RUNNER_TEMP/gaw-enterprise-policy-artifact.json\"\
    \ >> \"$GITHUB_ENV\"\nelif [ \"$GAW_ENTERPRISE_MANAGED\" = \"false\" ]; then\n\
    \  echo \"GAW_MANAGED_CLOUD_MODE=unmanaged\" >> \"$GITHUB_ENV\"\nelse\n  echo\
    \ \"::error::GAW_ENTERPRISE_MANAGED must be exactly true or false\"\n  exit 1\n\
    fi\n"
- env:
    ENTERPRISE_POLICY_B64: ${{ vars.GAW_ENTERPRISE_POLICY_B64 }}
    GAW_COPILOT_TOKEN: ${{ secrets.GAW_COPILOT_TOKEN }}
    GAW_TRUSTED_DIRECT_SOURCE_SHA256: ${{ secrets.GAW_TRUSTED_DIRECT_SOURCE_SHA256_b9aff9138a348b0b295a70223debf5b4c7906d9ae9721131838321e6d82fad55
      }}
    GH_AW_SAFE_OUTPUTS: ${{ steps.set-runtime-paths.outputs.GH_AW_SAFE_OUTPUTS }}
    RUN_TAG: ${{ github.run_id }}-${{ github.run_attempt }}
  name: Run exact governed OWS deployment
  run: 'set -euo pipefail

    PYTHONPATH="$GITHUB_WORKSPACE/.gaw/engine/source" $RUNNER_TEMP/gaw-deployment-venv/bin/python
    -m src.backends.deployment_runtime emit --source-path "$OWS_BODY_PATH" --source-sha256
    "$OWS_BODY_SHA256" --engine-ref cc30687eb56a4898d1811dcedf6db7b61edcbc45 --gaw-root
    "$GITHUB_WORKSPACE/.gaw/engine/source" --target-root "$GITHUB_WORKSPACE" --output
    "$GH_AW_SAFE_OUTPUTS"

    '
---

# Governed deployment run

Runs the selected `actions` cloud mode of the exact deployed OWS at `.gaw/deployments/gaw-actions-end-to-end-proof/workflow.ows.js` under the fixed repository-local GAW engine (`.gaw/engine/gaw-engine.bundle`), through the existing `src.backends.deployment_runtime` prepare/emit runtime-preparation and native SafeOutputs serialization path.
