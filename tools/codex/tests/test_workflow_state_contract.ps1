Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

## Runs dependency-free, offline positive and adversarial tests for the workflow-state contract.
## It reads only its schema, fixtures, and pure libraries; it never collects repository or GitHub evidence.

$testRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $testRoot 'workflow_state_contract.ps1')
. (Join-Path $testRoot 'workflow_state_envelopes.ps1')
$fixtureRoot = Join-Path $PSScriptRoot 'fixtures'
$failures = New-Object System.Collections.Generic.List[string]
$validCount = 0
$rejectionCount = 0

function Add-TestFailure { param([string]$Name, [string]$Message) $script:failures.Add("${Name}: $Message") }
function Assert-True { param([bool]$Condition, [string]$Name) if (-not $Condition) { throw $Name } }
function Assert-Rejected {
    param([string]$Name, [scriptblock]$Action)
    try { & $Action; Add-TestFailure $Name 'accepted unexpectedly.' } catch { $script:rejectionCount++ }
}
function Copy-Document { param($Document) return ($Document | ConvertTo-Json -Depth 20 | ConvertFrom-Json) }
function Get-Fixture { param([string]$Name) return (Get-Content -Raw (Join-Path $fixtureRoot $Name) | ConvertFrom-Json) }
function New-TestPullRequest {
    return [pscustomobject][ordered]@{ number = 1; url = 'https://example.test/pr/1'; state = 'OPEN'; draft = $false; mergeable = $true; base_ref = 'main'; head_ref = 'codex/synthetic'; head_sha = '0123456789abcdef0123456789abcdef01234567'; author = 'synthetic'; labels = @('alpha'); auto_merge = $false }
}
function New-TestThread { param([string]$Id) return [pscustomobject][ordered]@{ id = $Id; is_resolved = $true; is_outdated = $false; path = 'synthetic.txt'; line = 1 } }

try {
    $schemaText = Get-Content -Raw (Join-Path $testRoot 'workflow-state.schema.json')
    $schema = $schemaText | ConvertFrom-Json
    Assert-True ([regex]::Matches($schemaText, '"if"').Count -eq 6) 'schema conditional-policy count is not six'
    Assert-True ($schema.'$defs'.query.properties.exit_code.minimum -eq -2147483648) 'schema signed Int32 minimum missing'
    Assert-True ($schema.'$defs'.query.properties.exit_code.maximum -eq 2147483647) 'schema signed Int32 maximum missing'
} catch { Add-TestFailure 'schema parsing and policy structure' $_.Exception.Message }

foreach ($fixtureName in @('workflow-state-pass-valid.json','workflow-state-partial-valid.json','workflow-state-fail-valid.json')) {
    try { Test-WorkflowStateContract (Get-Fixture $fixtureName) | Out-Null; $validCount++ } catch { Add-TestFailure "valid fixture $fixtureName" $_.Exception.Message }
}
Assert-Rejected 'unknown field fixture' { Test-WorkflowStateContract (Get-Fixture 'workflow-state-unknown-field-invalid.json') | Out-Null }

$pass = Get-Fixture 'workflow-state-pass-valid.json'
$partial = Get-Fixture 'workflow-state-partial-valid.json'
$fail = Get-Fixture 'workflow-state-fail-valid.json'
Assert-Rejected 'exit code below Int32 minimum' { $d = Copy-Document $fail; $d.queries[0].exit_code = [Int64]-2147483649; Test-WorkflowStateContract $d | Out-Null }
Assert-Rejected 'exit code above Int32 maximum' { $d = Copy-Document $fail; $d.queries[0].exit_code = [Int64]2147483648; Test-WorkflowStateContract $d | Out-Null }
Assert-Rejected 'pass with failed query' { $d = Copy-Document $pass; $d.queries[0].ok = $false; $d.queries[0].error = 'synthetic'; Test-WorkflowStateContract $d | Out-Null }
Assert-Rejected 'partial without failed github query' { $d = Copy-Document $partial; $d.queries[1].ok = $true; $d.queries[1].error = $null; Test-WorkflowStateContract $d | Out-Null }
Assert-Rejected 'partial with failed local query' { $d = Copy-Document $partial; $d.queries[0].ok = $false; $d.queries[0].error = 'synthetic'; Test-WorkflowStateContract $d | Out-Null }
Assert-Rejected 'fail without failed non-github query' { $d = Copy-Document $fail; $d.queries[0].scope = 'github'; Test-WorkflowStateContract $d | Out-Null }
Assert-Rejected 'null PR with count one' { $d = Copy-Document $pass; $d.github.matching_pr_count = 1; Test-WorkflowStateContract $d | Out-Null }
Assert-Rejected 'PR object with count zero' { $d = Copy-Document $pass; $d.github.pull_request = New-TestPullRequest; $d.github.matching_pr_count = 0; Test-WorkflowStateContract $d | Out-Null }
Assert-Rejected 'main with remote feature SHA' { $d = Copy-Document $pass; $d.repository.remote_feature_sha = '0123456789abcdef0123456789abcdef01234567'; Test-WorkflowStateContract $d | Out-Null }
Assert-Rejected 'malformed SHA' { $d = Copy-Document $pass; $d.repository.head = 'not-a-sha'; Test-WorkflowStateContract $d | Out-Null }
Assert-Rejected 'malformed URI' { $d = Copy-Document $pass; $d.github.check_runs[0].details_url = 'not a uri'; Test-WorkflowStateContract $d | Out-Null }
Assert-Rejected 'review item count mismatch' { $d = Copy-Document $pass; $d.github.review_threads.total_count = 1; Test-WorkflowStateContract $d | Out-Null }
Assert-Rejected 'unresolved count mismatch' { $d = Copy-Document $pass; $d.github.review_threads.total_count = 1; $d.github.review_threads.unresolved_count = 1; $d.github.review_threads.items = @(New-TestThread 'thread-1'); Test-WorkflowStateContract $d | Out-Null }
Assert-Rejected 'duplicate review-thread ID' { $d = Copy-Document $pass; $d.github.review_threads.total_count = 2; $d.github.review_threads.items = @((New-TestThread 'thread-1'),(New-TestThread 'thread-1')); Test-WorkflowStateContract $d | Out-Null }
Assert-Rejected 'duplicate query scope/name pair' { $d = Copy-Document $pass; $d.queries = @($d.queries[0], $d.queries[0]); Test-WorkflowStateContract $d | Out-Null }
Assert-Rejected 'unsorted labels' { $d = Copy-Document $pass; $d.github.pull_request = New-TestPullRequest; $d.github.matching_pr_count = 1; $d.github.pull_request.labels = @('zeta','alpha'); Test-WorkflowStateContract $d | Out-Null }
Assert-Rejected 'duplicate origin fetch URLs' { $d = Copy-Document $pass; $d.repository.origin_fetch_urls = @('https://github.com/Navandis/idle-death','https://github.com/Navandis/idle-death'); Test-WorkflowStateContract $d | Out-Null }
Assert-Rejected 'duplicate origin push URLs' { $d = Copy-Document $pass; $d.repository.origin_push_urls = @('https://github.com/Navandis/idle-death','https://github.com/Navandis/idle-death'); Test-WorkflowStateContract $d | Out-Null }
Assert-Rejected 'credential-like error text' { $d = Copy-Document $fail; $d.queries[0].error = 'Bearer gho_example'; Test-WorkflowStateContract $d | Out-Null }
Assert-Rejected 'scalar where array required' { $d = Copy-Document $pass; $d.workspace.status_entries = 'not-an-array'; Test-WorkflowStateContract $d | Out-Null }

try {
    $negative = New-WorkflowStateQueryRecord -Scope local -Name 'negative_exit' -Ok $false -ExitCode -1073741819 -ErrorText 'synthetic'
    Assert-True ($negative.exit_code -eq -1073741819) 'negative signed exit code changed'
    $envelope = New-WorkflowStateFailEnvelope -FailureScope local -FailureName 'synthetic_failure' -ExitCode -1073741819 -ErrorText 'synthetic'
    Test-WorkflowStateContract $envelope | Out-Null
    $roundTrip = (ConvertTo-WorkflowStateJson $envelope) | ConvertFrom-Json
    Assert-True ($roundTrip.queries[0].exit_code -eq -1073741819) 'negative exit code did not survive JSON round trip'
    $safe = Get-WorkflowStateSanitizedError "line one`r`nBearer gho_example"
    Assert-True ($safe -eq 'Sensitive error details redacted.') 'sanitizer did not redact credential-like input'
    $oneLine = ConvertTo-WorkflowStateJson $envelope
    Assert-True ($oneLine -notmatch "[\r\n]") 'serialized JSON was not one line'
    $emergency = Get-WorkflowStateEmergencyFailJson
    Assert-True ($emergency -notmatch "[\r\n]") 'emergency JSON was not one line'
    Test-WorkflowStateContract ($emergency | ConvertFrom-Json) | Out-Null
} catch { Add-TestFailure 'envelope and emergency behavior' $_.Exception.Message }

if ($failures.Count -gt 0) { Write-Output ("FAIL valid={0} rejected={1} failures={2}" -f $validCount, $rejectionCount, ($failures -join ' | ')); exit 1 }
Write-Output ("PASS valid={0} rejected={1} signed_exit=PASS sanitizer=PASS envelope=PASS emergency=PASS schema_conditionals=6" -f $validCount, $rejectionCount)
exit 0
