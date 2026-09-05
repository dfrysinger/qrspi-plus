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
jobs:
  agent:
    needs:
    - gaw_root
  gaw_root:
    if: ${{ needs.activation.result == 'success' && needs.activation.outputs.lockdown_check_failed
      == 'false' && needs.activation.outputs.oauth_token_check_failed == 'false' &&
      needs.activation.outputs.stale_lock_file_failed == 'false' && needs.activation.outputs.secret_verification_result
      != 'failed' && needs.activation.outputs.daily_ai_credits_exceeded != 'true'
      }}
    name: Run approved root orchestration
    needs:
    - activation
    permissions:
      contents: write
      id-token: write
      issues: read
      pull-requests: write
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803
      with:
        persist-credentials: false
        ref: ${{ github.sha }}
    - uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020
      with:
        node-version: '22'
    - name: Verify and extract packaged GAW engine
      run: "set -euo pipefail\nactual_bundle_sha256=$(sha256sum .gaw/engine/gaw-engine.bundle\
        \ | cut -d ' ' -f1)\n[ \"$actual_bundle_sha256\" = \"1a8d1833837f17b38af12dc385de0630129900f54a24ca2d0c9d975add315aa8\"\
        \ ] || {\n  echo \"::error::packaged GAW engine bundle digest mismatch\"\n\
        \  exit 1\n}\nrm -rf .gaw/engine/source\ngit -c core.hooksPath=/dev/null clone\
        \ -- \"$(pwd)/.gaw/engine/gaw-engine.bundle\" .gaw/engine/source\ngit -C .gaw/engine/source\
        \ checkout --detach d4f5558994296ad7de02ff248beeb5fe56268d13\nactual_engine_ref=$(git\
        \ -C .gaw/engine/source rev-parse HEAD)\n[ \"$actual_engine_ref\" = \"d4f5558994296ad7de02ff248beeb5fe56268d13\"\
        \ ] || {\n  echo \"::error::checked-out GAW engine commit mismatch\"\n  exit\
        \ 1\n}\n"
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
        -m src.backends.deployment_runtime prepare --contract-b64 eyJhcmdzU2hhMjU2IjoiNDQxMzZmYTM1NWIzNjc4YTExNDZhZDE2ZjdlODY0OWU5NGZiNGZjMjFmZTc3ZTgzMTBjMDYwZjYxY2FhZmY4YSIsImJhY2tlbmQiOiJnaXRodWItc2RrIiwiYmluZGluZ3NTaGEyNTYiOiI4YWM0ZDQ0ZjM0YTQwNGFjZTViZjUwNWIwM2JhZTUwODZjYTZhM2E0NTc3MzRkNDcxNDBmMjFjMDg0YzhjNDRlIiwiY29uY3VycmVuY3kiOnsiY2FuY2VsSW5Qcm9ncmVzcyI6ZmFsc2UsImtleSI6W3siY29udGV4dCI6Ii90YXJnZXQvcmVwb3NpdG9yeUlkIn0seyJldmVudCI6Ii9pc3N1ZS9udW1iZXIifV0sInF1ZXVlIjoibWF4In0sImRlcGxveW1lbnRTaGEyNTYiOiIzYWIxNTZkY2E3OGNlYWEyOGM0NWRjYjEzNzQ4MTFhODU0N2M2MGNkNzdlMDk1MmUxYmFkMzFkODQ4MzcwZTA4IiwiZW5naW5lUmVmIjoiZDRmNTU1ODk5NDI5NmFkN2RlMDJmZjI0OGJlZWI1ZmU1NjI2OGQxMyIsImlucHV0QXV0aG9yaXR5Ijoic291cmNlIiwiaW50ZXJmYWNlIjp7ImlucHV0cyI6eyJhZGRpdGlvbmFsUHJvcGVydGllcyI6ZmFsc2UsInByb3BlcnRpZXMiOnsiaXNzdWUiOnsiZGVzY3JpcHRpb24iOiJJc3N1ZSBudW1iZXIgb3IgVVJMIGluIHRoZSBzZWxlY3RlZCB0YXJnZXQgcmVwb3NpdG9yeSIsIm1pbkxlbmd0aCI6MSwidHlwZSI6InN0cmluZyJ9fSwicmVxdWlyZWQiOlsiaXNzdWUiXSwidHlwZSI6Im9iamVjdCJ9LCJvdXRwdXRzIjp7ImZpbGVzIjpbeyJtYXhCeXRlcyI6MTY3NzcyMTYsIm1lZGlhVHlwZSI6InRleHQveC1kaWZmIiwibmFtZSI6InBhdGNoIiwicGF0aCI6Imdhdy1vdXRwdXQvaXNzdWUtdG8tcHIucGF0Y2giLCJyZXF1aXJlZCI6dHJ1ZX0seyJtYXhCeXRlcyI6MjYyMTQ0LCJtZWRpYVR5cGUiOiJ0ZXh0L3BsYWluIiwibmFtZSI6ImNoYW5nZWRGaWxlcyIsInBhdGgiOiJnYXctb3V0cHV0L2NoYW5nZWQtZmlsZXMudHh0IiwicmVxdWlyZWQiOnRydWV9LHsibWF4Qnl0ZXMiOjY1NTM2LCJtZWRpYVR5cGUiOiJhcHBsaWNhdGlvbi9qc29uIiwibmFtZSI6InB1bGxSZXF1ZXN0IiwicGF0aCI6Imdhdy1vdXRwdXQvcHVsbC1yZXF1ZXN0Lmpzb24iLCJyZXF1aXJlZCI6dHJ1ZX1dfSwic2NoZW1hVmVyc2lvbiI6MX0sIm1vZGUiOnsiY29uY3VycmVuY3kiOnsiY2FuY2VsSW5Qcm9ncmVzcyI6ZmFsc2UsImtleSI6W3siY29udGV4dCI6Ii90YXJnZXQvcmVwb3NpdG9yeUlkIn0seyJldmVudCI6Ii9pc3N1ZS9udW1iZXIifV0sInF1ZXVlIjoibWF4In0sImlkIjoiaXNzdWUiLCJpbnB1dHMiOnsiYXV0aG9yaXR5Ijoic291cmNlIiwiYmluZGluZ3MiOlt7InRhcmdldCI6Ii9pc3N1ZSIsInZhbHVlIjp7ImV2ZW50IjoiL2lzc3VlL2h0bWxfdXJsIn19XX0sImxhYmVsIjoiQ3JlYXRlIGEgcHVsbCByZXF1ZXN0IGZyb20gbGFiZWxlZCBpc3N1ZXMiLCJydW50aW1lIjp7InBsYWNlbWVudCI6ImNsb3VkIiwicHJvdmlkZXIiOiJnaXRodWItYWN0aW9ucyJ9LCJ0YXJnZXQiOnsia2luZCI6InJlcG9zaXRvcnkifSwidHJpZ2dlciI6eyJhY3Rpb25zIjpbImxhYmVsZWQiXSwiZXZlbnQiOiJpc3N1ZXMiLCJraW5kIjoiZXZlbnQiLCJwcm92aWRlciI6ImdpdGh1YiIsIndoZW4iOnsiZXF1YWxzIjpbeyJldmVudCI6Ii9sYWJlbC9uYW1lIn0seyJsaXRlcmFsIjoiYWdlbnRpYyJ9XX19fSwibW9kZUlkIjoiaXNzdWUiLCJtb2RlU2hhMjU2IjoiMzRjODQ1ZTNmMDcyMThiZTA2NjIyZTAxYTg1M2IxMTVjZmQ4ODUwMTIyYjBlNjI3MThiZDk2MTc5OGQ2ZjEzYSIsInNjaGVtYVZlcnNpb24iOjIsInNvdXJjZUJpbmRpbmdzIjpbeyJ0YXJnZXQiOiIvaXNzdWUiLCJ2YWx1ZSI6eyJldmVudCI6Ii9pc3N1ZS9odG1sX3VybCJ9fV0sInNvdXJjZVBhdGgiOiIuZ2F3L2RlcGxveW1lbnRzL2lzc3VlLXRvLXByL3dvcmtmbG93Lm93cy5qcyIsInNvdXJjZVNoYTI1NiI6IjQzNWFlZjVkMTRlOThhYmM5NTNhMWVlYzRkMDY1NDczNzRlNGY1MzdhNGM1YjNkM2JkZDhlNGE5ZWRiMTJhOWYiLCJ0cmlnZ2VyIjp7ImFjdGlvbnMiOlsibGFiZWxlZCJdLCJldmVudCI6Imlzc3VlcyIsImtpbmQiOiJldmVudCIsInByb3ZpZGVyIjoiZ2l0aHViIiwid2hlbiI6eyJlcXVhbHMiOlt7ImV2ZW50IjoiL2xhYmVsL25hbWUifSx7ImxpdGVyYWwiOiJhZ2VudGljIn1dfX19
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
      run: "set -euo pipefail\nif [ \"$GAW_ENTERPRISE_MANAGED\" = \"true\" ]; then\n\
        \  [ -n \"$GAW_ENTERPRISE_POLICY_B64\" ] || {\n    echo \"::error::Managed\
        \ mode requires GAW_ENTERPRISE_POLICY_B64\"\n    exit 1\n  }\n  PYTHONPATH=\"\
        $GITHUB_WORKSPACE/.gaw/engine/source\" $RUNNER_TEMP/gaw-deployment-venv/bin/python\
        \ -m src.policy.enterprise_artifact issue-oidc --source \"$GITHUB_WORKSPACE/.gaw/deployments/issue-to-pr/workflow.ows.js\"\
        \ --repository \"$RUN_REPOSITORY\" --run-id \"$RUN_ID\" --run-attempt \"$RUN_ATTEMPT\"\
        \ --output \"$RUNNER_TEMP/gaw-enterprise-policy-artifact.json\"\n  echo \"\
        GAW_MANAGED_CLOUD_MODE=managed\" >> \"$GITHUB_ENV\"\n  echo \"GAW_ENTERPRISE_POLICY_ARTIFACT_FILE=$RUNNER_TEMP/gaw-enterprise-policy-artifact.json\"\
        \ >> \"$GITHUB_ENV\"\nelif [ \"$GAW_ENTERPRISE_MANAGED\" = \"false\" ]; then\n\
        \  echo \"GAW_MANAGED_CLOUD_MODE=unmanaged\" >> \"$GITHUB_ENV\"\nelse\n  echo\
        \ \"::error::GAW_ENTERPRISE_MANAGED must be exactly true or false\"\n  exit\
        \ 1\nfi\n"
    - env:
        ENTERPRISE_POLICY_B64: ${{ vars.GAW_ENTERPRISE_POLICY_B64 }}
        GAW_COPILOT_TOKEN: ${{ secrets.GAW_COPILOT_TOKEN }}
        GAW_ROOT_REPOSITORY_TOKEN: ${{ github.token }}
        GAW_TRUSTED_DIRECT_SOURCE_SHA256: 435aef5d14e98abc953a1eec4d06547374e4f537a4c5b3d3bdd8e4a9edb12a9f
        GH_AW_SAFE_OUTPUTS: /tmp/gh-aw/gaw-root-output.jsonl
        RUN_TAG: ${{ github.run_id }}-${{ github.run_attempt }}
      name: Run exact governed OWS deployment
      run: 'set -euo pipefail

        PYTHONPATH="$GITHUB_WORKSPACE/.gaw/engine/source" $RUNNER_TEMP/gaw-deployment-venv/bin/python
        -m src.backends.deployment_runtime emit --source-path "$OWS_BODY_PATH" --source-sha256
        "$OWS_BODY_SHA256" --engine-ref d4f5558994296ad7de02ff248beeb5fe56268d13 --gaw-root
        "$GITHUB_WORKSPACE/.gaw/engine/source" --target-root "$GITHUB_WORKSPACE" --output
        "$GH_AW_SAFE_OUTPUTS"

        '
    - if: ${{ success() || failure() }}
      name: Transfer root execution outputs
      uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02
      with:
        if-no-files-found: error
        include-hidden-files: true
        name: gaw-root-execution-${{ github.run_attempt }}
        path: /tmp/gh-aw
name: Issue to PR
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
- uses: actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c
  with:
    name: gaw-root-execution-${{ github.run_attempt }}
    path: /tmp/gh-aw
- env:
    GH_AW_SAFE_OUTPUTS: ${{ steps.set-runtime-paths.outputs.GH_AW_SAFE_OUTPUTS }}
  name: Restore root publication output
  run: 'set -euo pipefail

    mkdir -p "$(dirname "$GH_AW_SAFE_OUTPUTS")"

    cp /tmp/gh-aw/gaw-root-output.jsonl "$GH_AW_SAFE_OUTPUTS"

    '
---

# Governed deployment run

Runs the selected `issue` cloud mode of the exact deployed OWS at `.gaw/deployments/issue-to-pr/workflow.ows.js` under the fixed repository-local GAW engine (`.gaw/engine/gaw-engine.bundle`), through the existing `src.backends.deployment_runtime` prepare/emit runtime-preparation and native SafeOutputs serialization path.
