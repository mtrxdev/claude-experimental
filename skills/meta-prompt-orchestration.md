---
name: meta-prompt-orchestration
description: Execution flow and decision tree for the meta-prompt skill. Use when implementing, debugging, tracing, or extending the meta-prompt skill's behaviour. Companion to the meta-prompt skill — load alongside it when you need to understand exactly what the skill does at each step.
---

# meta-prompt — Orchestration Chronology

Companion to `skills/meta-prompt.md`. Documents the runtime execution flow of that skill.

Execution sequence for every invocation of the meta-prompt skill.

---

```
1. RECEIVE
   → In scope?
       No  → "This cannot be fixed at the prompt level. The problem is [X]. Address that separately." STOP.
       Yes → 2.

2. IDENTIFY ROLE
   → Clear from context?
       Yes → 3.
       No  → Ask: "What's your role? 1. Developer/engineer  2. PM/designer  3. End user  4. Stakeholder"
             Wait for selection → 3.

3. GATHER INFO  (Task / Surface / Output / Constraints / Existing prompt)
   → All 5 known?
       Yes → 4.
       No  → Ask for missing items (max 3 per turn, numbered choices).
             Wait for answers → loop to 3.

4. TOOL CHECK
   → Task involves Claude tools (web search, code execution, computer use, memory, files, MCP…)?
       Yes → identify which tool(s), mark URL(s) for fetch → 5.
       No  → 5.

5. FETCH DOCS
   → Version-sensitive feature or tool-specific question?
       Yes → fetch release notes first, then most specific URL.
             Flag output: "Note: verify against release notes — behavior may differ by version."
       No  → fetch most specific matching URL.
       No matching URL → "The documentation does not cover this. Check [URL] directly." STOP.
   → 6.

6. FOUR Ds CHECK  (internal — do not surface as prose)
   → Delegation: AI scope vs user scope explicit? Edge-case escalation defined?
   → Description: precise enough that two readers produce identical output?
   → Discernment: explicit "I don't know" path or confidence threshold present?
   → Diligence: privacy, accuracy, bias guardrails written in (not assumed)?
   Any gap?
       Yes → surface as numbered-choice question. Wait for answer → loop to 6.
       No  → 7.

7. CHOOSE STRUCTURE
   → Simple single-step task               → plain instruction
   → Role + defined output needed          → role + task + constraints + format
   → Multiple inputs or parsed output      → labelled sections with headers

8. DRAFT
   → Write prompt using chosen structure.
   → After each major element, add on the next line:
       [Label: one-line rationale]

9. DELIVER
   → Output:
       ```
       [prompt]
       ```
       Risk note: [highest-priority Four Ds gap]
   → If role-calibrated: "Calibrated for [role]: [what was included or omitted]"
   → If version-sensitive: "Note: verify against release notes — behavior may differ by version."
   → No preamble. No sign-off. No restatement of request. STOP.
```

---

## Loop map

```
3 ←──────────────────────────┐
↓                            │ missing info
4 → 5 → 6 ←─────────────────┤
          ↓                  │ Four Ds gap
          7 → 8 → 9  STOP   │
                    ↑        │
          gap found ─────────┘
```
