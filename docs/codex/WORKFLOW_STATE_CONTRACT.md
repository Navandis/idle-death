# Workflow-state contract kernel

## Purpose and boundary

This kernel defines the public, read-only evidence document produced by a future `verify_workflow_state` composition. It owns vocabulary, JSON Schema, semantic validation, query records, and safe fail documents. It performs no repository, Git, GitHub, network, process, credential, or filesystem collection.

Future local-Git and GitHub collectors provide evidence; a CLI composes it into this contract. This slice deliberately defers mutation, publication, approval, journals, PR administration, merge, branch deletion, rulesets, billing, and deployment.

## Vocabulary

Every document has `schema_version: 1`, `tool: "verify_workflow_state"`, a UTC RFC3339 generation timestamp, `result`, `repository`, `tools`, `workspace`, `github`, and `queries`. Objects reject unknown fields and every declared field is present. Unavailable scalars are `null`; collection fields remain arrays.

`result` is `pass`, `partial`, or `fail`. SHA values are `null` or lowercase 40-character hexadecimal values. Repository origin URLs are the normalized, sorted, duplicate-free `https://github.com/Navandis/idle-death` value. A query records its explicit owner scope (`local`, `github`, `invariant`, or `schema`), name, Boolean outcome, signed native exit code, and safe error.

Exit codes retain the full signed Int32 range. Windows native crashes can surface negative `LASTEXITCODE` values, so coercing them to unsigned values would lose diagnostic meaning.

## Result and failure behavior

`pass` has no failed queries. `partial` has at least one failed GitHub query and no failed query outside GitHub. `fail` has at least one failed local, invariant, or schema query. Pass and partial documents require complete local-state evidence: repository root, branch, local and origin-main SHAs, both normalized origin arrays, and index-lock path.

`New-WorkflowStateFailEnvelope` creates a fresh document rather than reusing a partial candidate. It has exactly one failed local, invariant, or schema query and represents unavailable evidence with `null` or empty arrays. It validates before return. `Get-WorkflowStateEmergencyFailJson` independently constructs one fixed, one-line schema-scope failure JSON document with exit code `-1`; it does not depend on `ConvertTo-Json`.

Errors collapse whitespace, are bounded to 512 characters, and replace credential-like material—authorization, bearer, token, `hosts.yml`, `gho_`, and `github_pat_` forms—with `Sensitive error details redacted.` No collector or caller should place credentials in errors.

## Schema and semantic authority

[workflow-state.schema.json](../../tools/codex/workflow-state.schema.json) is Draft 2020-12 and supplies exact object shapes, nullability, formats, signed exit-code bounds, uniqueness where JSON Schema can express it, and conditional policies for result/query, pull-request/count, branch/remote-feature-SHA, and query outcome/error relationships.

`Test-WorkflowStateContract` is authoritative for a trust decision. Semantic-only invariants are: review-item array/count equality; unresolved-thread recounting; unique review-thread IDs; duplicate query scope/name pairs; sorted labels; sorted normalized origin arrays; and pass/partial local-state completeness. Parsing the schema alone is not sufficient.

| Invariant owner | Examples |
| --- | --- |
| JSON Schema | Exact keys, primitive types, URI/timestamp forms, signed Int32 bounds, `matching_pr_count` range, expressible conditionals |
| Semantic validator | Normalized URL equality and ordering, recounts, cross-array uniqueness, credential-safe errors, complete local evidence |
| Future collectors | Native command execution and truthful source-specific evidence |

## Offline verification

Run on Windows PowerShell 5.1 or later:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\codex\tests\test_workflow_state_contract.ps1"
```

The dependency-free test reads synthetic fixtures and proves valid acceptance, all required adversarial rejections, signed negative exit-code round trips, sanitizer behavior, fail-envelope validation, emergency JSON validation, and schema conditional structure. It performs no repository mutation or external-system access.
