# Death Idle Quantitative Scope Budgets and Anti-Bloat Guardrails

**Status:** Owner-approved durable policy
**Repository path:** `docs/codex/QUANTITATIVE_SCOPE_BUDGETS_AND_ANTI_BLOAT_GUARDRAILS.md`
**Policy revision:** 1.2
**Effective date:** 2026-08-09
**Document role:** Single semantic owner for quantitative review-surface budgets, concept budgets, threshold exceptions, and anti-bloat rules
**Applies to:** Planning memos, versioned slice packets, implementation work, correction packets, PR triage, review, owner-verification tooling, architect-handover continuity, and governance/documentation changes
**Companion authority:** `AGENTS.md`, `STANDARD_MILESTONE_SLICE_WORKFLOW.md`, `ACTOR_PROMPT_STANDARD.md`, `ARCHITECT_HANDOVER_STANDARD.md`, `PROMPT_TEMPLATE.md`, `IMPLEMENTATION_RULES.md`, `MILESTONES.md`, and the active owner-approved slice packet

This document supersedes the 2026-08-08 working planning artifact with the same subject. Historical packet-specific exceptions retain their recorded meaning and do not become project-wide defaults.

---

## 1. Purpose

Death Idle uses quantitative scope budgets to detect unplanned growth, over-engineering, and bulk coding before they become the path of least resistance.

The governing rule is:

> Use the smallest **complete, clear, and independently reviewable** solution—not the fewest physical lines and not the largest reusable framework.

Quantitative budgets are **no-silent-crossing reassessment boundaries**. They are not semantic completion criteria, code-golfing targets, or automatic merge gates.

This policy separates four controls:

1. **hard authority boundaries** — semantic limits that cannot be crossed without explicit approval;
2. **concept budgets** — the types of new ideas, owners, APIs, or abstractions a task may introduce;
3. **categorized quantitative budgets** — forecast and measured review surface by kind of change;
4. **acceptance and evidence floors** — behavior and proof that may not be weakened to fit a number.

This document owns only quantitative review-surface, concept-budget, threshold-exception, and anti-gaming semantics. Actor roles, lifecycle, review materiality, convergence authority, prompt/session routing, and output proportionality remain owned by `STANDARD_MILESTONE_SLICE_WORKFLOW.md` and `ACTOR_PROMPT_STANDARD.md`; any summary of those subjects here is subordinate to those authorities.

This policy governs repository review surface. It does not relax a slice packet's byte ceiling or an actor response's output ceiling. When a complete authority or handoff cannot fit those delivery constraints without ambiguity or omission, the design or artifact must be revised rather than compressed.

---

## 2. Why this policy exists

The project must prevent two opposite failure modes.

### 2.1 Uncontrolled growth

An implementation or fixer may respond to a bounded requirement by adding:

- a generalized framework instead of a local solution;
- another validator, coordinator, cache, service, or abstraction layer;
- speculative extension points;
- duplicated semantic authority;
- broad cleanup or refactoring unrelated to acceptance;
- large amounts of generated code because generation is easier than diagnosis;
- tests that mirror production logic rather than independently disproving defects.

A small diff can still violate authority. A large diff can still be appropriate when it is explicit evidence for a finite approved contract. Physical size is a signal, not the decision.

### 2.2 Cap-induced corner cutting

A hard physical cap may pressure an actor to:

- omit required behavior or malformed-input cases;
- weaken diagnostics or no-mutation proof;
- compress readable tests into opaque loops, reflection, or a test DSL;
- combine unrelated logic to reduce physical lines;
- remove useful names, comments, or structure;
- avoid a correct correction because little numerical headroom remains;
- treat one line below a ceiling as inherently safe and one line above it as inherently unsafe.

This is also bloat: complexity and risk are hidden rather than removed.

### 2.3 PR #34 evidence

M04E2R1 PR #34 is the first substantial calibration case for this policy.

Final base-to-head additions were:

| Category | Additions | Deletions | Share of budgeted non-documentation additions |
|---|---:|---:|---:|
| Production runtime code | 514 | 0 | 24% |
| Tests and integration evidence | 1,184 | 0 | 54% |
| Deterministic trace and owner-verification tooling | 489 | 0 | 22% |
| Documentation, planning, and packet authority | 1,153 | 51 | Not part of the non-documentation line threshold |
| Godot `.uid` files | 12 | 0 | Excluded from line threshold; included in path count |
| **Complete PR** | **3,352** | **51** | — |

The owner-approved non-documentation threshold excluded documentation and `.uid` files. The final measured total was:

```text
production runtime      514
tests                  1,184
verification tooling    489
                       -----
budgeted total         2,187 / 2,200
```

The PR completed after 19 commits and 32 changed paths. The final governed total was 13 lines below the approved threshold.

The resulting lessons are:

1. The aggregate threshold was useful because it prevented growth from becoming invisible.
2. One total did not explain the risk: 76% of the budgeted additions were tests or verification tooling, not runtime code.
3. Explicit tests can legitimately exceed production code when they encode a finite independent oracle.
4. Test and tooling lines are still maintenance and review surface; they are not free.
5. Near-zero remaining headroom can create pressure to code-golf or weaken evidence unless the policy explicitly forbids it.
6. Gross additions matter for review burden even when a correction is net-negative after replacing partial mechanisms.
7. Repeated threshold adjustments are convergence evidence and require deliberate triage; they are not automatically wrong when concepts, paths, ownership, and the finite completion set remain stable.
8. The final `2,200` threshold was a slice-specific exception. It is not a default for future work.

---

## 3. Normative terms

### 3.1 Hard authority boundary

A semantic, ownership, architecture, or scope limit that cannot be crossed merely because the physical diff is small.

Examples include:

- another primary subsystem owner;
- another authoritative aggregate family;
- a new save-schema or migration transition;
- a new public API or externally observed result grammar;
- changed persistence meaning;
- a new runtime or cross-layer seam;
- another dependency, platform integration, or trust boundary;
- an unauthorized path or script;
- application, session, service, singleton, autoload, or global ownership not approved by the packet;
- later-slice behavior entering the current slice;
- another player-facing flow or screen.

Crossing a hard authority boundary requires a stop, planning reconciliation, and explicit owner approval. Material changes require fresh independent scope assessment.

### 3.2 Concept

A distinct implementation or authority idea that creates review and maintenance cost independent of its line count.

Concepts include:

- runtime type or aggregate;
- public method, command, or result grammar;
- authoritative state field or persisted meaning;
- semantic validator or checker;
- service, coordinator, cache, or index;
- abstraction layer or generic framework;
- dependency or platform bridge;
- test-only assertion framework, fixture language, or snapshot DSL;
- verification execution framework.

A helper is not automatically a new concept. It becomes one when it introduces a new reusable grammar, authority, lifecycle, dependency, or abstraction boundary.

Count one concept per distinct authority, lifecycle, public grammar, reusable abstraction boundary, dependency, platform bridge, or verification framework—not per file, class, method, assertion, or private helper. An internal helper within an existing owner does not count unless it creates one of those boundaries. When the same change removes or supersedes a prior mechanism, report the outcome as a replacement rather than both an addition and a retained concept.

### 3.3 Forecast range

The expected size of a coherent implementation based on the current repository and approved design. A forecast is a calibration estimate, not permission to add everything within it and not a promise to fit exactly.

### 3.4 Reassessment threshold

A numeric boundary that may not be crossed silently. Before publication beyond the threshold, the actor stops and provides the exception report in §9.

Use the term **reassessment threshold** in new authority. Legacy uses of “line cap,” “ceiling,” or “limit” are interpreted as reassessment thresholds unless the document explicitly defines a different semantic boundary.

### 3.5 Acceptance and evidence floor

The minimum behavior, malformed-input handling, transactionality, diagnostics, and independent proof required by the packet. It cannot be traded for size reduction.

### 3.6 Gross additions, deletions, and net growth

- **Gross additions** represent newly reviewed surface.
- **Deletions** represent removed surface and replacement work.
- **Net growth** is additions minus deletions.

All three may matter. Net growth alone is insufficient when a correction adds substantial new logic while deleting different logic.

### 3.7 Cumulative PR surface and correction delta

For an active PR:

- **cumulative PR surface** is measured from the PR base to the current head;
- **correction delta** is measured from the previously reviewed or triaged head to the proposed correction head.

Correction decisions must report both.

---

## 4. Hard authority boundaries

Hard authority boundaries outrank every quantitative budget.

An implementer or fixer must stop before publication when the work requires:

- an owner, aggregate, schema, public contract, dependency, seam, path, or lifecycle not authorized by the packet;
- a new source of semantic truth;
- a second validator for the same contract without explicit design authority;
- a production abstraction introduced only to simplify one local correction;
- a test framework that recreates production normalization or validation;
- a changed persistence, trust, security, or platform boundary;
- later-slice behavior;
- a change to the principal transition.

A threshold exception cannot authorize a hard-boundary crossing. The packet or architecture must be revised first.

---

## 5. Concept budgets

### 5.1 Required packet declaration

Every implementation packet and material correction packet must declare its concept budget.

Use a table equivalent to:

| Concept class | Approved allowance | Expected additions | Actual outcome |
|---|---:|---|---|
| Primary subsystem owners | 1 total | [[OWNER]] | [[ACTUAL]] |
| New authoritative aggregate families | [[0–1]] | [[NAMES]] | [[ACTUAL]] |
| New public APIs/result grammars | [[COUNT]] | [[NAMES]] | [[ACTUAL]] |
| Schema transitions | [[0–1]] | [[TRANSITION]] | [[ACTUAL]] |
| Production abstraction layers | [[COUNT]] | [[NAMES]] | [[ACTUAL]] |
| Dependencies/platform bridges | [[COUNT]] | [[NAMES]] | [[ACTUAL]] |
| Test-only helper concepts | [[COUNT]] | [[PURPOSE]] | [[ACTUAL]] |
| Verification-tool concepts | [[COUNT]] | [[PURPOSE]] | [[ACTUAL]] |

The packet may state zero for a class. Zero is enforceable.

### 5.2 Default correction concept budget

Unless a correction packet explicitly says otherwise:

```text
new primary owners: 0
new runtime aggregate families: 0
new public APIs or result grammars: 0
new authoritative state or persisted meaning: 0
new dependencies or platform seams: 0
new production abstraction layers: 0
new repository paths: 0
new test-only helper concepts: 0, except a named replacement that proves a finite affected family
new verification-tool concepts: 0, except a named local safety correction
```

A correction may replace a partial mechanism with one clearer local helper without being treated as architecture expansion, provided it:

- remains inside the approved paths and concepts;
- removes or supersedes the partial mechanism;
- does not become another semantic authority;
- has a finite named acceptance population;
- is independently reviewable.

### 5.3 Concept justification questions

Every proposed new type, helper framework, validator, cache, coordinator, or DSL must answer:

1. Which exact requirement or finding requires it?
2. What existing code or partial mechanism does it replace?
3. Why is extending the current structure insufficient?
4. Does it create another source of semantic authority?
5. Is it a durable domain concept or only implementation convenience?
6. Is the complete proof clearer with explicit data or assertions?
7. What later use is actually approved now, rather than merely imagined?

Speculative reuse is not justification.

---

## 6. Categorized quantitative budgets

### 6.1 Required categories

Measure and report at least these categories:

1. **Production runtime code**
   - domain, simulation, services, persistence, application, platform, and presentation behavior.

2. **Tests and deterministic evidence**
   - unit/integration tests, fixtures, executable expected-output witnesses, and negative matrices.

3. **Owner and verification tooling**
   - traces, owner runners, audit scripts, recovery tooling, and CI-specific support.

4. **Documentation and packet authority**
   - decisions, architecture, contracts, planning memos, packets, workflow, and milestone status.

5. **Authored or generated data**
   - `.tres`, fixtures, generated source/data, and other repetitive content.

6. **Metadata and binary paths**
   - `.uid`, images, fonts, archives, and other files without meaningful line counts.

Documentation and authored data do not consume the same risk budget as production runtime code. They still count as changed paths and review surface.

### 6.2 Project-wide fallback bands

These are fallback planning bands when an approved packet does not define a narrower threshold.

| Dimension | Normal planning band | Review zone | Mandatory reassessment |
|---|---:|---:|---:|
| Primary subsystem owners | 1 | — | More than 1 is a hard authority stop |
| New authoritative aggregate families | 0–1 | 2 requires explicit assessor scrutiny | More than 2 is presumptive split/redesign |
| Save-schema transitions | 0–1 | — | More than 1 is a hard authority stop |
| New player-facing flows/screens | 0–1 | — | More than 1 requires split or explicit owner exception |
| New platform/native integrations | 0 | 1 only in its own approved slice | Any mixed with unrelated gameplay is a hard stop |
| Risk dimensions | 0–3 | — | 4 or more requires reassessment |
| Cross-layer integration seams | 0–2 | — | More than 2 requires reassessment |
| Non-documentation changed paths excluding `.uid` | Approximately 10–25 | 26–35 | 36 or more |
| Non-documentation gross additions excluding `.uid` and repetitive authored data | Approximately 500–1,200 | 1,201–1,500 | 1,501 or more |
| Bulk authored data | Small fixture/catalog set | Separately forecast | Production-catalog bulk mixed with a new framework requires split review |

These numbers are project-wide defaults, not entitlements. A packet may set a lower threshold based on risk or a higher owner-approved threshold based on an independently assessed finite design.

Entering a review zone requires an explicit scope-assessor or triage statement about slice coherence and the dominant growth categories. It does not itself require an owner exception. Risk dimensions and integration seams use the definitions and classifications in the active packet and standard workflow.

### 6.3 Category-specific scrutiny

There is no universal test-to-production ratio and no automatic sub-cap for tests.

Apply these questions instead:

- **Production runtime growth:** Does it add authority, behavior, lifecycle, or abstraction?
- **Test growth:** Does it independently encode the accepted contract, or mirror production logic?
- **Verification-tool growth:** Does it improve deterministic safety, or create a fragile execution framework?
- **Documentation growth:** Does it establish durable authority, or duplicate existing semantic ownership?
- **Data growth:** Is it required authored content, or code hidden in data?
- **Generated growth:** Is the generator reviewable, deterministic, and disclosed?

Production runtime code receives the strongest anti-bloat scrutiny. Explicit tests may be larger than production when they prove a finite approved oracle. Verification tooling receives separate safety scrutiny because a small script can still be destructive or misleading.

### 6.4 Forecast and threshold table

Every packet should include a table equivalent to:

| Category | Forecast additions | Forecast deletions | Expected paths | Reassessment threshold | Concepts added/replaced |
|---|---:|---:|---:|---:|---|
| Production runtime | [[RANGE]] | [[RANGE]] | [[COUNT]] | [[VALUE]] | [[LIST]] |
| Tests/evidence | [[RANGE]] | [[RANGE]] | [[COUNT]] | [[VALUE]] | [[LIST]] |
| Verification tooling | [[RANGE]] | [[RANGE]] | [[COUNT]] | [[VALUE]] | [[LIST]] |
| Documentation | [[RANGE]] | [[RANGE]] | [[COUNT]] | [[VALUE]] | [[LIST]] |
| Authored/generated data | [[RANGE]] | [[RANGE]] | [[COUNT]] | [[VALUE]] | [[LIST]] |
| **Aggregate governed total** | [[RANGE]] | [[RANGE]] | [[COUNT]] | [[VALUE]] | — |

If only one aggregate threshold is practical, the categories are still reported so reviewers can see where the growth occurred.

A small deterministic or documentation-only task may use a compact form rather than a large table when:

- every new concept and hard-boundary field is explicitly zero or named;
- no threshold exception is requested;
- the complete category totals and path set remain visible;
- the compact form does not hide a material variance.

---

## 7. Acceptance and evidence floor

No concept or quantitative budget may authorize weakening:

- required behavior;
- malformed-input coverage;
- transactionality and no-mutation proof;
- exact endpoint, identity, ordering, or continuity witnesses;
- aliasing and deep-detachment proof;
- overflow and boundary handling;
- migration and compatibility evidence;
- deterministic equivalence or chunk invariance;
- stable error diagnostics;
- cleanup, restoration, and artifact evidence;
- owner-verification integrity;
- junior-readable names, structure, and reasoning comments;
- independent reviewability.

When a complete readable implementation or correction cannot fit within the authorized threshold, the actor stops and escalates. The actor does not compress, omit, or disguise the proof.

A verbose literal witness may be preferable to a compact abstraction when the abstraction would:

- duplicate production logic;
- conceal field omissions;
- create a second validator;
- make failures harder to localize;
- reduce independent reviewability.

Literal evidence must identify a finite affected population and must not duplicate cases that prove no distinct invariant, boundary, malformed-input class, or accepted outcome.

---

## 8. Measurement standard

### 8.1 Baselines

Record exact refs:

- initial implementation: approved base to proposed/current head;
- cumulative PR: PR base to current head;
- correction: prior reviewed/triaged head to current or forecast head;
- governance/documentation change: current `main` to candidate branch.

Do not compare against an obsolete packet snapshot.

### 8.2 Required measurements

Report:

```text
changed paths by category
gross additions by category
deletions by category
net growth by category
aggregate additions/deletions/net
concepts added, removed, or replaced
current and forecast totals
```

For correction rounds, report both the correction delta and complete PR totals.

### 8.3 Counting rules

- Use Git/GitHub line statistics from the exact refs.
- Exclude `.uid` files from line totals but include them in changed-path counts.
- Count documentation separately from non-documentation code/test/tooling.
- Count tests and verification tooling in the governed non-documentation total. A packet may define additional sub-aggregates or lower category thresholds, but it may not exclude either category from that total. An owner-approved exception changes the authorized threshold, not the counting rule.
- Count generated code in the category whose semantics it implements; do not hide it as data.
- Report authored repetitive data separately and state whether it was generated.
- List binary files separately.
- Disclose renames and moves because line statistics may overstate or understate semantic change.
- Disclose large formatting-only changes; do not use them to obscure review surface.
- Preserve both gross and net figures.
- Do not use logical-line or statement counts to evade physical-line reporting.

### 8.4 No ratio gaming

Do not target:

- a specific test-to-production ratio;
- a fixed comments-to-code ratio;
- a minimum deletion count;
- a desired net line count.

Ratios may describe a result but do not prove quality.

---

## 9. Threshold exception process

### 9.1 Required stop

Before crossing an approved reassessment threshold, the implementer or fixer must stop **before publication** and report. The actor may preserve local work for measurement and review, but must not push, update the PR, or represent the over-threshold result as authorized. A packet may impose an earlier pre-commit stop for a high-risk task.

```text
exact repository, branch, base, and current head
current cumulative totals by category
current correction delta, when applicable
forecast final totals by category
exact additional paths and lines
concepts added, removed, or replaced
acceptance criteria requiring the additional surface
finite affected population or completion oracle
why the existing structure cannot express the result safely
code or helpers deleted/replaced
alternatives considered
whether any hard authority boundary changes
whether any new semantic owner or validator is introduced
validation already completed
smallest exact exception requested
```

Use `None` or `Not applicable` for genuinely irrelevant fields rather than inventing ceremony.

Retain the complete report in a versioned correction packet, triage record, or PR record tied to the exact ref. Present the owner with a concise decision summary containing the exact requested variance, affected concepts and paths, hard-boundary status, recommendation, and reference to the complete report. Record the approver, date, exact head or forecast range, and any delegated variance.

State whether the overage is caused by:

- necessary domain behavior;
- explicit independent test evidence;
- compatibility or migration handling;
- verification safety;
- authored/generated data;
- a refactor or abstraction chosen for convenience.

### 9.2 Available decisions

The planning architect and retained triage architect may recommend:

1. approve the measured exception;
2. require simplification or replacement of unnecessary structure;
3. split the slice while preserving a coherent result;
4. revise the packet;
5. redesign ownership or the oracle;
6. reject or defer the proposed addition.

The implementer, fixer, reviewer, and automation do not self-approve an exception.

### 9.3 Approval authority

- Before packet approval, the planning architect may revise forecasts and thresholds, subject to independent scope assessment and owner approval.
- After packet approval, crossing an owner-approved threshold requires explicit owner approval unless the packet already contains an exact delegated variance range.
- A planning architect or triage architect recommendation is not itself permission to publish beyond the threshold.
- An approved exception applies only to the named slice, paths, concepts, and measured range.
- An exception does not authorize a hard authority-boundary change.

### 9.4 When fresh independent scope assessment is required

A fresh independent scope assessment is required when the proposed exception changes:

- the principal result;
- primary owner;
- concept budget materially;
- authoritative aggregate or state meaning;
- schema or persistence meaning;
- public contract;
- dependency or platform boundary;
- path set materially;
- integration seams or risk dimensions beyond the assessed packet;
- slice decomposition.

A fresh scope assessment is not automatically required for a local finite correction when:

- the approved paths and concepts remain stable;
- retained PR triage establishes a finite completion set;
- no hard authority boundary changes;
- the owner approves the exact measured exception.

---

## 10. Initial implementation-packet requirements

A versioned slice packet must define:

- hard authority boundaries;
- concept budget;
- categorized forecast ranges;
- aggregate and category reassessment thresholds;
- acceptance and evidence floor;
- exact changed-path expectations or path classes;
- mandatory stop conditions;
- exception-report fields;
- independent scope-assessor boundary;
- convergence and correction-loop rule.

A forecast miss is interpreted in context:

- A small diff that adds another semantic owner may require redesign.
- A larger test diff that explicitly proves a finite approved oracle may be acceptable.
- A generalized framework for one current use case is presumptively suspect.
- Repeated threshold extensions with new independent defect classes are non-convergence evidence.
- Repeated extensions caused by completing one finite enumerated oracle may justify one measured exception, but still require convergence assessment.

Recommended packet clause:

> Quantitative budgets are no-silent-crossing reassessment boundaries, not semantic quotas or entitlements. Implement the smallest complete and independently reviewable result. Do not omit behavior, weaken evidence, reduce diagnostics, code-golf, or add speculative abstraction to fit a number. Stop before publication when a threshold or concept budget would be crossed and provide the exception report required by the repository policy.

---

## 11. Correction-packet requirements

A material correction packet must state:

- exact starting head;
- current cumulative PR totals by category;
- forecast correction delta by category;
- forecast final cumulative totals;
- exact writable paths;
- exact concept allowance;
- the complete affected behavior or witness population, not only the latest comments;
- whether replacement is preferred over additive patching;
- the post-correction review scope;
- the stop condition if the same root cause survives;
- whether assertion/test counts or owner tooling may change.

Default correction clause:

> Prefer the smallest complete correction, not the fewest physical lines. The quantitative threshold is a no-silent-crossing reassessment boundary, not a semantic quota. Do not omit required behavior, weaken witnesses, reduce diagnostics, code-golf, or introduce opaque abstraction solely to remain below it. Replace partial or duplicative mechanisms where that improves clarity. A new abstraction is permitted only when the packet explicitly authorizes it and it proves the complete named family without becoming another semantic authority. If the complete readable correction cannot fit, stop before publication and report the categorized delta, concepts introduced or replaced, alternatives considered, finite completion set, and smallest exact exception requested.

After two substantial correction rounds, the retained PR-lifetime triage architect performs the convergence assessment required by the standard workflow.

---

## 12. Anti-gaming rules

Actors must not reduce reported size or apparent complexity by:

- joining unrelated statements onto fewer physical lines;
- compressing data or expectations into unreadable one-line literals;
- removing meaningful names, comments, assertions, or diagnostics;
- moving code into strings, generated blobs, fixtures, or hidden data;
- using reflection or metaprogramming solely to reduce line count;
- creating a generic DSL harder to review than literal evidence;
- duplicating production normalization or validation inside tests;
- moving production semantics into tests or tooling;
- excluding required support code from the measured category without disclosure;
- reporting only net lines when gross additions materially enlarge review surface;
- deleting useful code solely to create numerical headroom without proving equivalent clarity and behavior;
- splitting one coherent change across files or PRs merely to evade thresholds;
- combining unrelated work into a “cleanup” deletion/addition trade;
- treating generated code as free review surface.

A reviewer should report a concrete consequence—duplicated authority, hidden behavior, untestable abstraction, omitted evidence, unsafe tooling—not “too many lines” by itself.

---

## 13. Review, assessment, and triage questions

Independent scope assessors, triage architects, and reviewers should ask:

1. Did the change introduce more concepts than the packet authorized?
2. Is the added code required by acceptance, or merely convenient?
3. Did the actor replace a partial mechanism or stack another layer on top?
4. Are tests independently authored, or do they reproduce implementation logic?
5. Is an explicit verbose witness safer than the proposed abstraction?
6. Could the result be achieved by deleting or simplifying existing structure?
7. Did line pressure cause omitted cases, opaque logic, or reduced diagnostics?
8. Does measured size reveal a hidden owner, seam, API, or behavior change?
9. Is the remaining work finite and enumerable?
10. Would another correction round likely expose the same root cause or a new defect class?
11. Are gross additions, net growth, and changed paths all represented truthfully?
12. Is owner-verification tooling proportionate and failure-safe?
13. Is an approved exception recorded and bounded to this slice?
14. Would a fresh scope assessment materially improve independence, or merely repeat retained PR triage?

### 13.1 Scope assessor

The scope assessor challenges:

- principal result and owner;
- concept budget;
- categorized forecasts;
- reassessment thresholds;
- hidden later-slice behavior;
- oracle independence;
- whether the task should split before implementation.

### 13.2 Triage architect

The retained PR-lifetime triage architect determines:

- whether a correction is local and finite;
- whether a threshold extension reflects completion of one known family or systemic drift;
- whether a new concept or authority has entered;
- whether another correction has a credible finite endpoint;
- whether to recommend exception, simplification, split, packet revision, or redesign.

### 13.3 Code reviewer

A code reviewer may report material bloat when it causes a concrete defect or authority violation. The reviewer should not treat an approved threshold exception or explicit test volume as a defect by itself.

---

## 14. Relationship to convergence

Quantitative growth is one input to convergence assessment, not the conclusion.

Continue when:

- defects are local;
- the root cause is understood;
- the affected population is finite;
- the correction can be independently tested;
- ownership, concepts, and path boundaries remain stable;
- new concepts are absent or explicitly justified;
- the next rereview has a credible completion condition.

Stop, split, or redesign when:

- each round reveals a new independent defect class;
- the oracle cannot become complete without mirroring production semantics;
- another owner, aggregate, schema, seam, dependency, or public contract is required;
- generalized infrastructure is repeatedly added to solve local findings;
- the actor cannot state a finite completion set;
- thresholds keep expanding without a stable endpoint;
- review burden grows while acceptance evidence does not improve.

Round count and line count alone are not dispositive.

---

## 15. Evidence retention and calibration

The final PR handoff should record:

- final changed paths;
- additions/deletions/net by category;
- final concepts added or removed;
- approved threshold and exception;
- final acceptance and review evidence;
- any divergence from forecast and why.

Milestone closure should retain concise lessons when they affect future planning. It should not reproduce every correction transcript.

The planning architect may use completed slices to recalibrate future default bands. A prior exception does not automatically raise the default.

---

## 16. Repository ownership and integration

This document is the single semantic owner of quantitative scope-budget and anti-bloat policy.

Other documents should route rather than duplicate:

- `AGENTS.md` — concise universal stop and anti-gaming router;
- `STANDARD_MILESTONE_SLICE_WORKFLOW.md` — actor, lifecycle, assessment, correction, convergence, and exception-routing rules; quantitative additions to those processes are owned here;
- `ACTOR_PROMPT_STANDARD.md` — actor model, session, context, proportionality, and output rules; quantitative details remain owned here and are referenced only when relevant;
- `PROMPT_TEMPLATE.md` — required packet fields and clause;
- `IMPLEMENTATION_RULES.md` — junior readability, explicit code, and engineering conventions;
- `MILESTONES.md` — compact project-wide fallback bands and historical slice outcomes;
- `ARCHITECT_HANDOVER_STANDARD.md` — handover package, source-discipline, and successor-bootstrap semantics; every future successor authority map routes to this policy without copying it;
- `templates/architect-handover/GENERATE_ARCHITECT_HANDOVER_REQUEST.txt` and `01_SESSION_HANDOVER.md` — authoring routers that require the outgoing architect to read this policy and name it in the successor's exact authority map;
- active slice packet — exact slice-specific concepts, forecasts, thresholds, and exceptions.

For architect continuity, every future filled `01_SESSION_HANDOVER.md` should name this policy as stable authority. It should cite exact sections relevant to the current cutoff and record active slice-specific threshold, measurement, review-zone, exception, or delegated-variance facts only when they affect continuation. It must not copy this policy or reproduce its default tables. `00_BOOTSTRAP_PROMPT.txt` should remain generic and continue directing the successor to fetch the sources named in the handover authority map.

Revision 1.2 is integrated through these companion-routing updates:

1. `AGENTS.md` provides the concise universal stop and anti-gaming route;
2. `STANDARD_MILESTONE_SLICE_WORKFLOW.md` references this policy from scope assessment, implementation stop, correction, convergence, exception handling, and completion evidence;
3. `PROMPT_TEMPLATE.md` requires the declarations and stop route in §§5–11;
4. `MILESTONES.md` retains only the compact fallback-band summary governed here;
5. `IMPLEMENTATION_RULES.md` routes junior-readable implementation choices away from code-golfing and speculative abstraction;
6. `ARCHITECT_HANDOVER_STANDARD.md`, `templates/architect-handover/GENERATE_ARCHITECT_HANDOVER_REQUEST.txt`, and `templates/architect-handover/01_SESSION_HANDOVER.md` make this policy discoverable by every successor planning architect without copying it;
7. `templates/architect-handover/00_BOOTSTRAP_PROMPT.txt` remains generic;
8. no gameplay, test, owner-tooling, or milestone-sequence behavior changes.

---

## 17. Approval and change control

Revision 1.2 became the approved repository policy after:

1. fresh independent governance/scope assessment of the candidate policy;
2. owner approval of revision 1.1 with the assessor's bounded amendments;
3. owner approval of the revision 1.2 architect-handover routing refinement;
4. deployment of this policy and its narrow companion routers.

Future changes require evidence of recurring friction or miscalibration and explicit owner approval through the normal governance/documentation workflow. Do not expand the policy because a more generalized governance framework is theoretically possible.

---

## 18. Decision summary

> Death Idle uses quantitative review-surface budgets as planning and reassessment triggers, not semantic quotas or entitlements. Hard stops apply to unapproved authority, ownership, schema, dependency, seam, public-contract, trust-boundary, and path expansion. Every material packet declares a concept budget, categorized forecast, reassessment thresholds, and acceptance/evidence floor. Before crossing a threshold, the actor stops and reports exact categorized deltas, concepts, finite acceptance coverage, alternatives, and the smallest exception requested. Explicit owner approval is required unless an exact variance was already delegated. Tests and verification tooling count as review surface but are judged by independence and safety rather than a production-code ratio. No budget authorizes omitted behavior, weakened proof, code golfing, hidden generated logic, or speculative abstraction.
