# Workflow-state structural primitives

## Purpose and ownership

`tools/codex/workflow_state_primitives.ps1` is a pure Windows PowerShell 5.1-compatible library of structural checks for future workflow-state code. It owns runtime type inspection, ordinal string and property comparison, UTC timestamp syntax, URI and SHA primitives, array and uniqueness checks, and sensitive-error indication.

It deliberately contains no public workflow-state document, JSON Schema, serializer, sanitizer, envelope, Git or GitHub collector, process execution, or mutation capability. It performs no I/O, does not inspect the environment, and does not write output streams. Successful `Assert-*` calls have no output, failed assertions throw once, `Get-*` calls return their value, and `Test-*` calls return a Boolean.

## Candidate values and scalar safety

Untrusted candidate-value parameters use `object`, never `string`, integer, Boolean, array, URI, or timestamp parameter types. This prevents PowerShell parameter binding from converting a one-item array into a scalar before validation. A scalar-string primitive therefore accepts only an actual `System.String`; it rejects arrays, numeric and Boolean values, characters, `StringBuilder`, and other objects without conversion.

Literal and enum checks first require that scalar primitive and compare with `StringComparison.Ordinal`. Property discovery and exact-property access likewise preserve original case and locate names ordinally. `PSCustomObject` and `IDictionary` are the only supported object containers. Exact-key checks reject missing, extra, wrong-case, and repeated ordinal names. An existing null property is distinct from a missing property, and an array property is returned as one array object even when it is empty or has one item.

## Scalar and collection primitives

The Boolean primitive accepts only `System.Boolean`. The integer primitive accepts only `SByte`, `Byte`, `Int16`, `UInt16`, `Int32`, `UInt32`, and `Int64`, each safely representable as signed `Int64`. It rejects `UInt64`, floating-point and decimal values, numeric strings, Booleans, and arrays. Its inclusive bounds preserve negative native exit values.

The array primitive accepts only rank-one `System.Array` values. It intentionally rejects strings, scalars, `ArrayList`/`List` collections, and multidimensional arrays. Order-preserving uniqueness accepts ordinally distinct scalar strings in any caller order. Sorted uniqueness additionally requires strict `String.CompareOrdinal` order; `Alpha` and `alpha` are distinct only when supplied in that order.

## URI, SHA, and timestamps

The absolute-URI primitive first requires an actual scalar string, rejects whitespace and relative or malformed values, then uses absolute URI parsing. It intentionally makes no HTTPS, repository, or host choice; that later public-document policy belongs to 10E1B.

The SHA primitive accepts only lowercase, forty-character hexadecimal text, with culture-invariant and case-sensitive matching. It can be explicitly nullable.

Canonical UTC timestamps use exactly `YYYY-MM-DDTHH:mm:ssZ` or `YYYY-MM-DDTHH:mm:ss.fZ` through seven fractional digits. The primitive first applies an anchored ASCII grammar, then uses invariant exact Gregorian parsing. It rejects spaces, offsets, lower-case separators, missing seconds, invalid calendar/clock values, and more than seven fractional digits while accepting valid leap days.

## Sensitive-error indication

`Test-WorkflowStateSensitiveError` returns false for null and requires a scalar string otherwise. It uses culture-invariant case-insensitive detection for standalone `authorization`, `bearer`, and `token`; `hosts.yml`; and these GitHub credential prefixes anywhere in text, including URL user-info: `ghp_`, `gho_`, `ghu_`, `ghs_`, `ghr_`, and `github_pat_`. It detects only; redaction and sanitization are outside this slice.

## Test and future composition

Run the dependency-free offline verification on Windows with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\codex\tests\test_workflow_state_primitives.ps1"
```

The test uses synthetic values, validates both `PSCustomObject` and a `StringComparer.Ordinal` dictionary, covers the scalar one-item-array bypass matrix, and statically inspects the production library for process, output, filesystem, console, and environment-write behavior.

10E1B will compose these primitives into the public workflow-state document contract and JSON Schema. 10E1C will compose them into constructors and guaranteed envelopes. Neither later responsibility is implemented here.
