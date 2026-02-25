---
name: contract-test
description: Generate or verify API contract tests for consumer-provider pairs
---

# Contract Test

Generate or verify API contract tests for the specified endpoints. $ARGUMENTS

## Process

1. **Identify API contracts in scope**:
   - If arguments specify endpoints: use those
   - If invoked during BUILD: target new or changed API endpoints
     (`git diff` for route files, controller changes, schema changes)
   - Detect existing contract definitions:
     - OpenAPI/Swagger specs
     - GraphQL schemas
     - gRPC proto files
     - Pact contract files
     - AsyncAPI specs (for event-driven APIs)
   - Identify consumer-provider pairs: who calls this API?

2. **For new endpoints — generate consumer contracts**:
   - From the OpenAPI spec or route definition, extract:
     - Request: method, path, headers, query params, body schema
     - Response: status codes, body schema, headers
     - For each status code (200, 400, 401, 403, 404, 500)
   - Generate Pact consumer tests (or equivalent) that:
     - Define the expected interaction (request → response)
     - Assert on response status, body structure, and required fields
     - Cover: happy path, validation error, auth error, not found
   - **Signal**: consumer test pass/fail

3. **For changed endpoints — verify existing contracts**:
   - Run Pact verify (or equivalent) against existing consumer contracts
   - **Signal**: verification pass/fail per consumer-provider pair
   - For each failure:
     - Identify what broke: missing field, changed type, removed endpoint,
       changed status code, new required parameter
     - Classify: breaking change vs. additive change
     - Breaking change → contract needs version bump + consumer notification
     - Additive change → safe, contracts should still pass

4. **For event-driven APIs** (if applicable):
   - Identify event schemas (AsyncAPI, JSON Schema, Avro)
   - Verify: published events match the declared schema
   - Verify: consumers can deserialize the event
   - Check backward/forward compatibility of schema changes
   - **Signal**: schema compatibility check pass/fail

5. **Validate contract quality**:
   - Contracts must assert on STRUCTURE (required fields, types),
     not on CONTENT (specific values) unless those values are constants
   - Contracts must cover error responses, not just happy path
   - Contracts must be independent — no shared state between tests
   - Contracts must be executable without the real provider running
     (using recorded interactions or mocks)

6. **Produce report**:

```
## Contract Test Report
**Date**: YYYY-MM-DD
**Scope**: [endpoints]

## Consumer Contracts
| Consumer | Provider | Endpoint | Status | Breaking Change? |
|----------|----------|----------|--------|-----------------|

## New Contracts Generated
| Endpoint | Method | Interactions | Tests |
|----------|--------|-------------|-------|

## Broken Contracts
| Consumer | Provider | Endpoint | What Broke | Severity |
|----------|----------|----------|-----------|----------|

## Schema Compatibility (Event-Driven)
| Event | Change Type | Backward Compatible | Forward Compatible |
|-------|------------|--------------------|--------------------|

## Verdict
- Contracts verified: N
- Contracts broken: N
- New contracts generated: N
- **PASS / FAIL** (FAIL if any breaking change without version bump)
```

## Rules

- Contract tests verify the INTERFACE, not the implementation
- Assert on structure and required fields, not specific data values
- Breaking changes (removed fields, changed types, removed endpoints) BLOCK SHIP
- Additive changes (new optional fields, new endpoints) are always safe
- Every new public API endpoint must have at least one consumer contract
- If no consumer exists yet, generate a contract from the OpenAPI spec as the "canonical" consumer
- Schema changes in event-driven APIs must be checked for backward compatibility —
  old consumers must be able to read new events
- Contract tests run WITHOUT the real provider — they use recorded interactions
- Never auto-fix a broken contract by weakening it. Fix the provider or version the API.
