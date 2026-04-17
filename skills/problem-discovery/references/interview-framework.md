# Interview Framework

## Phase 1: Problem Understanding (5-10 min)

### Opening Questions
1. **"What's the problem you're trying to solve?"**
   - Listen for: pain frequency, severity, who's affected
   - Follow up: "How often does this happen? What's the impact when it does?"

2. **"What triggered this — why now?"**
   - Listen for: customer complaint, new regulation, business opportunity, tech debt
   - Follow up: "What happens if we don't solve this in the next quarter?"

3. **"Who are the people affected?"**
   - Map: end users, operators, admins, staff, customers
   - Follow up: "Which of these groups feels the most pain?"

## Phase 2: Current State (5 min)

4. **"How is this handled today?"**
   - Manual process? Spreadsheet? Another system? Not handled at all?

5. **"What existing systems/components touch this?"**
   - Integration surface, data sources, existing APIs

6. **"What data exists today that's relevant?"**
   - Where does it live, who owns it, how accessible is it

## Phase 3: Constraints (5 min)

7. **"What's the timeline pressure?"**
   - Procurement deadline? Demo date? Go-live commitment?

8. **"What's the team situation?"**
   - Available developers? Skillset gaps? Other commitments?

9. **"Any regulatory or compliance requirements?"**
   - Privacy, security standards, industry-specific regulations

## Phase 4: Appetite Calibration (5 min)

10. **"If I told you this would take 6 weeks with 2-3 devs, would you say that's too much, about right, or too little for the value it delivers?"**
    - This surfaces the true appetite

11. **"What's the minimum version of this that would make you happy?"**
    - This is the scope-hammered core

12. **"What would you cut if you had to ship in half the time?"**
    - This reveals must-haves vs nice-to-haves

## Profile Probes

When a platform profile is active, add profile-specific probes here. For example,
the Ubiwhere profile adds:
- Domain vertical (mobility, energy, water, waste, incidents, IoT)
- Tenant scope (which instances / municipalities)
- Platform-capability vs vertical-feature classification

Load the profile's `platform-stack` skill references to discover the probes.

## Anti-Patterns to Watch For

| Signal | What It Means | What to Do |
|--------|--------------|------------|
| "We need a complete redesign" | Grab-bag, not a project | Narrow to specific pain point |
| "It should be like {competitor}" | Solution, not problem | Ask what problem that solves |
| "Just a small change" | Scope is hiding | Ask about edge cases |
| "This is urgent for everyone" | No prioritization | Force-rank stakeholders |
| "We'll figure out the details later" | Rabbit holes ahead | Spike first |
