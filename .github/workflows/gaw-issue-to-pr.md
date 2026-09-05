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
        \ | cut -d ' ' -f1)\n[ \"$actual_bundle_sha256\" = \"6ded35dfd41d30e195ea42a90837c3d4fe75d55dddeffadcf5fc6fc0a084df78\"\
        \ ] || {\n  echo \"::error::packaged GAW engine bundle digest mismatch\"\n\
        \  exit 1\n}\nrm -rf .gaw/engine/source\ngit -c core.hooksPath=/dev/null clone\
        \ -- \"$(pwd)/.gaw/engine/gaw-engine.bundle\" .gaw/engine/source\ngit -C .gaw/engine/source\
        \ checkout --detach ec2678f7d223c66199321ff90aa1f4d62bdebaaf\nactual_engine_ref=$(git\
        \ -C .gaw/engine/source rev-parse HEAD)\n[ \"$actual_engine_ref\" = \"ec2678f7d223c66199321ff90aa1f4d62bdebaaf\"\
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
        -m src.backends.deployment_runtime prepare --contract-b64 eyJhcmdzU2hhMjU2IjoiNDQxMzZmYTM1NWIzNjc4YTExNDZhZDE2ZjdlODY0OWU5NGZiNGZjMjFmZTc3ZTgzMTBjMDYwZjYxY2FhZmY4YSIsImJhY2tlbmQiOiJnaXRodWItc2RrIiwiYmluZGluZ3NTaGEyNTYiOiI4YWM0ZDQ0ZjM0YTQwNGFjZTViZjUwNWIwM2JhZTUwODZjYTZhM2E0NTc3MzRkNDcxNDBmMjFjMDg0YzhjNDRlIiwiY29uY3VycmVuY3kiOnsiY2FuY2VsSW5Qcm9ncmVzcyI6ZmFsc2UsImtleSI6W3siY29udGV4dCI6Ii90YXJnZXQvcmVwb3NpdG9yeUlkIn0seyJldmVudCI6Ii9pc3N1ZS9udW1iZXIifV0sInF1ZXVlIjoibWF4In0sImRlcGxveW1lbnRTaGEyNTYiOiIzYWIxNTZkY2E3OGNlYWEyOGM0NWRjYjEzNzQ4MTFhODU0N2M2MGNkNzdlMDk1MmUxYmFkMzFkODQ4MzcwZTA4IiwiZW5naW5lUmVmIjoiZWMyNjc4ZjdkMjIzYzY2MTk5MzIxZmY5MGFhMWY0ZDYyYmRlYmFhZiIsImlucHV0QXV0aG9yaXR5Ijoic291cmNlIiwiaW50ZXJmYWNlIjp7ImlucHV0cyI6eyJhZGRpdGlvbmFsUHJvcGVydGllcyI6ZmFsc2UsInByb3BlcnRpZXMiOnsiaXNzdWUiOnsiZGVzY3JpcHRpb24iOiJJc3N1ZSBudW1iZXIgb3IgVVJMIGluIHRoZSBzZWxlY3RlZCB0YXJnZXQgcmVwb3NpdG9yeSIsIm1pbkxlbmd0aCI6MSwidHlwZSI6InN0cmluZyJ9fSwicmVxdWlyZWQiOlsiaXNzdWUiXSwidHlwZSI6Im9iamVjdCJ9LCJvdXRwdXRzIjp7ImZpbGVzIjpbeyJtYXhCeXRlcyI6MTY3NzcyMTYsIm1lZGlhVHlwZSI6InRleHQveC1kaWZmIiwibmFtZSI6InBhdGNoIiwicGF0aCI6Imdhdy1vdXRwdXQvaXNzdWUtdG8tcHIucGF0Y2giLCJyZXF1aXJlZCI6dHJ1ZX0seyJtYXhCeXRlcyI6MjYyMTQ0LCJtZWRpYVR5cGUiOiJ0ZXh0L3BsYWluIiwibmFtZSI6ImNoYW5nZWRGaWxlcyIsInBhdGgiOiJnYXctb3V0cHV0L2NoYW5nZWQtZmlsZXMudHh0IiwicmVxdWlyZWQiOnRydWV9LHsibWF4Qnl0ZXMiOjY1NTM2LCJtZWRpYVR5cGUiOiJhcHBsaWNhdGlvbi9qc29uIiwibmFtZSI6InB1bGxSZXF1ZXN0IiwicGF0aCI6Imdhdy1vdXRwdXQvcHVsbC1yZXF1ZXN0Lmpzb24iLCJyZXF1aXJlZCI6dHJ1ZX1dfSwic2NoZW1hVmVyc2lvbiI6MX0sIm1vZGUiOnsiY29uY3VycmVuY3kiOnsiY2FuY2VsSW5Qcm9ncmVzcyI6ZmFsc2UsImtleSI6W3siY29udGV4dCI6Ii90YXJnZXQvcmVwb3NpdG9yeUlkIn0seyJldmVudCI6Ii9pc3N1ZS9udW1iZXIifV0sInF1ZXVlIjoibWF4In0sImlkIjoiaXNzdWUiLCJpbnB1dHMiOnsiYXV0aG9yaXR5Ijoic291cmNlIiwiYmluZGluZ3MiOlt7InRhcmdldCI6Ii9pc3N1ZSIsInZhbHVlIjp7ImV2ZW50IjoiL2lzc3VlL2h0bWxfdXJsIn19XX0sImxhYmVsIjoiQ3JlYXRlIGEgcHVsbCByZXF1ZXN0IGZyb20gbGFiZWxlZCBpc3N1ZXMiLCJydW50aW1lIjp7InBsYWNlbWVudCI6ImNsb3VkIiwicHJvdmlkZXIiOiJnaXRodWItYWN0aW9ucyJ9LCJ0YXJnZXQiOnsia2luZCI6InJlcG9zaXRvcnkifSwidHJpZ2dlciI6eyJhY3Rpb25zIjpbImxhYmVsZWQiXSwiZXZlbnQiOiJpc3N1ZXMiLCJraW5kIjoiZXZlbnQiLCJwcm92aWRlciI6ImdpdGh1YiIsIndoZW4iOnsiZXF1YWxzIjpbeyJldmVudCI6Ii9sYWJlbC9uYW1lIn0seyJsaXRlcmFsIjoiYWdlbnRpYyJ9XX19fSwibW9kZUlkIjoiaXNzdWUiLCJtb2RlU2hhMjU2IjoiMzRjODQ1ZTNmMDcyMThiZTA2NjIyZTAxYTg1M2IxMTVjZmQ4ODUwMTIyYjBlNjI3MThiZDk2MTc5OGQ2ZjEzYSIsInNjaGVtYVZlcnNpb24iOjIsInNvdXJjZUJpbmRpbmdzIjpbeyJ0YXJnZXQiOiIvaXNzdWUiLCJ2YWx1ZSI6eyJldmVudCI6Ii9pc3N1ZS9odG1sX3VybCJ9fV0sInNvdXJjZVBhdGgiOiIuZ2F3L2RlcGxveW1lbnRzL2lzc3VlLXRvLXByL3dvcmtmbG93Lm93cy5qcyIsInNvdXJjZVNoYTI1NiI6IjQzNWFlZjVkMTRlOThhYmM5NTNhMWVlYzRkMDY1NDczNzRlNGY1MzdhNGM1YjNkM2JkZDhlNGE5ZWRiMTJhOWYiLCJ0cmlnZ2VyIjp7ImFjdGlvbnMiOlsibGFiZWxlZCJdLCJldmVudCI6Imlzc3VlcyIsImtpbmQiOiJldmVudCIsInByb3ZpZGVyIjoiZ2l0aHViIiwid2hlbiI6eyJlcXVhbHMiOlt7ImV2ZW50IjoiL2xhYmVsL25hbWUifSx7ImxpdGVyYWwiOiJhZ2VudGljIn1dfX19
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
        COPILOT_HOME: ${{ runner.temp }}/gaw-sdk-${{ github.run_id }}-${{ github.run_attempt }}
        ENTERPRISE_POLICY_B64: ${{ vars.GAW_ENTERPRISE_POLICY_B64 }}
        GAW_COPILOT_TOKEN: ${{ secrets.GAW_COPILOT_TOKEN }}
        GAW_ROOT_REPOSITORY_TOKEN: ${{ github.token }}
        GAW_TRUSTED_DIRECT_SOURCE_SHA256: 435aef5d14e98abc953a1eec4d06547374e4f537a4c5b3d3bdd8e4a9edb12a9f
        GH_AW_SAFE_OUTPUTS: /tmp/gh-aw/gaw-root-output.jsonl
        RUN_TAG: ${{ github.run_id }}-${{ github.run_attempt }}
      name: Run exact governed OWS deployment
      run: 'set -euo pipefail

        umask 077

        mkdir -m 700 -- "$COPILOT_HOME"

        PYTHONPATH="$GITHUB_WORKSPACE/.gaw/engine/source" $RUNNER_TEMP/gaw-deployment-venv/bin/python
        -m src.backends.deployment_runtime emit --source-path "$OWS_BODY_PATH" --source-sha256
        "$OWS_BODY_SHA256" --engine-ref ec2678f7d223c66199321ff90aa1f4d62bdebaaf --gaw-root
        "$GITHUB_WORKSPACE/.gaw/engine/source" --target-root "$GITHUB_WORKSPACE" --output
        "$GH_AW_SAFE_OUTPUTS"

        '
    - name: Encrypt run-owned native session events
      id: encrypt_native_transcript
      if: ${{ always() }}
      working-directory: ${{ runner.temp }}
      env:
        DIAGNOSTIC_RUNNER_TEMP: ${{ runner.temp }}
        DIAGNOSTIC_RUN_TAG: ${{ github.run_id }}-${{ github.run_attempt }}
      run: |
        set -euo pipefail
        /usr/bin/python3 -I <<'PY'
        import contextlib
        import io
        import os
        import re
        import stat
        import subprocess
        import tarfile

        LIMIT = 16 * 1024 * 1024
        MAX_SESSIONS = 4096
        DIR_FLAGS = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW
        RECIPIENT = b"""-----BEGIN CERTIFICATE-----
        MIID1DCCAjwCCQCazGnXz/fFFzANBgkqhkiG9w0BAQsFADAsMSowKAYDVQQDDCFQ
        YXBhIG9uZS1ydW4gZGlhZ25vc3RpYyByZWNpcGllbnQwHhcNMjYwOTA1MTY0MTI3
        WhcNMjYwOTEyMTY0MTI3WjAsMSowKAYDVQQDDCFQYXBhIG9uZS1ydW4gZGlhZ25v
        c3RpYyByZWNpcGllbnQwggGiMA0GCSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQDE
        N+i9rcphSvS6bM0SJSNNmmxWQgcjPho/B3XkDPUw4lpBK5KAiPZ5LMgexp4AAbJA
        86MwKdZuO2fv/nrqEZ5gPzGZPaVTeWBlMooW/56dDgJWOHkP7rxCMpdWeWSb458v
        bfY1PPqzGd3b0c/ISLUxig8+Rdmg/LGZZb0xxCZsYkQluwGWTNPDW+HsceByF3sB
        SG1/3JJgVSmt6MgDSTS7wdUcFgln55IsCh4FHbTm501FXiGzeiofIRiNnXsYqZnX
        DaCvNbFy2tDu+yyVcmaiLDkkADT2dmRBT5oYi5ffKnHqcmrTjnYM4XAPywdOi7Eb
        Olf4jrTu6x0pJgCmw7O2MU4KTumoP1R0LHhrp0NrmjY9ZCgZdCO/RuIgCpvkr5Vo
        XL9aDozWxr4jcIBmFy850/LaPgtFsfy5fR2s31ZxRF1ahE9V0bRKWa8mBhyA7T6L
        gNfVxnJQMAxJNOmiCql39GkZR7m1G40ugSiomm0vUtab/M89ewgTpR3eb11yiPMC
        AwEAATANBgkqhkiG9w0BAQsFAAOCAYEAnYGycjdksHeqF71kKAQPHyGHcfvhGp8C
        xHH9W56ou4GQUDIBpW3ytWISnCuL/n1sgviojYhmZ5TSpGVc/HYP2hQVaB2H24UV
        Xn4XyLNk+09swSPNrrLqeWiJ2X9hYx/VqvM36jcJX12RfUWbem+uw/r/cXnCrwKh
        UWoLtH8YeqOvsMEmH4qQDptsf8edNYX9PzEThzWRsPb/NNsXNM/eT3XF2FRHFlQq
        SDTiHSuHZtSLC9FZumIe2vc4j3BRPKTmlF2CzR5kBFwOZSLlEvyhhBHxWmu+qxGt
        cU9uhJfR70QjQeSqNo9iOBFmBSpfHfYMSOfE8jCDa1kwB7cqLKqb7JuBbjcHUHt/
        q/5ltfwwlpAYqaru84mt7YmpRABtooMIz+pMEy4wOLooqlZc7o2Cmunb6TyNjajw
        nW0x43WcvUYeDL875oOMFeTZhskvUlz8E3ZOfy0xIfihYNGB91JXWTtty8nM+tZl
        5P9ZedAM8yYUKaHXwPIioV9YKlO9jVa9
        -----END CERTIFICATE-----
        """

        class DiagnosticError(Exception):
            pass

        def collect_and_encrypt():
            tag = os.environ["DIAGNOSTIC_RUN_TAG"]
            root = os.environ["DIAGNOSTIC_RUNNER_TEMP"]
            if not re.fullmatch(r"[0-9]+-[0-9]+", tag):
                raise DiagnosticError("invalid run identity")
            parts = root.split("/")
            if not root.startswith("/") or any(p in ("", ".", "..") for p in parts[1:]):
                raise DiagnosticError("invalid runner temporary directory")
            if root == "/tmp/gh-aw" or root.startswith("/tmp/gh-aw/"):
                raise DiagnosticError("native events must be outside ordinary artifacts")
            with contextlib.ExitStack() as stack:
                def directory(name, parent=None):
                    fd = os.open(name, DIR_FLAGS, dir_fd=parent)
                    stack.callback(os.close, fd)
                    return fd

                # Descriptor-relative opens reject symlinks at every path component.
                temp = directory("/")
                for part in parts[1:]:
                    temp = directory(part, temp)
                home = directory("gaw-sdk-" + tag, temp)
                sessions = directory("session-state", home)
                selected = []
                total = 0
                count = 0
                with os.scandir(sessions) as entries:
                    for entry in entries:
                        if entry.is_symlink():
                            raise DiagnosticError("symlink in session selection")
                        if not entry.is_dir(follow_symlinks=False):
                            continue
                        count += 1
                        if count > MAX_SESSIONS:
                            raise DiagnosticError("session count exceeds collection bound")
                        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]{0,63}", entry.name):
                            raise DiagnosticError("invalid native session directory name")
                        session = os.open(entry.name, DIR_FLAGS, dir_fd=sessions)
                        try:
                            try:
                                fd = os.open("events.jsonl", os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=session)
                            except FileNotFoundError:
                                continue
                            with os.fdopen(fd, "rb") as events:
                                before = os.fstat(events.fileno())
                                if not stat.S_ISREG(before.st_mode) or before.st_nlink != 1:
                                    raise DiagnosticError("events must be a single-link regular file")
                                if before.st_size > LIMIT - total:
                                    raise DiagnosticError("native events exceed 16 MiB aggregate")
                                data = events.read(LIMIT - total + 1)
                                after = os.fstat(events.fileno())
                                if len(data) > LIMIT - total:
                                    raise DiagnosticError("native events exceed 16 MiB aggregate")
                                if (before.st_size, before.st_mtime_ns, before.st_ctime_ns) != (after.st_size, after.st_mtime_ns, after.st_ctime_ns) or len(data) != before.st_size:
                                    raise DiagnosticError("native events changed during collection")
                                total += len(data)
                                selected.append((entry.name, data))
                        finally:
                            os.close(session)
                if not selected or not total:
                    raise DiagnosticError("no nonempty native session events")

                output_name = "gaw-native-encrypted-" + tag
                os.mkdir(output_name, mode=0o700, dir_fd=temp)
                output = directory(output_name, temp)
                filename = "events.tar.cms"
                fd = os.open(filename, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600, dir_fd=output)
                complete = False
                try:
                    with os.fdopen(fd, "wb") as ciphertext:
                        cert_read, cert_write = os.pipe()
                        stack.callback(os.close, cert_read)
                        with os.fdopen(cert_write, "wb") as cert:
                            cert.write(RECIPIENT)
                        command = ["/usr/bin/openssl", "cms", "-encrypt", "-binary", "-aes-256-cbc", "-outform", "DER", "/dev/fd/" + str(cert_read)]
                        with subprocess.Popen(command, stdin=subprocess.PIPE, stdout=ciphertext, stderr=subprocess.DEVNULL, pass_fds=(cert_read,), env={"PATH": "/usr/bin:/bin"}) as encryption:
                            try:
                                # Stream tar directly to CMS; no plaintext archive is written.
                                with tarfile.open(fileobj=encryption.stdin, mode="w|", format=tarfile.USTAR_FORMAT) as archive:
                                    for session_id, data in sorted(selected):
                                        member = tarfile.TarInfo("session-state/" + session_id + "/events.jsonl")
                                        member.size = len(data)
                                        member.mode = 0o600
                                        archive.addfile(member, io.BytesIO(data))
                            finally:
                                encryption.stdin.close()
                            if encryption.wait(timeout=60) != 0:
                                raise DiagnosticError("CMS encryption failed")
                        ciphertext.flush()
                        if os.fstat(ciphertext.fileno()).st_size == 0:
                            raise DiagnosticError("CMS encryption produced no ciphertext")
                    complete = True
                finally:
                    if not complete:
                        os.unlink(filename, dir_fd=output)
                print("Encrypted native events: sessions=" + str(len(selected)) + " bytes=" + str(total))

        try:
            collect_and_encrypt()
        except DiagnosticError as error:
            raise SystemExit("::error::" + str(error))
        except (OSError, ValueError, tarfile.TarError, subprocess.SubprocessError):
            raise SystemExit("::error::Native transcript collection/encryption failed; no upload permitted")
        PY
    - name: Upload encrypted native session events
      if: ${{ always() && steps.encrypt_native_transcript.outcome == 'success' }}
      uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02
      with:
        name: gaw-native-events-encrypted-${{ github.run_id }}-${{ github.run_attempt }}
        path: ${{ runner.temp }}/gaw-native-encrypted-${{ github.run_id }}-${{ github.run_attempt }}/events.tar.cms
        if-no-files-found: error
        retention-days: 1
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
