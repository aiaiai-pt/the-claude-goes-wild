---
name: scan
description: Run a scan-only cycle — security scans + AI triage, no code changes
---

# Scan

Run a scan-only cycle. No implementation, no code changes. $ARGUMENTS

## Process

1. **Run local scans**:
   - Execute `python ~/.claude/scripts/fetch-local-scans.py`
   - If `$ARGUMENTS` contains `--sonar`, add the `--sonar` flag
   - If `$ARGUMENTS` contains `--image <tag>`, add the `--image <tag>` flag
   - If the script is not found, fall back to the `/security-scan` skill

2. **Triage findings**:
   - Use the `security-analyst` agent to read `.agent-handoffs/ci-findings.json`
   - The agent will cross-reference against `.agent-memory/security/` (if present)
   - Agent writes `.agent-handoffs/security-report.md`

3. **Report**:
   - Summarise the security report to the user
   - Include: finding counts by severity, suppressed count, recommended remediations
   - Leave `.agent-handoffs/` intact for user review

## Rules

- Do NOT proceed to implementation
- Do NOT delete `.agent-handoffs/` — leave it for user review
- If scan tools are missing, report which ones and how to install them
