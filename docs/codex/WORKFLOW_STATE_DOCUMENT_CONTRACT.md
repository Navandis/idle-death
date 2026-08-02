# Workflow-state public document contract

`tools/codex/workflow_state_document_contract.ps1` exposes the authoritative in-memory semantic assertion entry point `Assert-WorkflowStateDocument`. It validates a closed public document with fixed `schema_version: 1` and `tool: "verify_workflow_state"` values. A successful assertion emits no success-stream objects and does not mutate the supplied document; an invalid document throws one terminating structural or semantic error.

## Ownership and dependency

The document contract dot-sources only the fixed sibling `tools/codex/workflow_state_primitives.ps1` dependency introduced by 10E1A. That merged primitive library owns structural scalar, array, key, URI, SHA, and timestamp checks, including ordinal property and string identity. This component owns nested document records and cross-field semantic policy only.

10E1C owns query constructors, error sanitization/redaction output, JSON serialization, canonical failure envelopes, and emergency-failure JSON. Collectors and the verifier CLI remain deferred. This validator performs no evidence collection, process, Git, GitHub, network, publication, file mutation, credential access, or serialization.

## Vocabulary and semantic policy

The closed root contains `schema_version`, `tool`, `generated_at_utc`, `result`, `repository`, `tools`, `workspace`, `github`, and nonempty `queries`. `result` is `pass`, `partial`, or `fail`; timestamps are exact canonical UTC (`T`/`Z`, zero through seven fractional digits); SHAs are lowercase 40-character values; URIs are absolute. Nullable fields are defined by the authoritative semantic assertion.

`repository.root`, `branch`, and `upstream` are nullable strings; `head`, `origin_main`, `remote_main`, and `remote_feature_sha` are nullable SHAs. Every `tools` field and `github.login` is nullable string data. `github.pull_request` is null or a complete identifiable pull-request record; its `mergeable` and `auto_merge` are Boolean or null. Check and workflow evidence follows the historical nullable evidence policy: its IDs, text fields, URIs, and SHAs are nullable where the assertion permits them. Review-item `path` and `line`, plus query `exit_code` and `error`, are nullable; no other required identity field is nullable.

Repository URLs are sorted, unique arrays containing only `https://github.com/Navandis/idle-death`. Workspace entries are unique, preserve caller order, and are not required to be sorted. Pull-request labels and origin URL arrays are strictly ordinal-sorted and unique. Query `(scope, name)` pairs and review-thread IDs are ordinally unique, while case-distinct free-form names remain distinct.

`pass` has no failed queries. `partial` has one or more failed GitHub queries and no failures from another scope. `fail` has at least one failed `local`, `invariant`, or `schema` query. Pass/partial additionally require complete local evidence: repository root, branch, head, origin main, both origin URL arrays, and workspace index-lock path. A null pull request requires count zero; a present identifiable pull request requires count one. Review counts must agree with item count and resolved state. Query success requires null error, failure requires a bounded nonwhitespace error, and any credential-like error indication rejects.

## Fixtures and deferred validation boundary

The four JSON fixtures are semantic examples and adversarial test inputs. Parsing those fixtures supplies in-memory documents for `Assert-WorkflowStateDocument`; it does not validate another artifact.

This PR includes no JSON Schema. The previous hand-written parsed-schema evidence was removed after repeated evidence-integrity findings. Draft 2020-12 work is deferred to a separately owned component that must execute a pinned validation engine against fixtures and adversarial documents, or use another separately reviewed single-source generation and validation strategy. This component does not select that future dependency or strategy.
