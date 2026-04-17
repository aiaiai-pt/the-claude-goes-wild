# Feature Specification Template

Use this within a module SPEC.md for each feature. Stack-specific guidance in
the Technical Approach section comes from the active `platform-stack` skill.

```markdown
### F-{nn}.{m}: {Feature Title}

**Priority**: must-have | ~nice-to-have
**Appetite**: {days within module budget}
**Service**: {which container/service}

#### User Story
As a {role},
I want to {action},
so that {outcome}.

#### Acceptance Criteria
- [ ] Given {precondition}, when {action}, then {expected result}
- [ ] Given {precondition}, when {action}, then {expected result}
- [ ] Given {error condition}, when {action}, then {error handling}

#### Technical Approach

**Stack**: {primary technology from active platform-stack profile}
**Auth**: {identity + authorization check}
**Events**: {topic produced/consumed, if any}
**Data Layer**: {which storage layer(s) this touches}

{2-4 sentences of opinionated implementation guidance, referencing specific
patterns from the active profile.}

#### API Contract (if this feature exposes an endpoint)
```http
POST /api/v1/{resource}
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "string",
  "metadata": {}
}

→ 201 Created
{
  "id": "uuid",
  "name": "string",
  "created_at": "ISO8601"
}

→ 403 Forbidden (authorization denied)
→ 422 Unprocessable Entity (validation)
```

#### Dependencies
- **Blocked by**: {F-nn.m or M-nn — what must exist first}
- **Blocks**: {F-nn.m — what depends on this}

#### Out of Scope
- {Explicit exclusion — e.g., "No bulk import in this feature"}

#### Verification
{How a developer or QA verifies this works:}
1. {Step 1}
2. {Step 2}
3. {Expected outcome}
```

## Sizing Guide

| Feature Size | Typical Duration | Signals |
|-------------|-----------------|---------|
| **XS** | < 0.5 day | Config change, copy update, simple CRUD |
| **S** | 0.5–1 day | Single endpoint, single UI component, basic event |
| **M** | 1–2 days | Multi-step flow, API + event + UI, auth integration |
| **L** | 2–3 days | Complex business logic, multi-service coordination |
| **XL** | > 3 days | ⚠ Split into smaller features |
