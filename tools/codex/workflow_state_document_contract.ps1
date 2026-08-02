<#
Workflow-state public document contract.

This library validates the complete in-memory workflow-state document used by
the verifier boundary. It owns document vocabulary, nested record validation,
and cross-field semantics. It does not collect evidence, construct query
records or envelopes, serialize JSON, redact text, access files beyond loading
its fixed primitive dependency, or perform external operations.
#>

$primitive_path = Join-Path $PSScriptRoot 'workflow_state_primitives.ps1'
. $primitive_path

function Assert-WorkflowStateDocumentExactKeys {
    param([object]$Value, [object]$ExpectedNames)
    Assert-WorkflowStateExactKeys -Value $Value -ExpectedNames $ExpectedNames
}

function Get-WorkflowStateDocumentProperty {
    param([object]$Value, [string]$Name)
    return ,(Get-WorkflowStateExactProperty -Value $Value -Name $Name)
}

function Assert-WorkflowStateDocumentNullableString {
    param([object]$Value)
    Assert-WorkflowStateScalarString -Value $Value -AllowNull
}

function Assert-WorkflowStateDocumentStringArray {
    param([object]$Value, [switch]$Sorted, [switch]$RequireNonEmpty)
    if ($Sorted) {
        Assert-WorkflowStateSortedUniqueStrings -Value $Value
    }
    else {
        Assert-WorkflowStateOrdinalUniqueStrings -Value $Value
    }
    if ($RequireNonEmpty -and ($Value.Length -eq 0)) {
        throw 'Workflow-state array must not be empty.'
    }
}

function Assert-WorkflowStateDocumentOriginUrls {
    param([object]$Value)
    Assert-WorkflowStateDocumentStringArray -Value $Value -Sorted
    foreach ($url in $Value) {
        Assert-WorkflowStateAbsoluteUri -Value $url
        Assert-WorkflowStateLiteralString -Value $url -Literal 'https://github.com/Navandis/idle-death'
    }
}

function Assert-WorkflowStateDocumentRepository {
    param([object]$Value)
    Assert-WorkflowStateDocumentExactKeys -Value $Value -ExpectedNames @(
        'root', 'full_name', 'remote_name', 'origin_fetch_urls', 'origin_push_urls',
        'branch', 'head', 'origin_main', 'remote_main', 'upstream', 'remote_feature_sha'
    )
    Assert-WorkflowStateDocumentNullableString -Value (Get-WorkflowStateDocumentProperty $Value 'root')
    Assert-WorkflowStateLiteralString -Value (Get-WorkflowStateDocumentProperty $Value 'full_name') -Literal 'Navandis/idle-death'
    Assert-WorkflowStateLiteralString -Value (Get-WorkflowStateDocumentProperty $Value 'remote_name') -Literal 'origin'
    Assert-WorkflowStateDocumentOriginUrls -Value (Get-WorkflowStateDocumentProperty $Value 'origin_fetch_urls')
    Assert-WorkflowStateDocumentOriginUrls -Value (Get-WorkflowStateDocumentProperty $Value 'origin_push_urls')
    Assert-WorkflowStateDocumentNullableString -Value (Get-WorkflowStateDocumentProperty $Value 'branch')
    foreach ($name in @('head', 'origin_main', 'remote_main', 'remote_feature_sha')) {
        Assert-WorkflowStateSha -Value (Get-WorkflowStateDocumentProperty $Value $name) -AllowNull
    }
    Assert-WorkflowStateDocumentNullableString -Value (Get-WorkflowStateDocumentProperty $Value 'upstream')
    $branch = Get-WorkflowStateDocumentProperty $Value 'branch'
    if (($branch -is [string]) -and [string]::Equals($branch, 'main', [System.StringComparison]::Ordinal) -and
        ($null -ne (Get-WorkflowStateDocumentProperty $Value 'remote_feature_sha'))) {
        throw 'Workflow-state main branch cannot have a remote feature SHA.'
    }
}

function Assert-WorkflowStateDocumentTools {
    param([object]$Value)
    Assert-WorkflowStateDocumentExactKeys -Value $Value -ExpectedNames @('git_path', 'git_version', 'gh_path', 'gh_version')
    foreach ($name in @('git_path', 'git_version', 'gh_path', 'gh_version')) {
        Assert-WorkflowStateDocumentNullableString -Value (Get-WorkflowStateDocumentProperty $Value $name)
    }
}

function Assert-WorkflowStateDocumentWorkspace {
    param([object]$Value)
    Assert-WorkflowStateDocumentExactKeys -Value $Value -ExpectedNames @(
        'status_entries', 'staged_paths', 'publish_request_present', 'index_lock_path', 'index_lock_present'
    )
    Assert-WorkflowStateDocumentStringArray -Value (Get-WorkflowStateDocumentProperty $Value 'status_entries')
    Assert-WorkflowStateDocumentStringArray -Value (Get-WorkflowStateDocumentProperty $Value 'staged_paths')
    Assert-WorkflowStateBoolean -Value (Get-WorkflowStateDocumentProperty $Value 'publish_request_present')
    Assert-WorkflowStateDocumentNullableString -Value (Get-WorkflowStateDocumentProperty $Value 'index_lock_path')
    Assert-WorkflowStateBoolean -Value (Get-WorkflowStateDocumentProperty $Value 'index_lock_present')
}

function Assert-WorkflowStateDocumentPullRequest {
    param([object]$Value)
    Assert-WorkflowStateDocumentExactKeys -Value $Value -ExpectedNames @(
        'number', 'url', 'state', 'draft', 'mergeable', 'base_ref', 'head_ref', 'head_sha', 'author', 'labels', 'auto_merge'
    )
    Assert-WorkflowStateInteger -Value (Get-WorkflowStateDocumentProperty $Value 'number') -Minimum 1
    Assert-WorkflowStateAbsoluteUri -Value (Get-WorkflowStateDocumentProperty $Value 'url')
    foreach ($name in @('state', 'base_ref', 'head_ref', 'author')) {
        Assert-WorkflowStateScalarString -Value (Get-WorkflowStateDocumentProperty $Value $name) -RequireNonWhitespace
    }
    Assert-WorkflowStateBoolean -Value (Get-WorkflowStateDocumentProperty $Value 'draft')
    $mergeable = Get-WorkflowStateDocumentProperty $Value 'mergeable'
    if ($null -ne $mergeable) { Assert-WorkflowStateBoolean -Value $mergeable }
    Assert-WorkflowStateSha -Value (Get-WorkflowStateDocumentProperty $Value 'head_sha')
    Assert-WorkflowStateDocumentStringArray -Value (Get-WorkflowStateDocumentProperty $Value 'labels') -Sorted
    $auto_merge = Get-WorkflowStateDocumentProperty $Value 'auto_merge'
    if ($null -ne $auto_merge) { Assert-WorkflowStateBoolean -Value $auto_merge }
}

function Assert-WorkflowStateDocumentCheckRun {
    param([object]$Value)
    Assert-WorkflowStateDocumentExactKeys -Value $Value -ExpectedNames @('id', 'name', 'status', 'conclusion', 'app_id', 'app_name', 'app_slug', 'details_url')
    foreach ($name in @('id', 'app_id')) { Assert-WorkflowStateInteger -Value (Get-WorkflowStateDocumentProperty $Value $name) -AllowNull }
    foreach ($name in @('name', 'status', 'conclusion', 'app_name', 'app_slug')) { Assert-WorkflowStateDocumentNullableString -Value (Get-WorkflowStateDocumentProperty $Value $name) }
    Assert-WorkflowStateAbsoluteUri -Value (Get-WorkflowStateDocumentProperty $Value 'details_url') -AllowNull
}

function Assert-WorkflowStateDocumentWorkflowRun {
    param([object]$Value)
    Assert-WorkflowStateDocumentExactKeys -Value $Value -ExpectedNames @('id', 'name', 'number', 'attempt', 'event', 'status', 'conclusion', 'head_branch', 'head_sha', 'url')
    foreach ($name in @('id', 'number', 'attempt')) { Assert-WorkflowStateInteger -Value (Get-WorkflowStateDocumentProperty $Value $name) -AllowNull }
    foreach ($name in @('name', 'event', 'status', 'conclusion', 'head_branch')) { Assert-WorkflowStateDocumentNullableString -Value (Get-WorkflowStateDocumentProperty $Value $name) }
    Assert-WorkflowStateSha -Value (Get-WorkflowStateDocumentProperty $Value 'head_sha') -AllowNull
    Assert-WorkflowStateAbsoluteUri -Value (Get-WorkflowStateDocumentProperty $Value 'url') -AllowNull
}

function Assert-WorkflowStateDocumentReviewThreads {
    param([object]$Value)
    Assert-WorkflowStateDocumentExactKeys -Value $Value -ExpectedNames @('total_count', 'unresolved_count', 'items')
    $total = Get-WorkflowStateDocumentProperty $Value 'total_count'
    $unresolved = Get-WorkflowStateDocumentProperty $Value 'unresolved_count'
    $items = Get-WorkflowStateDocumentProperty $Value 'items'
    Assert-WorkflowStateInteger -Value $total -Minimum 0
    Assert-WorkflowStateInteger -Value $unresolved -Minimum 0
    Assert-WorkflowStateArray -Value $items
    if ($items.Length -ne $total) { throw 'Workflow-state review-thread item count does not equal total count.' }
    if ($unresolved -gt $total) { throw 'Workflow-state unresolved count cannot exceed total count.' }
    $ids = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $actual_unresolved = 0
    foreach ($item in $items) {
        Assert-WorkflowStateDocumentExactKeys -Value $item -ExpectedNames @('id', 'is_resolved', 'is_outdated', 'path', 'line')
        $id = Get-WorkflowStateDocumentProperty $item 'id'
        Assert-WorkflowStateScalarString -Value $id -RequireNonWhitespace
        if (-not $ids.Add($id)) { throw 'Workflow-state review-thread IDs must be ordinally unique.' }
        $is_resolved = Get-WorkflowStateDocumentProperty $item 'is_resolved'
        Assert-WorkflowStateBoolean -Value $is_resolved
        Assert-WorkflowStateBoolean -Value (Get-WorkflowStateDocumentProperty $item 'is_outdated')
        Assert-WorkflowStateDocumentNullableString -Value (Get-WorkflowStateDocumentProperty $item 'path')
        Assert-WorkflowStateInteger -Value (Get-WorkflowStateDocumentProperty $item 'line') -AllowNull -Minimum 1
        if (-not $is_resolved) { $actual_unresolved += 1 }
    }
    if ($actual_unresolved -ne $unresolved) { throw 'Workflow-state unresolved review-thread count does not match items.' }
}

function Assert-WorkflowStateDocumentGitHub {
    param([object]$Value)
    Assert-WorkflowStateDocumentExactKeys -Value $Value -ExpectedNames @('login', 'matching_pr_count', 'pull_request', 'check_runs', 'workflow_runs', 'review_threads')
    Assert-WorkflowStateDocumentNullableString -Value (Get-WorkflowStateDocumentProperty $Value 'login')
    $count = Get-WorkflowStateDocumentProperty $Value 'matching_pr_count'
    Assert-WorkflowStateInteger -Value $count -Minimum 0 -Maximum 1
    $pull_request = Get-WorkflowStateDocumentProperty $Value 'pull_request'
    if ($null -eq $pull_request) {
        if ($count -ne 0) { throw 'Workflow-state null pull request requires matching count zero.' }
    }
    else {
        if ($count -ne 1) { throw 'Workflow-state present pull request requires matching count one.' }
        Assert-WorkflowStateDocumentPullRequest -Value $pull_request
    }
    $check_runs = Get-WorkflowStateDocumentProperty $Value 'check_runs'
    Assert-WorkflowStateArray -Value $check_runs
    foreach ($item in $check_runs) { Assert-WorkflowStateDocumentCheckRun -Value $item }
    $workflow_runs = Get-WorkflowStateDocumentProperty $Value 'workflow_runs'
    Assert-WorkflowStateArray -Value $workflow_runs
    foreach ($item in $workflow_runs) { Assert-WorkflowStateDocumentWorkflowRun -Value $item }
    $review_threads = Get-WorkflowStateDocumentProperty $Value 'review_threads'
    Assert-WorkflowStateDocumentReviewThreads -Value $review_threads
    if ($null -eq $pull_request) {
        $review_total = Get-WorkflowStateDocumentProperty $review_threads 'total_count'
        $review_unresolved = Get-WorkflowStateDocumentProperty $review_threads 'unresolved_count'
        $review_items = Get-WorkflowStateDocumentProperty $review_threads 'items'
        if (($review_total -ne 0) -or ($review_unresolved -ne 0) -or ($review_items.Length -ne 0)) {
            throw 'Workflow-state null pull request requires empty review-thread evidence.'
        }
    }
}

function Assert-WorkflowStateDocumentQueries {
    param([object]$Value)
    Assert-WorkflowStateArray -Value $Value
    if ($Value.Length -eq 0) { throw 'Workflow-state queries must not be empty.' }
    $pairs = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($query in $Value) {
        Assert-WorkflowStateDocumentExactKeys -Value $query -ExpectedNames @('scope', 'name', 'ok', 'exit_code', 'error')
        $scope = Get-WorkflowStateDocumentProperty $query 'scope'
        $name = Get-WorkflowStateDocumentProperty $query 'name'
        $ok = Get-WorkflowStateDocumentProperty $query 'ok'
        $error = Get-WorkflowStateDocumentProperty $query 'error'
        Assert-WorkflowStateEnumString -Value $scope -Candidates @('local', 'github', 'invariant', 'schema')
        Assert-WorkflowStateScalarString -Value $name -RequireNonWhitespace
        Assert-WorkflowStateBoolean -Value $ok
        Assert-WorkflowStateInteger -Value (Get-WorkflowStateDocumentProperty $query 'exit_code') -AllowNull -Minimum -2147483648 -Maximum 2147483647
        Assert-WorkflowStateScalarString -Value $error -AllowNull
        if (($null -ne $error) -and ($error.Length -gt 512)) { throw 'Workflow-state query error exceeds 512 characters.' }
        if ($ok -and ($null -ne $error)) { throw 'Workflow-state successful query requires null error.' }
        if ((-not $ok) -and (($null -eq $error) -or [string]::IsNullOrWhiteSpace($error))) { throw 'Workflow-state failed query requires a nonwhitespace error.' }
        if (($null -ne $error) -and (Test-WorkflowStateSensitiveError -Value $error)) { throw 'Workflow-state query error indicates sensitive credential material.' }
        if (-not $pairs.Add($scope + [char]0 + $name)) { throw 'Workflow-state query scope/name pairs must be ordinally unique.' }
    }
}

function Assert-WorkflowStateDocumentResultPolicy {
    param([object]$Document)
    $result = Get-WorkflowStateDocumentProperty $Document 'result'
    $queries = Get-WorkflowStateDocumentProperty $Document 'queries'
    $failed_scopes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($query in $queries) {
        if (-not (Get-WorkflowStateDocumentProperty $query 'ok')) { [void]$failed_scopes.Add((Get-WorkflowStateDocumentProperty $query 'scope')) }
    }
    if (($result -eq 'pass') -and ($failed_scopes.Count -ne 0)) { throw 'Workflow-state pass cannot contain failed queries.' }
    if (($result -eq 'partial') -and (($failed_scopes.Count -eq 0) -or ($failed_scopes.Count -ne 1) -or (-not $failed_scopes.Contains('github')))) { throw 'Workflow-state partial requires failed GitHub queries only.' }
    if (($result -eq 'fail') -and (-not ($failed_scopes.Contains('local') -or $failed_scopes.Contains('invariant') -or $failed_scopes.Contains('schema')))) { throw 'Workflow-state fail requires a failed local, invariant, or schema query.' }
    if (($result -eq 'pass') -or ($result -eq 'partial')) {
        $repository = Get-WorkflowStateDocumentProperty $Document 'repository'
        $workspace = Get-WorkflowStateDocumentProperty $Document 'workspace'
        foreach ($name in @('root', 'branch')) { Assert-WorkflowStateScalarString -Value (Get-WorkflowStateDocumentProperty $repository $name) -RequireNonWhitespace }
        foreach ($name in @('head', 'origin_main')) { if ($null -eq (Get-WorkflowStateDocumentProperty $repository $name)) { throw "Workflow-state $name is required for pass or partial." } }
        foreach ($name in @('origin_fetch_urls', 'origin_push_urls')) { if ((Get-WorkflowStateDocumentProperty $repository $name).Length -eq 0) { throw "Workflow-state $name is required for pass or partial." } }
        Assert-WorkflowStateScalarString -Value (Get-WorkflowStateDocumentProperty $workspace 'index_lock_path') -RequireNonWhitespace
    }
}

function Assert-WorkflowStateDocument {
    <# Validates one complete public workflow-state document without output or mutation. #>
    param([object]$Document)
    Assert-WorkflowStateDocumentExactKeys -Value $Document -ExpectedNames @('schema_version', 'tool', 'generated_at_utc', 'result', 'repository', 'tools', 'workspace', 'github', 'queries')
    Assert-WorkflowStateInteger -Value (Get-WorkflowStateDocumentProperty $Document 'schema_version') -Minimum 1 -Maximum 1
    Assert-WorkflowStateLiteralString -Value (Get-WorkflowStateDocumentProperty $Document 'tool') -Literal 'verify_workflow_state'
    Assert-WorkflowStateCanonicalUtcTimestamp -Value (Get-WorkflowStateDocumentProperty $Document 'generated_at_utc')
    Assert-WorkflowStateEnumString -Value (Get-WorkflowStateDocumentProperty $Document 'result') -Candidates @('pass', 'partial', 'fail')
    Assert-WorkflowStateDocumentRepository -Value (Get-WorkflowStateDocumentProperty $Document 'repository')
    Assert-WorkflowStateDocumentTools -Value (Get-WorkflowStateDocumentProperty $Document 'tools')
    Assert-WorkflowStateDocumentWorkspace -Value (Get-WorkflowStateDocumentProperty $Document 'workspace')
    Assert-WorkflowStateDocumentGitHub -Value (Get-WorkflowStateDocumentProperty $Document 'github')
    Assert-WorkflowStateDocumentQueries -Value (Get-WorkflowStateDocumentProperty $Document 'queries')
    Assert-WorkflowStateDocumentResultPolicy -Document $Document
}
