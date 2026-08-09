# Death Idle Planning Architect Session Handover

**Handover date/time:** [[YYYY-MM-DD HH:MM TZ]]
**Outgoing session coverage:** [[START DATE/TOPIC]] to [[END DATE/TOPIC]]
**Current project phase:** [[PHASE]]
**Parent milestone or sequence:** [[SEQUENCE]]
**Active bounded slice or task:** [[SLICE/TASK]]
**Current lifecycle stage:** [[PLANNING / ASSESSMENT / IMPLEMENTATION / CI / REVIEW / TRIAGE / CORRECTION / FINAL REVIEW / OWNER VERIFICATION / INTEGRATION / CLOSURE]]
**One-line cutoff:** [[LAST COMPLETED OPERATION -> NEXT WORKFLOW ACTION (EXECUTION OWNER); PLANNING ARCHITECT RESPONSIBILITY]]

## 1. Role and operating boundary

The successor is the long-lived planning architect.

**In scope now:**

- [[CURRENT PLANNING, RECONCILIATION, ROUTING, OR ESCALATION RESPONSIBILITIES]]

**Out of scope now:**

- implementation or direct repository edits;
- independent assessment of the planning architect's own material packet;
- routine PR-lifetime finding triage;
- independent review of work for which this architect is the sole planning authority;
- owner-only integration, destructive cleanup, force operations, credentials, governance, or spending;
- [[ANY CURRENT ADDITIONAL BOUNDARY]].

## 2. Exact authority map

Fetch these sources at their current refs. Do not rely on copied excerpts.

| Priority | Source | Exact heading, decision ID, packet version, PR, run, or thread | Why it applies | Authority band |
|---:|---|---|---|---|
| 1 | Latest owner instruction | [[EXACT INSTRUCTION OR APPROVAL]] | Current owner authority | Current authority |
| 2 | `docs/codex/ARCHITECT_HANDOVER_STANDARD.md` | Full file | Continuity rules | Stable policy |
| 3 | `docs/codex/STANDARD_MILESTONE_SLICE_WORKFLOW.md` | [[EXACT SECTIONS]] | Actor and lifecycle boundary | Stable policy |
| 4 | `docs/codex/QUANTITATIVE_SCOPE_BUDGETS_AND_ANTI_BLOAT_GUARDRAILS.md` | [[EXACT SECTIONS RELEVANT TO THE CUTOFF; normally §§3–9 and 15–16, plus §§10–14 when packet, correction, exception, or convergence work is active]] | Concept budgets, categorized measurement, reassessment thresholds, exceptions, anti-bloat rules, and quantitative convergence inputs | Stable policy |
| 5 | `docs/codex/ACTOR_PROMPT_STANDARD.md` | [[EXACT SECTIONS, IF A HANDOFF PROMPT IS NEXT]] | Model/effort/session routing | Stable policy |
| 6 | `docs/codex/DECISIONS.md` | [[DECISION IDS]] | Current accepted decisions | Current authority |
| 7 | `docs/codex/MILESTONES.md` | [[EXACT MILESTONE/STATUS SECTION]] | Current sequence and status | Current authority |
| 8 | `docs/codex/ARCHITECTURE.md` or exact contract | [[EXACT SECTION]] | Current architecture or contract boundary | Current authority |
| 9 | [[ACTIVE PLANNING MEMO]] | [[VERSION/SECTIONS]] | Active planning contract | Approved planning authority |
| 10 | [[ACTIVE SLICE PACKET]] | [[VERSION/SECTIONS]] | Current executable scope, when relevant | Approved packet |
| 11 | [[VALIDATED WORKFLOW-STATE ARTIFACT, IF AVAILABLE]] | [[ARTIFACT/GENERATED TIME]] | Mutable state actually proven by the artifact | Operational state |
| 12 | [[ACTIVE PR/CI/REVIEW/OWNER SOURCE]] | [[NUMBER/HEAD/RUN/THREAD/LOG]] | Continuation evidence not covered above | Operational state |

**Historical or superseded source permitted for one exact question:**

- [[SOURCE AND QUESTION, OR `None`]]

## 3. Source-labelled mutable state

Include only facts needed for continuation. Delete irrelevant rows.

| Fact | Current value | Label | Verified/reported at | Canonical source | Consequence if stale |
|---|---|---|---|---|---|
| `main` / `origin/main` | [[REF OR UNKNOWN]] | [[REPO_VERIFIED / UNVERIFIED]] | [[TIME]] | [[SOURCE]] | [[CONSEQUENCE]] |
| Active branch | [[BRANCH OR NONE/UNKNOWN]] | [[LABEL]] | [[TIME]] | [[SOURCE]] | [[CONSEQUENCE]] |
| Active PR and current head | [[PR/HEAD OR NONE]] | [[LABEL]] | [[TIME]] | [[SOURCE]] | [[CONSEQUENCE]] |
| CI at current head | [[STATE/RUN OR NONE]] | [[LABEL]] | [[TIME]] | [[SOURCE]] | [[CONSEQUENCE]] |
| Primary/final review | [[STATE OR NONE]] | [[LABEL]] | [[TIME]] | [[SOURCE]] | [[CONSEQUENCE]] |
| PR-lifetime triage and correction round | [[STATE OR NONE]] | [[LABEL]] | [[TIME]] | [[SOURCE]] | [[CONSEQUENCE]] |
| Active concept/quantitative budget | [[PACKET BUDGET OR DELETE WHEN IRRELEVANT]] | [[LABEL]] | [[TIME]] | [[SOURCE]] | [[CONSEQUENCE]] |
| Current governed surface and threshold state | [[TOTALS/REVIEW ZONE/REASSESSMENT STATE OR DELETE]] | [[LABEL]] | [[TIME]] | [[SOURCE]] | [[CONSEQUENCE]] |
| Approved exception or delegated variance | [[EXACT RANGE/RECORD OR NONE/DELETE]] | [[LABEL]] | [[TIME]] | [[SOURCE]] | [[CONSEQUENCE]] |
| Unresolved material review threads | [[STATE/THREADS OR NONE]] | [[LABEL]] | [[TIME]] | [[SOURCE]] | [[CONSEQUENCE]] |
| Owner verification | [[PASS/FAIL/PENDING/NOT APPLICABLE]] | [[LABEL]] | [[TIME]] | [[SOURCE]] | [[CONSEQUENCE]] |
| Integration/cleanup | [[STATE OR NOT STARTED]] | [[LABEL]] | [[TIME]] | [[SOURCE]] | [[CONSEQUENCE]] |
| Local working tree | [[STATE OR UNVERIFIED]] | [[LABEL]] | [[TIME]] | [[SOURCE]] | [[CONSEQUENCE]] |
| Active external session | [[SESSION/STATE OR UNKNOWN]] | [[LABEL]] | [[TIME]] | [[SOURCE]] | [[CONSEQUENCE]] |

## 4. Net session delta

Record accepted outcomes and unresolved decisions, not the path taken to reach them.

| Outcome or decision | Final status | Why it changes current planning | Durable location or `SESSION_ONLY` |
|---|---|---|---|
| [[DELTA 1]] | [[ACCEPTED / IMPLEMENTED / MERGED / REJECTED / SUPERSEDED / OPEN]] | [[IMPLICATION]] | [[PATH/DECISION/PR/THREAD]] |
| [[DELTA 2]] | [[STATUS]] | [[IMPLICATION]] | [[LOCATION]] |
| [[DELTA 3]] | [[STATUS]] | [[IMPLICATION]] | [[LOCATION]] |

**Material session conclusions not yet persisted:**

- [[CONCLUSION + WHY IT IS STILL SESSION_ONLY, OR `None`]]

## 5. Current cutoff and next-step chain

**Parent milestone or sequence:** [[SEQUENCE]]
**Current bounded slice or task:** [[SLICE/TASK]]
**Current lifecycle stage:** [[STAGE]]
**Last completed bounded operation:** [[OPERATION AND EVIDENCE]]
**Current blocking fact or decision:** [[BLOCKER OR `None`]]
**Single next workflow action:** [[ONE ACTION]]
**Execution owner:** [[ACTOR]]
**Planning architect's immediate responsibility:** [[VERIFY / PREPARE / ROUTE / ASSESS / AWAIT / ESCALATE; DO NOT SUBSTITUTE FOR EXECUTION OWNER]]
**Required authorization:** [[AUTHORIZATION OR `None`]]

**Expected next transitions after the immediate action:**

```text
[[CURRENT STAGE]]
-> [[NEXT 1]]
-> [[NEXT 2]]
-> [[NEXT 3, IF KNOWN]]
```

**Completion condition for the current bounded task:**

- [[CONDITION]]

**Escalation or stop condition:**

- [[CONDITION]]

## 6. Active actor and session routing

List only active or next likely actors.

| Actor/task | Recommended model | Effort | Session | Session rationale | Current state | Next handoff |
|---|---|---|---|---|---|---|
| Planning architect successor | ChatGPT Sol Pro | High | `FRESH` | Context rollover with durable continuity | This handover | [[NEXT PLANNING RESPONSIBILITY]] |
| [[ACTOR]] | [[MODEL]] | [[EFFORT]] | [[FRESH / EXISTING: NAME / FRESH THEN PR-LIFETIME / PLATFORM INVOCATION / OWNER ACTION]] | [[WHY]] | [[STATE]] | [[HANDOFF]] |

## 7. Open decisions, blockers, and risks

| Item | Decision owner | Evidence already available | Exact decision or evidence still needed | Blocks |
|---|---|---|---|---|
| [[ITEM OR `None`]] | [[OWNER]] | [[EVIDENCE]] | [[NEEDED]] | [[WHAT]] |

Do not silently resolve these items in the handover.

## 8. Superseded routes and prohibited reuse

Include only items that remain a credible drift risk.

- [[SUPERSEDED PLAN/PROMPT/IMPLEMENTATION]]: [[CURRENT CONTROLLING AUTHORITY AND PROHIBITION]]
- [[ITEM OR DELETE]]

## 9. Pending prompts and session-only artifacts

**Pending prompt inventory:**

| Prompt or artifact | Purpose | Model | Effort | Session | Location | Why it is not already durable |
|---|---|---|---|---|---|---|
| [[ITEM OR `None`]] | [[PURPOSE]] | [[MODEL]] | [[EFFORT]] | [[SESSION]] | [[FILE/CHAT SECTION]] | [[REASON]] |

Do not include old prompts merely for history. Include a paste-ready prompt only when it is the immediate next action and is not already stored in the repository or PR.

**Optional package files:**

- [[FILENAME + JUSTIFICATION, OR `None`]]

## 10. Facts requiring reverification

- [[MUTABLE FACT]] — verify from [[SOURCE]] before [[DEPENDENT ACTION]].
- [[UNVERIFIED OR OWNER_REPORTED FACT, OR `None`]].

## 11. Successor first-turn completion test

Before advancing work, the successor must be able to state:

1. current durable authority;
2. net outgoing-session delta;
3. parent milestone or sequence;
4. active bounded task and lifecycle stage;
5. last completed bounded operation;
6. single next workflow action;
7. execution owner and planning architect responsibility as separate fields;
8. required model, effort, and session routing;
9. current owner-only boundary;
10. applicable concept/quantitative boundary or approved exception, when relevant;
11. prohibited restoration or reuse;
12. mutable facts that remain unverified.
