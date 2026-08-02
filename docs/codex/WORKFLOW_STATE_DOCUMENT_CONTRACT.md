# Workflow-state public document contract

`tools/codex/workflow_state_document_contract.ps1` exposes the authoritative in-memory assertion entry point `Assert-WorkflowStateDocument`. It validates a closed public document with fixed `schema_version: 1` and `tool: "verify_workflow_state"` values. A successful assertion emits no success-stream objects and does not mutate the supplied document; an invalid document throws one terminating structural or semantic error.

## Ownership and dependency

The document contract dot-sources only the fixed sibling `tools/codex/workflow_state_primitives.ps1` dependency introduced by 10E1A. That primitive library owns exact keys/property access, scalar runtime types, fixed literals/enums, Boolean and integer checks, rank-one arrays, URI/SHA/timestamp grammar, ordinal uniqueness/sorting, and sensitive-error indication. The document contract owns nested records and cross-field policy only.

10E1C owns query constructors, error sanitization/redaction output, JSON serialization, canonical failure envelopes, and emergency-failure JSON. Collectors and the verifier CLI are deferred. This validator performs no evidence collection, process/Git/GitHub/network access, publication, file mutation, credential access, or serialization.

## Vocabulary and semantic policy

The closed root contains `schema_version`, `tool`, `generated_at_utc`, `result`, `repository`, `tools`, `workspace`, `github`, and nonempty `queries`. `result` is `pass`, `partial`, or `fail`; timestamps are exact canonical UTC (`T`/`Z`, zero through seven fractional digits); SHAs are lowercase 40-character values; URIs are absolute. Nullable fields retain explicit nullability as described in the schema.

`repository.root`, `branch`, and `upstream` are nullable strings; `head`, `origin_main`, `remote_main`, and `remote_feature_sha` are nullable SHAs. Every `tools` field and `github.login` is nullable string data. `github.pull_request` is null or a complete identifiable pull-request record; its `mergeable` and `auto_merge` are Boolean or null. Check and workflow evidence follows the historical nullable evidence policy: its IDs, text fields, URIs, and SHAs are nullable exactly where the schema records. Review-item `path` and `line`, plus query `exit_code` and `error`, are nullable; no other required identity field is nullable.

Repository URLs are sorted, unique arrays containing only `https://github.com/Navandis/idle-death`. Workspace entries are unique, preserve caller order, and are not required to be sorted. Pull-request labels and origin URL arrays are strictly ordinal-sorted and unique. Query `(scope, name)` pairs and review-thread IDs are ordinally unique, while case-distinct free-form names remain distinct.

`pass` has no failed queries. `partial` has one or more failed GitHub queries and no failures from another scope. `fail` has at least one failed `local`, `invariant`, or `schema` query. Pass/partial additionally require complete local evidence: repository root, branch, head, origin main, both origin URL arrays, and workspace index-lock path. A null pull request requires count zero; a present identifiable pull request requires count one. Review counts must agree with item count and resolved state. Query success requires null error, failure requires a bounded nonwhitespace error, and any credential-like error indication rejects.

## Schema and verification boundary

`tools/codex/workflow-state.schema.json` declares Draft 2020-12 and closes every represented object with exact required fields. It records primitive/nullability policy, `uniqueItems` where JSON Schema can express it, and six conditional structures for result, main-branch, pull-request-count, and query error policy. Ordering, ordinal comparison, sensitive-error detection, exact runtime types, review aggregation, and complete trust semantics remain authoritative in `Assert-WorkflowStateDocument`.

The bundled offline test parses and structurally inspects this schema and the synthetic fixtures. It does not execute or claim to execute a third-party Draft 2020-12 validation engine. A caller making a trust decision must use `Assert-WorkflowStateDocument`.
