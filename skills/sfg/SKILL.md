---
name: sfg
description: Security Flow - continuous security scanning, threat modeling, dependency patching, penetration testing
argument-hint: [scope: threat-model | scan | test | patch | monitor | report | full]
---

# SFG — Security Flow, Go

Run the security process for the specified scope: $ARGUMENTS

If no scope is specified, run Phase 2 (Scan) on the current codebase as the default.

## Phase 1: Threat Model

**When**: During SHAPE, before a bet is committed. Invoked by LFG/DFG deepen phase.
**Purpose**: Analyze a shaped pitch for security implications before building starts.

1. Run `/threat-model` against the current spec or shaped pitch
2. Output a **Threat Model** section to append to the spec:
   - Data classification (what sensitive data is involved?)
   - Attack surface delta (what new entry points does this bet create?)
   - Trust boundaries crossed (where does data cross privilege levels?)
   - Compliance requirements triggered (GDPR, PCI, HIPAA, SOC2)
   - Security requirements for the bet (auth, encryption, rate limiting, audit logging)
3. Flag any threat rated High or Critical as a **rabbit hole** in the spec — these
   must be resolved during SHAPE, not discovered during BUILD.
4. Present findings to the user. If threat model reveals the bet needs significant
   security work, recommend adjusting the appetite.

## Phase 2: Scan

**When**: During BUILD, on every commit. Can also be invoked standalone.
**Purpose**: Catch vulnerabilities as code is written, not after.

5. Run `/security-scan` against the current codebase or changed files
6. **Decision rules based on deterministic signals**:
   - Secret detected (gitleaks) → **BLOCK immediately**. Zero tolerance. Alert human.
   - Critical SAST finding (Semgrep, confirmed reachable) → **BLOCK commit**. Must fix before proceeding.
   - High SAST finding → **WARN**. Add to findings list. Fix before SHIP.
   - Critical/High dependency CVE with fix available → **AUTO-FIX** via `/dependency-patch` if low risk.
   - Critical/High dependency CVE without fix → **FLAG** for human review with workaround options.
   - Medium/Low findings → **LOG**. Include in security report. Fix during cooldown.
7. Produce a structured scan report (see output format below).

## Phase 3: Test

**When**: During SHIP, before progressive rollout begins.
**Purpose**: Active testing of the running application for vulnerabilities.

8. Run DAST scan against staging environment:
   - Identify all HTTP endpoints from routes/OpenAPI spec
   - Run OWASP ZAP or equivalent against each endpoint
   - Focus on: injection (SQL, XSS, command), auth bypass, CORS misconfiguration,
     security headers, sensitive data exposure
9. For bets touching auth, payment, or data access — run targeted pentest:
   - Auth flows: token handling, session management, privilege escalation
   - Payment flows: parameter tampering, replay attacks
   - Data access: IDOR, authorization boundary testing
10. Generate SBOM using Syft or equivalent:
    - Full component inventory with versions and licenses
    - Flag any copyleft licenses in proprietary codebases
    - Flag any components with known EOL dates
11. **Decision rules**:
    - Confirmed High/Critical DAST finding → **BLOCK rollout**. Human must review.
    - License violation → **BLOCK rollout**. Human must review.
    - Medium/Low DAST findings → **LOG**. Include in report.

## Phase 4: Patch

**When**: Always-on. Runs on schedule (daily) or triggered by CVE feed.
**Purpose**: Keep dependencies patched with supply chain safety.

12. Run `/dependency-patch` to check for available updates
13. **Decision rules with cooldown for supply chain defense**:
    - Patch/minor security fix, published > 3 days ago → **AUTO-APPLY**, run tests, commit
    - Patch/minor security fix, published < 3 days ago → **WAIT**. Schedule for re-check.
    - Major version bump → **CREATE PR** with changelog analysis for human review
    - Any update where tests fail after apply → **REVERT**, flag for human review
14. Report: what was patched, what's waiting on cooldown, what needs human review

## Phase 5: Monitor

**When**: Always-on. Continuous runtime monitoring.
**Purpose**: Detect threats against running systems.

15. Monitor for:
    - CVE feed matches against current dependency graph (trigger Phase 4)
    - Anomalous access patterns (unusual IPs, rate spikes, auth failures)
    - Compliance drift (config changes that weaken security posture)
    - Attack surface changes (new endpoints, new exposed ports, new permissions)
    - Certificate expiration approaching
16. **Decision rules**:
    - New Critical CVE matching a deployed dependency → **ALERT human immediately**
    - Anomalous access pattern → **LOG + alert** if sustained
    - Compliance drift detected → **ALERT** with specific drift and remediation
    - Certificate expiring < 30 days → **ALERT**

## Phase 6: Report

**When**: On demand or scheduled (weekly).
**Purpose**: Security posture summary for human review.

17. Generate security posture report:

```
## Security Posture Report
**Date**: YYYY-MM-DD
**Scope**: [project/service name]

## Vulnerability Summary
| Severity | Open | Fixed This Period | New This Period |
|----------|------|-------------------|-----------------|

## Dependency Health
- Total dependencies: N
- With known CVEs: N (Critical: N, High: N)
- Patch status: N auto-patched, N awaiting cooldown, N need human review
- Average dependency age: N days

## Scan Results (Last Run)
- SAST findings: N (by severity)
- Secrets detected: N (must be 0)
- Container vulnerabilities: N

## DAST Results (Last Run)
- Confirmed vulnerabilities: N
- Auth/access issues: N

## Compliance Status
- [Relevant standards]: compliant / drift detected

## Action Items
1. [Critical items requiring human decision]
```

## Rules

- Secrets in code are ALWAYS Critical severity — no exceptions, no grace period
- NEVER auto-apply dependency patches without the 3-day cooldown
- High/Critical SAST findings with confirmed reachability BLOCK the commit
- High/Critical DAST findings BLOCK the rollout until human reviews
- Threat model is MANDATORY for any bet touching: authentication, authorization,
  payment processing, personal data, API keys/secrets, file uploads, or admin interfaces
- When AI-triaging SAST results, only suppress findings where reachability analysis
  PROVES the code path is unreachable. "Unlikely to be exploited" is not sufficient.
- All scan results must be deterministic and reproducible — same code, same findings
- Never weaken a security control to make tests pass
