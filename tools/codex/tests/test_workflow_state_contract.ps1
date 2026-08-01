#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

## Runs dependency-free positive and negative validation cases for the workflow-state JSON contract.
## It owns only in-memory fixture copies and never invokes Git, GitHub, or network operations.

$repo_root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
. (Join-Path $repo_root 'tools\codex\workflow_state_contract.ps1')
$fixture_root = Join-Path $PSScriptRoot 'fixtures'
$valid_count = 0
$rejection_count = 0

function Get-FixtureCopy {
    param([Parameter(Mandatory = $true)][string]$Name)

    return (Get-Content -LiteralPath (Join-Path $fixture_root $Name) -Raw | ConvertFrom-Json)
}

function Copy-WorkflowDocument {
    param([Parameter(Mandatory = $true)][object]$Document)

    return ($Document | ConvertTo-Json -Depth 30 | ConvertFrom-Json)
}

function Assert-ValidFixture {
    param([Parameter(Mandatory = $true)][string]$Name)

    $document = Get-FixtureCopy $Name
    Test-WorkflowStateContract $document | Out-Null
    $script:valid_count++
}

function Assert-RejectedCase {
    param([Parameter(Mandatory = $true)][string]$Name, [Parameter(Mandatory = $true)][scriptblock]$Action)

    try {
        & $Action
        throw "Expected rejection did not occur: $Name"
    }
    catch {
        if ($_.Exception.Message -like 'Expected rejection did not occur:*') { throw }
        $script:rejection_count++
    }
}

try {
    $schema = Get-Content -LiteralPath (Join-Path $repo_root 'tools\codex\workflow-state.schema.json') -Raw | ConvertFrom-Json
    if ($schema.'$schema' -ne 'https://json-schema.org/draft/2020-12/schema' -or $schema.additionalProperties -ne $false) {
        throw 'Workflow-state schema did not parse as the required strict draft 2020-12 document.'
    }

    foreach ($fixture in @('workflow-state-main-valid.json', 'workflow-state-feature-valid.json', 'workflow-state-partial-valid.json')) {
        Assert-ValidFixture $fixture
    }
    Assert-RejectedCase 'unknown field fixture' { Test-WorkflowStateContract (Get-FixtureCopy 'workflow-state-unknown-field-invalid.json') | Out-Null }
    Assert-RejectedCase 'malformed SHA' { $item = Get-FixtureCopy 'workflow-state-main-valid.json'; $item.repository.head = 'not-a-sha'; Test-WorkflowStateContract $item | Out-Null }
    Assert-RejectedCase 'pull request count mismatch' { $item = Get-FixtureCopy 'workflow-state-feature-valid.json'; $item.github.matching_pr_count = 0; Test-WorkflowStateContract $item | Out-Null }
    Assert-RejectedCase 'unresolved review-thread count' { $item = Get-FixtureCopy 'workflow-state-feature-valid.json'; $item.github.review_threads.unresolved_count = 3; Test-WorkflowStateContract $item | Out-Null }
    Assert-RejectedCase 'pass with failed query' { $item = Get-FixtureCopy 'workflow-state-partial-valid.json'; $item.result = 'pass'; Test-WorkflowStateContract $item | Out-Null }
    Assert-RejectedCase 'partial without failed query' { $item = Get-FixtureCopy 'workflow-state-main-valid.json'; $item.result = 'partial'; Test-WorkflowStateContract $item | Out-Null }
    Assert-RejectedCase 'scalar in array field' { $item = Get-FixtureCopy 'workflow-state-main-valid.json'; $item.workspace.status_entries = 'not-an-array'; Test-WorkflowStateContract $item | Out-Null }
    Assert-RejectedCase 'duplicate review-thread ID' { $item = Get-FixtureCopy 'workflow-state-feature-valid.json'; $item.github.review_threads.items[1].id = $item.github.review_threads.items[0].id; Test-WorkflowStateContract $item | Out-Null }

    if ($valid_count -ne 3 -or $rejection_count -ne 8) { throw 'The expected contract case counts were not reached.' }
    Write-Output 'workflow-state contract: 3 valid fixtures accepted; 8 invalid cases rejected.'
    exit 0
}
catch {
    Write-Output "workflow-state contract: FAIL - $($_.Exception.Message)"
    exit 1
}
