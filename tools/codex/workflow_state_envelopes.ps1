Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'workflow_state_contract.ps1')

## Builds validated, safe workflow-state failure documents without collecting external evidence.

function Get-WorkflowStateSanitizedError {
    param([AllowNull()][string]$ErrorText)
    $collapsed = if ($null -eq $ErrorText) { '' } else { [regex]::Replace($ErrorText, '\s+', ' ').Trim() }
    if ([string]::IsNullOrWhiteSpace($collapsed)) { return 'Unspecified failure.' }
    if (Test-WorkflowStateSensitiveError $collapsed) { return 'Sensitive error details redacted.' }
    if ($collapsed.Length -gt 512) { return $collapsed.Substring(0, 512) }
    return $collapsed
}

function New-WorkflowStateQueryRecord {
    param([Parameter(Mandatory = $true)][ValidateSet('local','github','invariant','schema', IgnoreCase = $false)][string]$Scope, [Parameter(Mandatory = $true)][string]$Name, [Parameter(Mandatory = $true)][bool]$Ok, [AllowNull()][Nullable[Int64]]$ExitCode, [AllowNull()][string]$ErrorText)
    if ([string]::IsNullOrWhiteSpace($Name)) { throw 'Query name must not be empty.' }
    if ($null -ne $ExitCode -and (($ExitCode -lt -2147483648) -or ($ExitCode -gt 2147483647))) { throw 'Query exit code must fit signed Int32.' }
    if ($Ok -and $null -ne $ErrorText) { throw 'A successful query cannot have an error.' }
    if (-not $Ok) { $ErrorText = Get-WorkflowStateSanitizedError $ErrorText }
    return [pscustomobject][ordered]@{ scope = $Scope; name = $Name; ok = $Ok; exit_code = $ExitCode; error = $ErrorText }
}

function New-WorkflowStateFailEnvelope {
    param([Parameter(Mandatory = $true)][ValidateSet('local','invariant','schema', IgnoreCase = $false)][string]$FailureScope, [Parameter(Mandatory = $true)][string]$FailureName, [AllowNull()][Nullable[Int64]]$ExitCode = -1, [AllowNull()][string]$ErrorText = 'Unspecified failure.')
    $query = New-WorkflowStateQueryRecord -Scope $FailureScope -Name $FailureName -Ok $false -ExitCode $ExitCode -ErrorText $ErrorText
    $document = [pscustomobject][ordered]@{
        schema_version = 1; tool = 'verify_workflow_state'; generated_at_utc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ', [Globalization.CultureInfo]::InvariantCulture); result = 'fail'
        repository = [pscustomobject][ordered]@{ root = $null; full_name = 'Navandis/idle-death'; remote_name = 'origin'; origin_fetch_urls = @(); origin_push_urls = @(); branch = $null; head = $null; origin_main = $null; remote_main = $null; upstream = $null; remote_feature_sha = $null }
        tools = [pscustomobject][ordered]@{ git_path = $null; git_version = $null; gh_path = $null; gh_version = $null }
        workspace = [pscustomobject][ordered]@{ status_entries = @(); staged_paths = @(); publish_request_present = $false; index_lock_path = $null; index_lock_present = $false }
        github = [pscustomobject][ordered]@{ login = $null; matching_pr_count = 0; pull_request = $null; check_runs = @(); workflow_runs = @(); review_threads = [pscustomobject][ordered]@{ total_count = 0; unresolved_count = 0; items = @() } }
        queries = @($query)
    }
    Test-WorkflowStateContract $document | Out-Null
    return $document
}

function ConvertTo-WorkflowStateJson {
    param([Parameter(Mandatory = $true)]$Document)
    Test-WorkflowStateContract $Document | Out-Null
    $json = $Document | ConvertTo-Json -Compress -Depth 12
    if ($json -match "[\r\n]") { throw 'Workflow-state JSON must be one line.' }
    return $json
}

function Get-WorkflowStateEmergencyFailJson {
    $timestamp = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ', [Globalization.CultureInfo]::InvariantCulture)
    return '{"schema_version":1,"tool":"verify_workflow_state","generated_at_utc":"' + $timestamp + '","result":"fail","repository":{"root":null,"full_name":"Navandis/idle-death","remote_name":"origin","origin_fetch_urls":[],"origin_push_urls":[],"branch":null,"head":null,"origin_main":null,"remote_main":null,"upstream":null,"remote_feature_sha":null},"tools":{"git_path":null,"git_version":null,"gh_path":null,"gh_version":null},"workspace":{"status_entries":[],"staged_paths":[],"publish_request_present":false,"index_lock_path":null,"index_lock_present":false},"github":{"login":null,"matching_pr_count":0,"pull_request":null,"check_runs":[],"workflow_runs":[],"review_threads":{"total_count":0,"unresolved_count":0,"items":[]}},"queries":[{"scope":"schema","name":"emergency_fail","ok":false,"exit_code":-1,"error":"Emergency contract failure."}]}'
}
