---
name: security-scan
description: Run SAST, secret scanning, and dependency audit on the current codebase
---

# Security Scan

Run security scans on the current codebase or changed files. $ARGUMENTS

## Process

0. **Automated scan (if available)**:
   - Check if `~/.claude/scripts/fetch-local-scans.py` exists
   - If yes: run `python ~/.claude/scripts/fetch-local-scans.py` (add `--sonar` if
     `SONAR_HOST` and `SONAR_TOKEN` env vars are set, add `--image <tag>` if a
     container image was specified in `$ARGUMENTS`)
   - Read the resulting `.agent-handoffs/ci-findings.json`
   - If `status` is `complete` or `partial`: use the normalised JSON for AI triage
     in steps 2-5 below — skip manual invocation of any tools that succeeded in
     the automated scan
   - If `status` is `failed` or the script is not found: fall back to the manual
     process below (steps 1-5 run as before)

1. **Determine scope**:
   - If arguments specify files or a branch: scan only those
   - If invoked during BUILD: scan changed files (`git diff --name-only` against base branch)
   - If invoked standalone: scan the full codebase
   - Identify the project language(s) to select appropriate tools

2. **Secret scanning** (ALWAYS runs first — fastest and most critical):
   - Run gitleaks or equivalent against the scan scope
   - Check for: API keys, tokens, passwords, private keys, connection strings,
     AWS credentials, GCP service accounts, any high-entropy strings matching
     known secret patterns
   - Check `.env` files are in `.gitignore`
   - Check for secrets in CI/CD configs, Docker files, and IaC templates
   - **Signal**: secret found → yes/no + file:line + secret type
   - **Any finding here is Critical severity. No exceptions.**

3. **SAST scan**:
   - Run Semgrep with appropriate rulesets for the project language:
     - `p/security-audit` (general)
     - `p/owasp-top-ten` (web applications)
     - `p/secrets` (additional secret patterns)
     - Language-specific rules (e.g., `p/python`, `p/typescript`)
   - **AI triage**: For each finding, assess reachability:
     - Trace the call graph from the finding to the nearest entry point
     - If the code path is provably unreachable (dead code, behind permanent
       feature flag, test-only code), mark as **Suppressed** with rationale
     - If reachability is uncertain, keep the finding — err on the side of caution
   - **Signal**: finding count by severity (Critical/High/Medium/Low) after triage

4. **Dependency audit**:
   - Detect package manager(s) in use
   - Run the appropriate audit command:
     - Node.js: `npm audit --json` or `yarn audit --json`
     - Python: `pip-audit --format=json`
     - Rust: `cargo audit --json`
     - Go: `govulncheck ./...`
     - Ruby: `bundle-audit check --format=json`
   - **Signal**: CVE count by severity + fix available (yes/no) + affected package + version range

5. **Container scan** (if Dockerfile or container configs exist):
   - Run Trivy or equivalent against the image or Dockerfile
   - Check for: OS-level vulnerabilities, misconfigured permissions,
     running as root, unnecessary packages
   - **Signal**: vulnerability count by severity

6. **Produce structured report**:

```
## Security Scan Report
**Date**: YYYY-MM-DD
**Scope**: [files/branch/full]
**Duration**: Ns

## Secrets
- Status: CLEAN | BLOCKED (N secrets found)
- [If found: file:line, secret type, remediation]

## SAST Findings
| Severity | Count | After Triage | Rule |
|----------|-------|-------------|------|
| Critical | N     | N           |      |
| High     | N     | N           |      |
| Medium   | N     | N           |      |
| Low      | N     | N           |      |
| Suppressed (unreachable) | N | — | |

### [Severity] Finding: [title]
- **File**: path/to/file:line
- **Rule**: [semgrep rule id]
- **Issue**: [what's wrong]
- **Reachable**: yes / uncertain / no (suppressed)
- **Fix**: [specific code change]

## Dependency Vulnerabilities
| Package | Version | CVE | Severity | Fix Available | Fixed In |
|---------|---------|-----|----------|--------------|----------|

## Container Vulnerabilities (if applicable)
| Package | Version | CVE | Severity | Fix Available |
|---------|---------|-----|----------|--------------|

## Verdict
- Secrets: PASS / FAIL
- SAST: PASS (0 Critical/High reachable) / FAIL (N Critical, N High)
- Dependencies: PASS / FAIL (N Critical/High CVEs)
- Container: PASS / FAIL / N/A
- **Overall**: PASS / FAIL — [blocking items list]
```

## Rules

- Secret scan ALWAYS runs, even if other scans are skipped
- Never suppress a SAST finding without proving unreachability — "unlikely" is not proof
- Dependency audit output must include whether a fix is available — this drives auto-patch decisions
- Container scan only runs if container artifacts exist — don't flag for non-containerized projects
- Report must include deterministic verdicts (PASS/FAIL) that downstream processes can parse
- If any scan tool is unavailable, report it as SKIPPED with the reason, not as PASS
