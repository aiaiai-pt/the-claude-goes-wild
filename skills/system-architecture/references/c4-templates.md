# C4 Mermaid Templates

Generic templates. For stack-specific container defaults, load the active
`platform-stack` skill — it will list the canonical containers for your stack.

## Level 1 — System Context

```mermaid
C4Context
    title System Context: {System Name}

    Person(end_user, "End User", "Primary user persona")
    Person(operator, "Operator", "Staff persona")
    Person(admin, "Platform Admin", "Ops persona")

    System(system, "{System Name}", "Description of what this system does")

    System_Ext(ext_system_1, "External System 1", "Description")
    System_Ext(ext_system_2, "External System 2", "Description")

    Rel(end_user, system, "Uses", "HTTPS")
    Rel(operator, system, "Manages", "HTTPS")
    Rel(system, ext_system_1, "Integrates with", "Protocol")
```

## Level 2 — Container

```mermaid
C4Container
    title Container Diagram: {System Name}

    Person(user, "User", "")

    Container_Boundary(system, "{System Name}") {
        Container(frontend, "Frontend", "{tech}", "User-facing UI")
        Container(api, "API Service", "{tech}", "Business logic")
        ContainerDb(db, "Database", "{tech}", "Persistent state")
    }

    System_Ext(auth, "Identity Provider", "OIDC")
    System_Ext(events, "Event Backbone", "Messaging")
    System_Ext(obs, "Observability", "Metrics/logs/traces")

    Rel(user, frontend, "Uses", "HTTPS")
    Rel(frontend, api, "Calls", "REST/JSON")
    Rel(api, db, "Reads/writes", "SQL")
    Rel(api, auth, "Validates tokens", "OIDC")
    Rel(api, events, "Pub/sub", "Protocol")
    Rel_L(api, obs, "Telemetry", "OTLP")
```

## Level 3 — Component (use sparingly)

```mermaid
C4Component
    title Component Diagram: {Container Name}

    Container_Boundary(api, "{Container}") {
        Component(router, "Router", "{framework}", "HTTP routing")
        Component(auth_mw, "Auth Middleware", "{framework}", "Token validation")
        Component(service, "Domain Service", "{language}", "Business logic")
        Component(repo, "Repository", "{language}", "Data access")
    }

    ContainerDb(db, "Database", "{tech}", "")
    Container_Ext(authz, "Authorization", "{tech}", "Permission checks")

    Rel(router, auth_mw, "Validates request")
    Rel(auth_mw, authz, "Checks permission")
    Rel(router, service, "Delegates")
    Rel(service, repo, "Queries/persists")
    Rel(repo, db, "SQL")
```

## Dynamic Diagram — Sequence

```mermaid
sequenceDiagram
    participant U as User
    participant FE as Frontend
    participant API as API Service
    participant AUTH as Identity Provider
    participant DB as Database

    U->>FE: Action
    FE->>API: Request
    API->>AUTH: Validate token
    AUTH-->>API: Token valid
    API->>DB: Query
    DB-->>API: Result
    API-->>FE: Response
    FE-->>U: Rendered output
```

## Tips
- Use `C4Context`, `C4Container`, `C4Component` Mermaid directives
- Keep Level 1 to ≤ 10 boxes
- Keep Level 2 to ≤ 15 boxes
- Level 3 only for the most complex container
- Always include the auth flow
- Always show the observability path
- Use `System_Ext` for anything outside your system boundary

## Profile Overrides

When a platform profile is active, it typically provides richer templates with
canonical container defaults (e.g., the Ubiwhere profile includes medallion
lakehouse containers, Keycloak+SpiceDB auth, Kafka event backbone). Load the
profile's `platform-stack` references for the canonical set.
