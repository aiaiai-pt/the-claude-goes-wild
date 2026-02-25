---
name: threat-model
description: Analyze a shaped pitch or spec for security implications using STRIDE
---

# Threat Model

Analyze the security implications of the current spec or shaped pitch. $ARGUMENTS

## Process

1. **Locate the spec**: Find the relevant spec or shaped pitch in:
   - dev_docs/specs/
   - The file specified in arguments
   - If no spec exists, analyze the current feature branch changes

2. **Map the system**:
   - Identify all data flows (what data moves where, in what format)
   - Identify trust boundaries (user → frontend → API → database → external service)
   - Identify entry points (API endpoints, webhooks, file uploads, user inputs)
   - Identify data stores (databases, caches, files, env vars, secrets)
   - Identify external dependencies (third-party APIs, auth providers, CDNs)

3. **STRIDE analysis per component**:

   For each component that crosses a trust boundary, analyze:
   - **S**poofing: Can an attacker impersonate a legitimate user or service?
   - **T**ampering: Can data be modified in transit or at rest?
   - **R**epudiation: Can actions be performed without audit trail?
   - **I**nformation Disclosure: Can sensitive data leak through logs, errors, or side channels?
   - **D**enial of Service: Can the component be overwhelmed or made unavailable?
   - **E**levation of Privilege: Can a lower-privilege actor gain higher access?

4. **Classify data sensitivity**:
   - **Public**: No protection required
   - **Internal**: Access control required
   - **Confidential**: Encryption at rest + in transit, audit logging
   - **Restricted**: All of Confidential + data minimization, retention limits, breach notification

5. **Rate each threat**:
   - Likelihood: Low / Medium / High (based on attack complexity and exposure)
   - Impact: Low / Medium / High / Critical (based on data sensitivity and blast radius)
   - Risk = Likelihood x Impact
   - For each High/Critical risk: specify a concrete mitigation

6. **Produce output**:

```
## Threat Model: [Feature Name]

### Data Classification
| Data Element | Classification | Notes |
|-------------|---------------|-------|

### Attack Surface Delta
- New entry points: [list]
- Changed entry points: [list]
- New data stores: [list]
- New external dependencies: [list]

### Threats
| ID | Component | STRIDE | Threat | Likelihood | Impact | Risk | Mitigation |
|----|-----------|--------|--------|-----------|--------|------|------------|

### Security Requirements
- [ ] [Specific requirement derived from threats]

### Compliance Triggers
- [Standard]: [Why this bet triggers it, what's required]

### Rabbit Holes
- [Threats rated High/Critical that need resolution during SHAPE]
```

## Rules

- Every trust boundary crossing MUST be analyzed — no shortcuts
- Focus on exploitable threats, not theoretical ones
- Mitigations must be specific and actionable ("add rate limiting to /api/auth" not "consider rate limiting")
- If the spec doesn't mention auth/authz for a new endpoint, flag it as a gap
- If the spec involves user input, assume it will be malicious
- Data classification drives encryption and access control requirements — never skip it
- Threats rated High/Critical become rabbit holes in the spec — they must be resolved before BUILD
