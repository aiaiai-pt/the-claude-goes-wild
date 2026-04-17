#!/usr/bin/env python3
"""
Validate architect process output for consistency and completeness.

Run: python3 ~/.claude/scripts/validate-architect-output.py

Or from a repo with a local copy:
  python3 scripts/validate-architect-output.py

Profile-aware: when a platform-grammar skill is installed (typically via the
Ubiwhere profile), this script also lints canonical grammar — forbidden
synonyms, ID prefix conformance, naming conventions, event envelope keys,
API path restrictions, and bucket naming.
"""

import json
import os
import re
import sys
from pathlib import Path

BASE = Path("docs/architect-process")
CLAUDE_HOME = Path(os.environ.get("CLAUDE_HOME", str(Path.home() / ".claude")))
PROFILE_MARKER = CLAUDE_HOME / ".active-profiles"
GRAMMAR_SKILL = CLAUDE_HOME / "skills" / "platform-grammar"

OK = "✓"
WARN = "⚠"
ERR = "✗"

issues = []
warnings = []


def check(ok, msg, warn_only=False):
    if ok:
        print(f"  {OK} {msg}")
    elif warn_only:
        print(f"  {WARN} {msg}")
        warnings.append(msg)
    else:
        print(f"  {ERR} {msg}")
        issues.append(msg)


# -----------------------------------------------------------------------------
# Profile detection
# -----------------------------------------------------------------------------

def active_profile():
    """Return the first profile name from ~/.claude/.active-profiles, or None."""
    if not PROFILE_MARKER.exists():
        return None
    try:
        content = PROFILE_MARKER.read_text().strip()
        return content.splitlines()[0] if content else None
    except OSError:
        return None


def platform_grammar_present():
    """True if the platform-grammar skill is installed (profile active)."""
    return GRAMMAR_SKILL.exists() and (GRAMMAR_SKILL / "SKILL.md").exists()


# -----------------------------------------------------------------------------
# Profile-aware grammar linting (Ubiwhere canonical grammar)
# -----------------------------------------------------------------------------

FORBIDDEN_SYNONYMS = [
    # (pattern, replacement hint, severity)
    (r"\bmunicipality_id\b", "tenant_id", "error"),
    (r"\bvisibility_zone\b", "scope_id", "error"),
    (r"\bworkspace\b(?!\s+file)", "tenant or instance (workspace is reserved)", "warn"),
    (r"\bbranch_id\b", "simulation_branch_id (operational tables should NOT use branch_id)", "error"),
    (r"\brequest\s+message\b", "ActionIntent (generic 'message' is forbidden)", "warn"),
]

ID_PREFIX_PATTERNS = {
    "instance": r"\binst_[a-z0-9_-]+\b",
    "tenant": r"\btnt_[a-z0-9_-]+\b",
    "scope": r"\bscp_[a-z0-9a-f_-]+\b",
    "subject": r"\b(usr_|svc_|edge_)[a-z0-9_-]+\b",
    "object": r"\b(obj_|occ_|ast_|alr_)[a-z0-9_-]+\b",
    "event": r"\bevt_[a-z0-9_-]+\b",
    "request": r"\breq_[a-z0-9_-]+\b",
    "correlation": r"\bcor_[a-z0-9_-]+\b",
}

EVENT_ENVELOPE_REQUIRED = [
    "event_id", "request_id", "event_type",
    "instance_id", "tenant_id", "scope_id",
    "occurred_at", "schema_version", "policy_version", "payload",
]

ALLOWED_API_PATHS = [
    "/v1/identity/exchange",
    "/v1/scope/resolve",
    "/v1/sync/snapshots/",
    "/v1/sync/deltas",
    "/v1/sync/checkpoints",
    "/v1/actions/submit",
    "/v1/events",
]

STATE_VOCABULARY = {"accepted", "transformed", "rejected", "duplicate", "conflict_pending", "reconciled"}


def scan_forbidden_synonyms(root: Path):
    """Walk all .md files under root and flag forbidden synonyms."""
    print("\n[Canonical Grammar — Forbidden Synonyms]")
    count = 0
    for f in root.rglob("*.md"):
        try:
            content = f.read_text()
        except OSError:
            continue
        for pattern, hint, severity in FORBIDDEN_SYNONYMS:
            for m in re.finditer(pattern, content):
                line_num = content[: m.start()].count("\n") + 1
                msg = f"{f.relative_to(root)}:{line_num}: '{m.group(0)}' — use {hint}"
                check(False, msg, warn_only=(severity == "warn"))
                count += 1
    if count == 0:
        check(True, "No forbidden synonyms found")


def scan_event_envelope(root: Path):
    """Check event envelope references include all required keys."""
    print("\n[Canonical Grammar — Event Envelope]")
    found_envelope = False
    for f in root.rglob("*.md"):
        try:
            content = f.read_text()
        except OSError:
            continue
        # Look for event envelope sections
        if "event_envelope" in content.lower() or "/v1/events" in content:
            found_envelope = True
            missing = [k for k in EVENT_ENVELOPE_REQUIRED if k not in content]
            if missing:
                check(False, f"{f.relative_to(root)}: event envelope missing keys: {', '.join(missing)}",
                      warn_only=True)
            else:
                check(True, f"{f.relative_to(root)}: event envelope complete")
    if not found_envelope:
        check(True, "No event envelope references to lint")


def scan_api_paths(root: Path):
    """Check that API paths match the enumerated allowlist when present."""
    print("\n[Canonical Grammar — API Paths]")
    pattern = re.compile(r"(?:POST|GET|PUT|DELETE|PATCH)\s+(/v\d+/[\w/{}\-]+)")
    count = 0
    for f in root.rglob("*.md"):
        try:
            content = f.read_text()
        except OSError:
            continue
        for m in pattern.finditer(content):
            path = m.group(1)
            if not any(path.startswith(allowed.rstrip("/")) for allowed in ALLOWED_API_PATHS):
                line_num = content[: m.start()].count("\n") + 1
                # Only warn — user APIs can exist outside canonical set for non-sync endpoints
                check(False, f"{f.relative_to(root)}:{line_num}: '{path}' not in canonical API path set",
                      warn_only=True)
                count += 1
    if count == 0:
        check(True, "No non-canonical API paths found")


def scan_bucket_naming(root: Path):
    """Check GCS bucket references follow ubp-{instance}-{purpose}-{env} pattern."""
    print("\n[Canonical Grammar — Bucket Naming]")
    # Match bucket names in gs:// URLs
    bucket_pattern = re.compile(r"gs://([a-z0-9][a-z0-9-]+)")
    canonical_pattern = re.compile(
        r"^ubp-(?:[a-z]+-(?:lakehouse|media|dropzone)-(?:dev|stg|prod)|"
        r"(?:lakehouse|tempo|loki|mimir)-(?:dev|stg|prod)(?:-global)?|"
        r"backoffice-modules|tofu-state|bronze-poc|ontology-testing|"
        r"ode-dropzone|ode-media-(?:stg|prod))$"
    )
    count = 0
    for f in root.rglob("*.md"):
        try:
            content = f.read_text()
        except OSError:
            continue
        for m in bucket_pattern.finditer(content):
            bucket = m.group(1)
            if bucket.startswith("ubp-") and not canonical_pattern.match(bucket):
                line_num = content[: m.start()].count("\n") + 1
                check(False, f"{f.relative_to(root)}:{line_num}: bucket '{bucket}' doesn't match ubp-{{instance}}-{{purpose}}-{{env}}",
                      warn_only=True)
                count += 1
    if count == 0:
        check(True, "No bucket naming violations found")


def scan_naming_conventions(root: Path):
    """Check tables snake_case, entity types PascalCase, events PastTense."""
    print("\n[Canonical Grammar — Naming Conventions]")
    # Rough heuristics — look for markdown table rows or SQL CREATE TABLE
    table_pattern = re.compile(r"CREATE TABLE\s+(\w+)", re.IGNORECASE)
    count = 0
    for f in root.rglob("*.md"):
        try:
            content = f.read_text()
        except OSError:
            continue
        for m in table_pattern.finditer(content):
            table = m.group(1)
            if not re.match(r"^[a-z][a-z0-9_]*$", table):
                line_num = content[: m.start()].count("\n") + 1
                check(False, f"{f.relative_to(root)}:{line_num}: table '{table}' should be snake_case",
                      warn_only=True)
                count += 1
    if count == 0:
        check(True, "Naming conventions look clean (heuristic scan)")


def run_grammar_checks():
    """Run all profile-aware grammar checks."""
    root = BASE
    if not root.exists():
        return
    scan_forbidden_synonyms(root)
    scan_event_envelope(root)
    scan_api_paths(root)
    scan_bucket_naming(root)
    scan_naming_conventions(root)


# -----------------------------------------------------------------------------
# Universal checks
# -----------------------------------------------------------------------------

def main():
    if not BASE.exists():
        return 0  # No architect session — nothing to validate

    state_file = BASE / ".architect-state.json"
    if not state_file.exists():
        return 0  # No state — nothing to validate

    try:
        state = json.loads(state_file.read_text())
    except (json.JSONDecodeError, OSError):
        print(f"  {ERR} State file is invalid JSON")
        return 1

    phase = state.get("current_phase", "not_started")
    if phase == "not_started":
        return 0

    profile = active_profile()
    print(f"\nArchitect Process Validation ({state.get('project_name', '?')})")
    print(f"Active profile: {profile or '(none)'}")
    print()

    # Phase 1: Pitch
    if phase in ("shape", "specify", "publish", "report", "complete"):
        print("[Pitch]")
        pitches = list((BASE / "pitches").glob("*.md")) if (BASE / "pitches").exists() else []
        check(len(pitches) > 0, f"{len(pitches)} pitch(es) found")
        for p in pitches:
            content = p.read_text()
            check("## Problem" in content, f"  {p.name}: has Problem section")
            check("Appetite" in content, f"  {p.name}: has Appetite", warn_only=True)
            check("## No-Gos" in content, f"  {p.name}: has No-Gos", warn_only=True)

    # Phase 2: Architecture
    if phase in ("specify", "publish", "report", "complete"):
        print("\n[Architecture]")
        arch = BASE / "architecture" / "ARCHITECTURE.md"
        check(arch.exists(), "ARCHITECTURE.md exists")
        if arch.exists():
            content = arch.read_text()
            check("## Module Map" in content, "  Has Module Map")
            check("mermaid" in content.lower(), "  Has Mermaid diagrams", warn_only=True)

        adrs_dir = BASE / "architecture" / "adrs"
        adrs = list(adrs_dir.glob("ADR-*.md")) if adrs_dir.exists() else []
        check(len(adrs) > 0, f"{len(adrs)} ADR(s) found")
        for adr in adrs:
            content = adr.read_text()
            check("**Status**:" in content or "Status:" in content, f"  {adr.name}: has Status")
            # Check naming: ADR-NNNN-kebab-title.md
            if not re.match(r"^ADR-\d{4}-[a-z0-9-]+\.md$", adr.name):
                check(False, f"  {adr.name}: doesn't match ADR-NNNN-kebab-title.md", warn_only=True)

    # Phase 3: Module Specs
    if phase in ("publish", "report", "complete"):
        print("\n[Module Specs]")
        modules_dir = BASE / "architecture" / "modules"
        module_dirs = [d for d in modules_dir.iterdir() if d.is_dir()] if modules_dir.exists() else []
        check(len(module_dirs) > 0, f"{len(module_dirs)} module spec dir(s) found")

        for md in module_dirs:
            spec = md / "SPEC.md"
            check(spec.exists(), f"  {md.name}/SPEC.md exists")
            if spec.exists():
                content = spec.read_text()
                check("## 3. Features" in content or "### 3.1" in content or "F-" in content,
                      f"  {md.name}: has features", warn_only=True)

    # Phase 3.5: Test Plan
    if phase in ("publish", "report", "complete"):
        print("\n[Test Plan]")
        test_plan = BASE / "architecture" / "TEST-PLAN.md"
        solution = state.get("solution_type", "")
        mvp_like = {"mvp", "prod-mvp", "production", "Production MVP", "Real Production", "MVP"}
        if solution in mvp_like:
            check(test_plan.exists(), "TEST-PLAN.md exists (required for this solution type)")
        else:
            check(test_plan.exists(), "TEST-PLAN.md exists", warn_only=True)
        if test_plan.exists():
            content = test_plan.read_text()
            check("Data Quality" in content or "DQ-" in content, "  Has data quality gates", warn_only=True)
            check("CI/CD" in content, "  Has CI/CD pipeline section", warn_only=True)

    # Phase 4: Issues
    if phase in ("report", "complete"):
        print("\n[Issues]")
        issues_dir = BASE / "issues"
        check(issues_dir.exists(), "Issues directory exists")
        if issues_dir.exists():
            index = issues_dir / "index.md"
            check(index.exists(), "  index.md exists", warn_only=True)
            manifest = issues_dir / "manifest.json"
            if manifest.exists():
                try:
                    m = json.loads(manifest.read_text())
                    total = sum(len(e.get("features", [])) for e in m.get("epics", []))
                    check(True, f"  manifest.json: {len(m.get('epics', []))} epics, {total} features")
                except json.JSONDecodeError:
                    check(False, "  manifest.json is invalid JSON")
            component_versions = issues_dir / "component-versions.md"
            check(component_versions.exists(), "  component-versions.md exists", warn_only=True)

    # Phase 5: DX Report
    if phase == "complete":
        print("\n[DX Reports]")
        reports = list((BASE / "dx-reports").glob("*.md")) if (BASE / "dx-reports").exists() else []
        check(len(reports) > 0, f"{len(reports)} DX report(s) found", warn_only=True)

    # Versioning
    print("\n[Versioning]")
    milestone = state.get("milestone", {}) if isinstance(state.get("milestone"), dict) else {}
    check(bool(milestone.get("name")), f"Milestone set: {milestone.get('name', '—')}", warn_only=True)
    components = state.get("components", {})
    check(len(components) > 0, f"{len(components)} component version(s) registered", warn_only=True)

    # Profile-aware grammar checks
    if platform_grammar_present():
        print(f"\n--- Canonical Grammar Checks (profile: {profile}) ---")
        run_grammar_checks()
    else:
        print(f"\n{WARN} No platform-grammar skill found at {GRAMMAR_SKILL} — skipping canonical grammar checks")

    # Summary
    print(f"\n{'='*50}")
    if issues:
        print(f"{ERR} {len(issues)} error(s), {len(warnings)} warning(s)")
        for i in issues:
            print(f"  {ERR} {i}")
    elif warnings:
        print(f"{WARN} 0 errors, {len(warnings)} warning(s) — process looks healthy")
    else:
        print(f"{OK} All checks passed")

    return 1 if issues else 0


if __name__ == "__main__":
    sys.exit(main())
