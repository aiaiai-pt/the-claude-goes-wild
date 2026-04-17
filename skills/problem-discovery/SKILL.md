---
name: problem-discovery
description: >
  Structured problem discovery framework using Shape Up methodology. Provides
  interview templates, appetite calibration, and pitch writing guidance.
  Use when conducting problem interviews or writing Shape Up pitches.
---

# Problem Discovery Skill

## When to Use
- Starting a new project, feature, or platform capability
- Conducting stakeholder interviews
- Writing or reviewing Shape Up pitches
- Calibrating appetite for a piece of work

## Process

1. Load `references/interview-framework.md` for the interview question bank
2. Load `references/appetite-levels.md` for appetite calibration matrix
3. If the active profile defines platform-specific probes, load those too (e.g.,
   the Ubiwhere profile adds domain-vertical and multi-tenancy probes)
4. Conduct the interview following the framework
5. Calibrate appetite using the matrix
6. Write the pitch using the template below

## Pitch Template

```markdown
# Pitch: {Title}

**Date**: {YYYY-MM-DD}
**Appetite**: {0-3} — {Spike|Small Batch|Big Batch|Multi-cycle} ({time budget})
**Solution Type**: {Dev|Prototype|MVP|Production MVP|Real Production}
**Author**: {who shaped this}

## Problem
{1-2 paragraphs. Be specific about WHO has the problem and WHY it matters NOW.}

## Appetite
{Why this level. What happens if we invest more? Less? What's the "circuit breaker"?}

## Solution Direction
{Rough sketch. Fat-marker level. Enough to evaluate feasibility, not enough to implement.
Use breadboarding (flow/affordance sketches) or fat-marker wireframes.}

## Rabbit Holes
{Specific unknowns that could blow up scope. For each, note the mitigation:
- Will we spike first?
- Will we timebox exploration?
- Will we cut if it's too hard?}

## No-Gos
{Things we are explicitly NOT building, even if someone asks.}

## Stakeholders
| Role | Who | Primary Concern |
|------|-----|-----------------|
```

## Gotchas
- Don't let "solution direction" become a detailed spec — keep it rough
- Appetite is a CONSTRAINT, not an estimate — the solution must fit the appetite
- If you can't narrow the problem enough for the appetite, the problem isn't shaped yet
- Nice-to-haves marked with ~ are the first things cut during scope hammering
