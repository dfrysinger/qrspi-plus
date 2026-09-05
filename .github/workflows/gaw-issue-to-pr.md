---
concurrency:
  cancel-in-progress: false
  group: gaw-engine-alpha-${{ github.repository_id }}-${{ github.event.issue.number
    }}
  queue: max
engine:
  command: /bin/true
  id: copilot
if: (github.event.label.name == 'agentic')
network: defaults
'on':
  issues:
    types:
    - labeled
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
    \ | cut -d ' ' -f1)\n[ \"$actual_bundle_sha256\" = \"6e0ae0c0a37f52ae7c47212163ab26b304344cdaf763dd0932dd990676f8a685\"\
    \ ] || {\n  echo \"::error::packaged GAW engine bundle digest mismatch\"\n  exit\
    \ 1\n}\nrm -rf .gaw/engine/source\ngit -c core.hooksPath=/dev/null clone -- \"\
    $(pwd)/.gaw/engine/gaw-engine.bundle\" .gaw/engine/source\ngit -C .gaw/engine/source\
    \ checkout --detach 5ade18fee0f93c389aeb6a072375dc55b85a0db3\nactual_engine_ref=$(git\
    \ -C .gaw/engine/source rev-parse HEAD)\n[ \"$actual_engine_ref\" = \"5ade18fee0f93c389aeb6a072375dc55b85a0db3\"\
    \ ] || {\n  echo \"::error::checked-out GAW engine commit mismatch\"\n  exit 1\n\
    }\n"
- name: Install pinned GAW runtime
  run: 'set -euo pipefail

    python3 -m venv "$RUNNER_TEMP/gaw-deployment-venv"

    $RUNNER_TEMP/gaw-deployment-venv/bin/python -m pip install --disable-pip-version-check
    -r "$GITHUB_WORKSPACE/.gaw/engine/source/requirements.txt"

    npm --prefix "$GITHUB_WORKSPACE/.gaw/engine/source" ci --ignore-scripts

    '
- name: Verify source and prepare deterministic deployment input
  run: 'set -euo pipefail

    PYTHONPATH="$GITHUB_WORKSPACE/.gaw/engine/source" $RUNNER_TEMP/gaw-deployment-venv/bin/python
    -m src.backends.deployment_runtime prepare --contract-b64 eyJhcmdzU2hhMjU2IjoiNDQxMzZmYTM1NWIzNjc4YTExNDZhZDE2ZjdlODY0OWU5NGZiNGZjMjFmZTc3ZTgzMTBjMDYwZjYxY2FhZmY4YSIsImJhY2tlbmQiOiJnaXRodWItc2RrIiwiYmluZGluZ3NTaGEyNTYiOiI4YWM0ZDQ0ZjM0YTQwNGFjZTViZjUwNWIwM2JhZTUwODZjYTZhM2E0NTc3MzRkNDcxNDBmMjFjMDg0YzhjNDRlIiwiY29uY3VycmVuY3kiOnsiY2FuY2VsSW5Qcm9ncmVzcyI6ZmFsc2UsImtleSI6W3siY29udGV4dCI6Ii90YXJnZXQvcmVwb3NpdG9yeUlkIn0seyJldmVudCI6Ii9pc3N1ZS9udW1iZXIifV0sInF1ZXVlIjoibWF4In0sImRlcGxveW1lbnRTaGEyNTYiOiIzYWIxNTZkY2E3OGNlYWEyOGM0NWRjYjEzNzQ4MTFhODU0N2M2MGNkNzdlMDk1MmUxYmFkMzFkODQ4MzcwZTA4IiwiZW5naW5lUmVmIjoiNWFkZTE4ZmVlMGY5M2MzODlhZWI2YTA3MjM3NWRjNTViODVhMGRiMyIsImlucHV0QXV0aG9yaXR5Ijoic291cmNlIiwiaW50ZXJmYWNlIjp7ImlucHV0cyI6eyJhZGRpdGlvbmFsUHJvcGVydGllcyI6ZmFsc2UsInByb3BlcnRpZXMiOnsiaXNzdWUiOnsiZGVzY3JpcHRpb24iOiJJc3N1ZSBudW1iZXIgb3IgVVJMIGluIHRoZSBzZWxlY3RlZCB0YXJnZXQgcmVwb3NpdG9yeSIsIm1pbkxlbmd0aCI6MSwidHlwZSI6InN0cmluZyJ9fSwicmVxdWlyZWQiOlsiaXNzdWUiXSwidHlwZSI6Im9iamVjdCJ9LCJvdXRwdXRzIjp7ImZpbGVzIjpbeyJtYXhCeXRlcyI6MTY3NzcyMTYsIm1lZGlhVHlwZSI6InRleHQveC1kaWZmIiwibmFtZSI6InBhdGNoIiwicGF0aCI6Imdhdy1vdXRwdXQvaXNzdWUtdG8tcHIucGF0Y2giLCJyZXF1aXJlZCI6dHJ1ZX0seyJtYXhCeXRlcyI6MjYyMTQ0LCJtZWRpYVR5cGUiOiJ0ZXh0L3BsYWluIiwibmFtZSI6ImNoYW5nZWRGaWxlcyIsInBhdGgiOiJnYXctb3V0cHV0L2NoYW5nZWQtZmlsZXMudHh0IiwicmVxdWlyZWQiOnRydWV9LHsibWF4Qnl0ZXMiOjY1NTM2LCJtZWRpYVR5cGUiOiJhcHBsaWNhdGlvbi9qc29uIiwibmFtZSI6InB1bGxSZXF1ZXN0IiwicGF0aCI6Imdhdy1vdXRwdXQvcHVsbC1yZXF1ZXN0Lmpzb24iLCJyZXF1aXJlZCI6dHJ1ZX1dfSwic2NoZW1hVmVyc2lvbiI6MX0sIm1vZGUiOnsiY29uY3VycmVuY3kiOnsiY2FuY2VsSW5Qcm9ncmVzcyI6ZmFsc2UsImtleSI6W3siY29udGV4dCI6Ii90YXJnZXQvcmVwb3NpdG9yeUlkIn0seyJldmVudCI6Ii9pc3N1ZS9udW1iZXIifV0sInF1ZXVlIjoibWF4In0sImlkIjoiaXNzdWUiLCJpbnB1dHMiOnsiYXV0aG9yaXR5Ijoic291cmNlIiwiYmluZGluZ3MiOlt7InRhcmdldCI6Ii9pc3N1ZSIsInZhbHVlIjp7ImV2ZW50IjoiL2lzc3VlL2h0bWxfdXJsIn19XX0sImxhYmVsIjoiQ3JlYXRlIGEgcHVsbCByZXF1ZXN0IGZyb20gbGFiZWxlZCBpc3N1ZXMiLCJydW50aW1lIjp7InBsYWNlbWVudCI6ImNsb3VkIiwicHJvdmlkZXIiOiJnaXRodWItYWN0aW9ucyJ9LCJ0YXJnZXQiOnsia2luZCI6InJlcG9zaXRvcnkifSwidHJpZ2dlciI6eyJhY3Rpb25zIjpbImxhYmVsZWQiXSwiZXZlbnQiOiJpc3N1ZXMiLCJraW5kIjoiZXZlbnQiLCJwcm92aWRlciI6ImdpdGh1YiIsIndoZW4iOnsiZXF1YWxzIjpbeyJldmVudCI6Ii9sYWJlbC9uYW1lIn0seyJsaXRlcmFsIjoiYWdlbnRpYyJ9XX19fSwibW9kZUlkIjoiaXNzdWUiLCJtb2RlU2hhMjU2IjoiMzRjODQ1ZTNmMDcyMThiZTA2NjIyZTAxYTg1M2IxMTVjZmQ4ODUwMTIyYjBlNjI3MThiZDk2MTc5OGQ2ZjEzYSIsInNjaGVtYVZlcnNpb24iOjIsInNvdXJjZUJpbmRpbmdzIjpbeyJ0YXJnZXQiOiIvaXNzdWUiLCJ2YWx1ZSI6eyJldmVudCI6Ii9pc3N1ZS9odG1sX3VybCJ9fV0sInNvdXJjZVBhdGgiOiIuZ2F3L2RlcGxveW1lbnRzL2lzc3VlLXRvLXByL3dvcmtmbG93Lm93cy5qcyIsInNvdXJjZVNoYTI1NiI6IjAwNjE2ZWNhMDlmOTFkOTYwYmIxMWViYjlmNTZjZDc4YTIxMmViZmM3OWI3Y2I4N2M0NTBlYWFjZmFkODg0YTEiLCJ0cmlnZ2VyIjp7ImFjdGlvbnMiOlsibGFiZWxlZCJdLCJldmVudCI6Imlzc3VlcyIsImtpbmQiOiJldmVudCIsInByb3ZpZGVyIjoiZ2l0aHViIiwid2hlbiI6eyJlcXVhbHMiOlt7ImV2ZW50IjoiL2xhYmVsL25hbWUifSx7ImxpdGVyYWwiOiJhZ2VudGljIn1dfX19
    --target-root "$GITHUB_WORKSPACE" --gaw-root "$GITHUB_WORKSPACE/.gaw/engine/source"
    --event-path "$GITHUB_EVENT_PATH" --github-env "$GITHUB_ENV"

    '
- env:
    GAW_ENTERPRISE_MANAGED: 'false'
    GAW_ENTERPRISE_POLICY_B64: ${{ vars.GAW_ENTERPRISE_POLICY_B64 }}
    RUN_ATTEMPT: ${{ github.run_attempt }}
    RUN_ID: ${{ github.run_id }}
    RUN_REPOSITORY: ${{ github.repository }}
  name: Resolve enterprise governance mode
  run: "set -euo pipefail\nif [ \"$GAW_ENTERPRISE_MANAGED\" = \"true\" ]; then\n \
    \ [ -n \"$GAW_ENTERPRISE_POLICY_B64\" ] || {\n    echo \"::error::Managed mode\
    \ requires GAW_ENTERPRISE_POLICY_B64\"\n    exit 1\n  }\n  PYTHONPATH=\"$GITHUB_WORKSPACE/.gaw/engine/source\"\
    \ $RUNNER_TEMP/gaw-deployment-venv/bin/python -m src.policy.enterprise_artifact\
    \ issue-oidc --source \"$GITHUB_WORKSPACE/.gaw/deployments/issue-to-pr/workflow.ows.js\"\
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
    GAW_TRUSTED_DIRECT_SOURCE_SHA256: 00616eca09f91d960bb11ebb9f56cd78a212ebfc79b7cb87c450eaacfad884a1
    GH_AW_SAFE_OUTPUTS: ${{ steps.set-runtime-paths.outputs.GH_AW_SAFE_OUTPUTS }}
    RUN_TAG: ${{ github.run_id }}-${{ github.run_attempt }}
  name: Run exact governed OWS deployment
  run: 'set -euo pipefail

    PYTHONPATH="$GITHUB_WORKSPACE/.gaw/engine/source" $RUNNER_TEMP/gaw-deployment-venv/bin/python
    -m src.backends.deployment_runtime emit --source-path "$OWS_BODY_PATH" --source-sha256
    "$OWS_BODY_SHA256" --engine-ref 5ade18fee0f93c389aeb6a072375dc55b85a0db3 --gaw-root
    "$GITHUB_WORKSPACE/.gaw/engine/source" --target-root "$GITHUB_WORKSPACE" --output
    "$GH_AW_SAFE_OUTPUTS"

    '
---

# Governed deployment run

Runs the selected `issue` cloud mode of the exact deployed OWS at `.gaw/deployments/issue-to-pr/workflow.ows.js` under the fixed repository-local GAW engine (`.gaw/engine/gaw-engine.bundle`), through the existing `src.backends.deployment_runtime` prepare/emit runtime-preparation and native SafeOutputs serialization path.
