#requires -Version 5.1
Set-StrictMode -Version Latest

function Get-WorkflowStatePropertyNames {
    param([Parameter(Mandatory = $true)][object]$Object)

    return @($Object.PSObject.Properties | ForEach-Object { $_.Name })
}

function Assert-WorkflowState {
    param([Parameter(Mandatory = $true)][bool]$Condition, [Parameter(Mandatory = $true)][string]$Message)

    if (-not $Condition) {
        throw "Workflow-state contract violation: $Message"
    }
}

function Assert-WorkflowStateExactKeys {
    param(
        [Parameter(Mandatory = $true)][object]$Object,
        [Parameter(Mandatory = $true)][string[]]$Expected,
        [Parameter(Mandatory = $true)][string]$Path
    )

    Assert-WorkflowState ($null -ne $Object -and $Object -isnot [System.Array] -and $Object -isnot [string]) "$Path must be an object."
    $actual = @(Get-WorkflowStatePropertyNames $Object | Sort-Object)
    $wanted = @($Expected | Sort-Object)
    Assert-WorkflowState ($actual.Count -eq $wanted.Count -and -not (Compare-Object $actual $wanted)) "$Path has missing or unknown fields."
}

function Assert-WorkflowStateString {
    param([object]$Value, [string]$Path, [bool]$Nullable = $false)

    if ($null -eq $Value) {
        Assert-WorkflowState $Nullable "$Path must be a string."
        return
    }
    Assert-WorkflowState ($Value -is [string]) "$Path must be a string."
}

function Assert-WorkflowStateInteger {
    param([object]$Value, [string]$Path, [bool]$Nullable = $false, [long]$Minimum = [long]::MinValue)

    if ($null -eq $Value) {
        Assert-WorkflowState $Nullable "$Path must be an integer."
        return
    }
    Assert-WorkflowState ($Value -is [byte] -or $Value -is [int16] -or $Value -is [int32] -or $Value -is [int64]) "$Path must be an integer."
    Assert-WorkflowState ([long]$Value -ge $Minimum) "$Path is below its minimum."
}

function Assert-WorkflowStateArray {
    param([object]$Value, [string]$Path)

    Assert-WorkflowState ($Value -is [System.Array]) "$Path must be an array."
}

function Assert-WorkflowStateSha {
    param([object]$Value, [string]$Path, [bool]$Nullable = $true)

    Assert-WorkflowStateString $Value $Path $Nullable
    if ($null -ne $Value) {
        Assert-WorkflowState ($Value -cmatch '^[0-9a-f]{40}$') "$Path must be a lowercase 40-character SHA."
    }
}

function Assert-WorkflowStateNullableUri {
    param([object]$Value, [string]$Path)

    Assert-WorkflowStateString $Value $Path $true
    if ($null -ne $Value) {
        $uri = $null
        Assert-WorkflowState ([System.Uri]::TryCreate($Value, [System.UriKind]::Absolute, [ref]$uri)) "$Path must be an absolute URI."
    }
}

function Test-WorkflowStateContract {
    ## Validates the version-one read-only workflow-state payload. It owns no I/O and raises on the first invalid field.
    param([Parameter(Mandatory = $true)][object]$Document)

    $root_keys = @('schema_version', 'tool', 'generated_at_utc', 'result', 'repository', 'tools', 'workspace', 'github', 'queries')
    Assert-WorkflowStateExactKeys $Document $root_keys '$'
    Assert-WorkflowStateInteger $Document.schema_version '$.schema_version' $false 1
    Assert-WorkflowState ([int]$Document.schema_version -eq 1) '$.schema_version must be 1.'
    Assert-WorkflowStateString $Document.tool '$.tool'
    Assert-WorkflowState ($Document.tool -eq 'verify_workflow_state') '$.tool must identify this verifier.'
    Assert-WorkflowStateString $Document.generated_at_utc '$.generated_at_utc'
    $timestamp = [DateTimeOffset]::MinValue
    Assert-WorkflowState ($Document.generated_at_utc -cmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$' -and [DateTimeOffset]::TryParse($Document.generated_at_utc, [ref]$timestamp)) '$.generated_at_utc must be RFC3339-compatible.'
    Assert-WorkflowStateString $Document.result '$.result'
    Assert-WorkflowState (@('pass', 'partial', 'fail') -contains $Document.result) '$.result is invalid.'

    Assert-WorkflowStateExactKeys $Document.repository @('root', 'full_name', 'origin_url', 'branch', 'head', 'origin_main', 'remote_main', 'upstream', 'remote_feature_sha') '$.repository'
    foreach ($name in @('root', 'origin_url', 'branch', 'upstream')) { Assert-WorkflowStateString $Document.repository.$name "$.repository.$name" $true }
    Assert-WorkflowStateString $Document.repository.full_name '$.repository.full_name'
    Assert-WorkflowState ($Document.repository.full_name -eq 'Navandis/idle-death') '$.repository.full_name must be Navandis/idle-death.'
    foreach ($name in @('head', 'origin_main', 'remote_main', 'remote_feature_sha')) { Assert-WorkflowStateSha $Document.repository.$name "$.repository.$name" $true }
    if ($Document.repository.branch -eq 'main') { Assert-WorkflowState ($null -eq $Document.repository.remote_feature_sha) '$.repository.remote_feature_sha must be null on main.' }

    Assert-WorkflowStateExactKeys $Document.tools @('git_path', 'git_version', 'gh_path', 'gh_version') '$.tools'
    foreach ($name in @('git_path', 'git_version', 'gh_path', 'gh_version')) { Assert-WorkflowStateString $Document.tools.$name "$.tools.$name" $true }

    Assert-WorkflowStateExactKeys $Document.workspace @('status_entries', 'staged_paths', 'publish_request_present', 'index_lock_present') '$.workspace'
    foreach ($name in @('status_entries', 'staged_paths')) {
        Assert-WorkflowStateArray $Document.workspace.$name "$.workspace.$name"
        foreach ($entry in @($Document.workspace.$name)) { Assert-WorkflowStateString $entry "$.workspace.$name[]" }
    }
    foreach ($name in @('publish_request_present', 'index_lock_present')) { Assert-WorkflowState ($Document.workspace.$name -is [bool]) "$.workspace.$name must be Boolean." }

    Assert-WorkflowStateExactKeys $Document.github @('login', 'matching_pr_count', 'pull_request', 'check_runs', 'workflow_runs', 'review_threads') '$.github'
    Assert-WorkflowStateString $Document.github.login '$.github.login' $true
    Assert-WorkflowStateInteger $Document.github.matching_pr_count '$.github.matching_pr_count' $false 0
    Assert-WorkflowStateArray $Document.github.check_runs '$.github.check_runs'
    Assert-WorkflowStateArray $Document.github.workflow_runs '$.github.workflow_runs'

    if ($null -eq $Document.github.pull_request) {
        Assert-WorkflowState ([int]$Document.github.matching_pr_count -eq 0) '$.github.matching_pr_count must be zero without a pull request.'
    }
    else {
        $pr = $Document.github.pull_request
        Assert-WorkflowStateExactKeys $pr @('number', 'url', 'state', 'draft', 'mergeable', 'base_ref', 'head_ref', 'head_sha', 'author', 'labels', 'auto_merge') '$.github.pull_request'
        Assert-WorkflowState ([int]$Document.github.matching_pr_count -eq 1) '$.github.matching_pr_count must be one with a pull request.'
        Assert-WorkflowStateInteger $pr.number '$.github.pull_request.number' $false 1
        Assert-WorkflowStateNullableUri $pr.url '$.github.pull_request.url'
        foreach ($name in @('state', 'base_ref', 'head_ref', 'author')) { Assert-WorkflowStateString $pr.$name "$.github.pull_request.$name" $true }
        foreach ($name in @('draft', 'mergeable', 'auto_merge')) { Assert-WorkflowState ($null -eq $pr.$name -or $pr.$name -is [bool]) "$.github.pull_request.$name must be Boolean or null." }
        Assert-WorkflowStateSha $pr.head_sha '$.github.pull_request.head_sha' $true
        Assert-WorkflowStateArray $pr.labels '$.github.pull_request.labels'
        foreach ($label in @($pr.labels)) { Assert-WorkflowStateString $label '$.github.pull_request.labels[]' }
        $joined_labels = (@($pr.labels) -join "`0")
        $joined_sorted_labels = (@($pr.labels | Sort-Object) -join "`0")
        Assert-WorkflowState ($joined_labels -eq $joined_sorted_labels) '$.github.pull_request.labels must be sorted.'
    }

    foreach ($check in @($Document.github.check_runs)) {
        Assert-WorkflowStateExactKeys $check @('id', 'name', 'status', 'conclusion', 'app_id', 'app_name', 'app_slug', 'details_url') '$.github.check_runs[]'
        Assert-WorkflowStateInteger $check.id '$.github.check_runs[].id' $false 0
        foreach ($name in @('name', 'status')) { Assert-WorkflowStateString $check.$name "$.github.check_runs[].$name" }
        Assert-WorkflowState (@('queued', 'in_progress', 'completed', 'waiting', 'requested', 'pending') -contains $check.status) '$.github.check_runs[].status is invalid.'
        foreach ($name in @('conclusion', 'app_name', 'app_slug')) { Assert-WorkflowStateString $check.$name "$.github.check_runs[].$name" $true }
        Assert-WorkflowStateInteger $check.app_id '$.github.check_runs[].app_id' $true 0
        Assert-WorkflowStateNullableUri $check.details_url '$.github.check_runs[].details_url'
    }
    foreach ($run in @($Document.github.workflow_runs)) {
        Assert-WorkflowStateExactKeys $run @('id', 'name', 'number', 'attempt', 'event', 'status', 'conclusion', 'head_branch', 'head_sha', 'url') '$.github.workflow_runs[]'
        foreach ($name in @('id', 'number', 'attempt')) { Assert-WorkflowStateInteger $run.$name "$.github.workflow_runs[].$name" $false 0 }
        foreach ($name in @('name', 'event', 'status', 'head_branch')) { Assert-WorkflowStateString $run.$name "$.github.workflow_runs[].$name" $true }
        if ($null -ne $run.status) { Assert-WorkflowState (@('queued', 'in_progress', 'completed') -contains $run.status) '$.github.workflow_runs[].status is invalid.' }
        Assert-WorkflowStateString $run.conclusion '$.github.workflow_runs[].conclusion' $true
        Assert-WorkflowStateSha $run.head_sha '$.github.workflow_runs[].head_sha' $true
        Assert-WorkflowStateNullableUri $run.url '$.github.workflow_runs[].url'
    }

    $threads = $Document.github.review_threads
    Assert-WorkflowStateExactKeys $threads @('total_count', 'unresolved_count', 'items') '$.github.review_threads'
    Assert-WorkflowStateInteger $threads.total_count '$.github.review_threads.total_count' $false 0
    Assert-WorkflowStateInteger $threads.unresolved_count '$.github.review_threads.unresolved_count' $false 0
    Assert-WorkflowStateArray $threads.items '$.github.review_threads.items'
    Assert-WorkflowState ([int]$threads.unresolved_count -le [int]$threads.total_count) '$.github.review_threads.unresolved_count exceeds total_count.'
    Assert-WorkflowState (@($threads.items).Count -eq [int]$threads.total_count) '$.github.review_threads.items must equal total_count.'
    $thread_ids = @()
    foreach ($thread in @($threads.items)) {
        Assert-WorkflowStateExactKeys $thread @('id', 'is_resolved', 'is_outdated', 'path', 'line') '$.github.review_threads.items[]'
        Assert-WorkflowStateString $thread.id '$.github.review_threads.items[].id'
        Assert-WorkflowState ($thread.is_resolved -is [bool] -and $thread.is_outdated -is [bool]) '$.github.review_threads.items[] resolution fields must be Boolean.'
        Assert-WorkflowStateString $thread.path '$.github.review_threads.items[].path' $true
        Assert-WorkflowStateInteger $thread.line '$.github.review_threads.items[].line' $true 1
        $thread_ids += $thread.id
    }
    Assert-WorkflowState (@($thread_ids | Select-Object -Unique).Count -eq $thread_ids.Count) '$.github.review_threads contains duplicate IDs.'
    Assert-WorkflowState (@($threads.items | Where-Object { -not $_.is_resolved }).Count -eq [int]$threads.unresolved_count) '$.github.review_threads.unresolved_count disagrees with items.'

    Assert-WorkflowStateArray $Document.queries '$.queries'
    $failed = @()
    foreach ($query in @($Document.queries)) {
        Assert-WorkflowStateExactKeys $query @('name', 'ok', 'exit_code', 'error') '$.queries[]'
        Assert-WorkflowStateString $query.name '$.queries[].name'
        Assert-WorkflowState ($query.ok -is [bool]) '$.queries[].ok must be Boolean.'
        Assert-WorkflowStateInteger $query.exit_code '$.queries[].exit_code' $false 0
        Assert-WorkflowStateString $query.error '$.queries[].error' $true
        if ($null -ne $query.error) { Assert-WorkflowState ($query.error.Length -le 512) '$.queries[].error exceeds the bounded length.' }
        Assert-WorkflowState ($query.ok -or $null -ne $query.error) '$.queries[].error must explain a failed query.'
        Assert-WorkflowState ((-not $query.ok) -or $null -eq $query.error) '$.queries[].error must be null for a successful query.'
        if ($null -ne $query.error) { Assert-WorkflowState ($query.error -notmatch '(?i)(authorization|bearer|token|hosts\.yml)') '$.queries[].error contains prohibited credential material.' }
        if (-not $query.ok) { $failed += $query }
    }
    if ($Document.result -eq 'pass') { Assert-WorkflowState ($failed.Count -eq 0) '$.result pass cannot contain failed queries.' }
    if ($Document.result -eq 'partial') { Assert-WorkflowState ($failed.Count -gt 0 -and @($failed | Where-Object { $_.name -like 'github.*' }).Count -eq $failed.Count) '$.result partial requires only failed GitHub queries.' }
    if ($Document.result -eq 'fail') { Assert-WorkflowState ($failed.Count -gt 0 -and @($failed | Where-Object { $_.name -notlike 'github.*' }).Count -gt 0) '$.result fail requires a failed local, invariant, or schema query.' }
    return $true
}
