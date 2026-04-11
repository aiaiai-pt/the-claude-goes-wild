#!/usr/bin/env python3
"""
fetch-local-scans.py
--------------------
Runs Semgrep, Trivy, and optionally SonarQube locally.
Writes normalised results to .agent-handoffs/ci-findings.json.

Usage:
  python scripts/fetch-local-scans.py
  python scripts/fetch-local-scans.py --sonar
  python scripts/fetch-local-scans.py --sonar --image your-image:tag
  python scripts/fetch-local-scans.py --out /tmp/results.json

Env vars (required only with --sonar):
  SONAR_TOKEN        project analysis token from SonarQube
  SONAR_PROJECT_KEY  must match sonar.projectKey in sonar-project.properties
  SONAR_HOST         SonarQube server URL (no default — must be set explicitly)
"""

import os
import sys
import json
import argparse
import subprocess
import time
import shutil
from datetime import datetime, timezone
import urllib.request
import urllib.error

HANDOFFS = ".agent-handoffs"


def run(cmd):
    print(f"  $ {' '.join(cmd)}")
    r = subprocess.run(cmd, capture_output=True, text=True)
    return r.returncode, r.stdout, r.stderr


def check_tool(name):
    if not shutil.which(name):
        print(f"  [error] '{name}' not found in PATH")
        return False
    return True


def run_semgrep(out_path):
    print("\n── Semgrep ──────────────────────────────")
    if not check_tool("semgrep"):
        return None, "semgrep not installed — run: pip install semgrep"
    code, _, err = run([
        "semgrep", "scan",
        "--config", "auto",
        "--json",
        "--output", out_path,
        ".",
    ])
    if code not in (0, 1):
        return None, f"semgrep exited {code}: {err}"
    try:
        with open(out_path) as f:
            return json.load(f), None
    except Exception as e:
        return None, f"could not read semgrep output: {e}"


def run_trivy(out_path, image=None):
    print("\n── Trivy ────────────────────────────────")
    if not check_tool("trivy"):
        return None, "trivy not installed — see: https://aquasecurity.github.io/trivy"
    if image:
        cmd = ["trivy", "image", "--format", "json", "--output", out_path, image]
    else:
        cmd = [
            "trivy", "fs",
            "--format", "json",
            "--output", out_path,
            "--scanners", "vuln,secret,misconfig",
            ".",
        ]
    code, _, err = run(cmd)
    if code != 0:
        return None, f"trivy exited {code}: {err}"
    try:
        with open(out_path) as f:
            return json.load(f), None
    except Exception as e:
        return None, f"could not read trivy output: {e}"


def run_sonar(out_path):
    print("\n── SonarQube ────────────────────────────")
    if not check_tool("sonar-scanner"):
        return None, (
            "sonar-scanner not installed — see: "
            "https://docs.sonarsource.com/sonarqube/latest/analyzing-source-code/scanners/sonarscanner/"
        )

    token = os.environ.get("SONAR_TOKEN")
    host = os.environ.get("SONAR_HOST")
    project = os.environ.get("SONAR_PROJECT_KEY", os.path.basename(os.getcwd()))

    if not host:
        return None, "SONAR_HOST env var not set — set it to your SonarQube server URL"
    if not token:
        return None, f"SONAR_TOKEN env var not set — generate at: {host}/account/security"

    code, _, err = run([
        "sonar-scanner",
        f"-Dsonar.host.url={host}",
        f"-Dsonar.token={token}",
    ])
    if code != 0:
        return None, f"sonar-scanner exited {code}: {err}"

    print("  Waiting for analysis to complete on server...")
    activity_url = f"{host}/api/ce/activity?component={project}&ps=1"
    req = urllib.request.Request(
        activity_url,
        headers={"Authorization": f"Bearer {token}"},
    )
    for attempt in range(20):
        time.sleep(3)
        try:
            with urllib.request.urlopen(req) as r:
                data = json.loads(r.read())
                tasks = data.get("tasks", [])
                if tasks and tasks[0].get("status") == "SUCCESS":
                    print(f"  [ok] analysis complete (attempt {attempt + 1})")
                    break
        except Exception as e:
            print(f"  [warn] polling attempt {attempt + 1} failed: {e}")
    else:
        return None, "SonarQube analysis timed out after 60s"

    issues_url = f"{host}/api/issues/search?projectKeys={project}&ps=500"
    req2 = urllib.request.Request(
        issues_url,
        headers={"Authorization": f"Bearer {token}"},
    )
    try:
        with urllib.request.urlopen(req2) as r:
            result = json.loads(r.read())
            with open(out_path, "w") as f:
                json.dump(result, f, indent=2)
            return result, None
    except Exception as e:
        return None, f"could not fetch SonarQube issues: {e}"


def main():
    parser = argparse.ArgumentParser(
        description="Run Semgrep, Trivy, and optionally SonarQube locally.",
    )
    parser.add_argument("--sonar", action="store_true", help="Include SonarQube scan")
    parser.add_argument("--image", help="Trivy scans a container image instead of filesystem")
    parser.add_argument("--out", default=f"{HANDOFFS}/ci-findings.json", help="Output file path")
    args = parser.parse_args()

    os.makedirs(HANDOFFS, exist_ok=True)

    findings = {
        "status": "incomplete",
        "source": "local",
        "fetched_at": datetime.now(timezone.utc).isoformat(),
        "semgrep": None,
        "trivy": None,
        "sonarqube": None,
        "errors": [],
    }

    data, err = run_semgrep(f"{HANDOFFS}/semgrep-raw.json")
    if err:
        findings["errors"].append(f"semgrep: {err}")
        print(f"  [error] {err}")
    else:
        findings["semgrep"] = data
        print("  [ok] semgrep complete")

    data, err = run_trivy(f"{HANDOFFS}/trivy-raw.json", image=args.image)
    if err:
        findings["errors"].append(f"trivy: {err}")
        print(f"  [error] {err}")
    else:
        findings["trivy"] = data
        print("  [ok] trivy complete")

    if args.sonar:
        data, err = run_sonar(f"{HANDOFFS}/sonar-raw.json")
        if err:
            findings["errors"].append(f"sonarqube: {err}")
            print(f"  [error] {err}")
        else:
            findings["sonarqube"] = data
            print("  [ok] sonarqube complete")
    else:
        print("\n── SonarQube skipped (pass --sonar to include) ──")

    has_any = any(findings[t] is not None for t in ("semgrep", "trivy", "sonarqube"))
    findings["status"] = (
        "complete" if not findings["errors"]
        else "partial" if has_any
        else "failed"
    )

    with open(args.out, "w") as f:
        json.dump(findings, f, indent=2)

    print(f"\n{'─' * 45}")
    print(f"Status : {findings['status']}")
    print(f"Output : {args.out}")
    if findings["errors"]:
        print("Errors :")
        for e in findings["errors"]:
            print(f"  - {e}")

    sys.exit(0 if findings["status"] in ("complete", "partial") else 1)


if __name__ == "__main__":
    main()
