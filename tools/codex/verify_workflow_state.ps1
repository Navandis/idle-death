#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

## Emits one validated, read-only snapshot of the local checkout and its GitHub workflow evidence.
## This script owns neither repository state nor credentials; it only composes command output into the public contract.

$EXPECTED_REPOSITORY = 'Navandis/idle-death'
$EXPECTED_REMOTE = 'origin'
$script:queries = New-Object System.Collections.ArrayList

function Add-WorkflowQuery {
    param([string]$Name, [bool]$Ok, [int]$ExitCode, [AllowNull()][object]$Error)

    [void]$script:queries.Add([pscustomobject]@{
        name = $Name
        ok = $Ok
        exit_code = $ExitCode
        error = if ($null -eq $Error) { $null } else { [string]$Error }
    })
}

function Invoke-WorkflowNative {
    ## Captures native stderr as data so expected gh 404s cannot become terminating PowerShell errors.
    param([Parameter(Mandatory = $true)][string]$Executable, [Parameter(Mandatory = $true)][string[]]$Arguments)

    $previous_preference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& $Executable @Arguments 2>&1)
        return [pscustomobject]@{ exit_code = [int]$LASTEXITCODE; text = (($output | Out-String).Trim()) }
    }
    catch {
        return [pscustomobject]@{ exit_code = 1; text = '' }
    }
    finally {
        $ErrorActionPreference = $previous_preference
    }
}

function Get-WorkflowLines {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) { return @() }
    return @([regex]::Split($Text.TrimEnd("`r", "`n"), "`r?`n") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Get-NormalizedOriginUrl {
    param([string]$Url)

    if ([string]::IsNullOrWhiteSpace($Url)) { return $null }
    $trimmed = $Url.Trim().TrimEnd('/')
    if ($trimmed.EndsWith('.git')) { $trimmed = $trimmed.Substring(0, $trimmed.Length - 4) }
    if ($trimmed -match '^(git@|ssh://git@)github\.com[:/]([^/]+)/(.+)$') { return "https://github.com/$($Matches[2])/$($Matches[3])" }
    if ($trimmed -match '^https?://github\.com/([^/]+)/(.+)$') { return "https://github.com/$($Matches[1])/$($Matches[2])" }
    return $trimmed
}

function Get-CommandInfo {
    param([string]$Name)

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        Add-WorkflowQuery "local.$Name.path" $false 1 'Required command is unavailable.'
        throw "Required command is unavailable: $Name"
    }
    Add-WorkflowQuery "local.$Name.path" $true 0 $null
    return $command.Source
}

function Invoke-RequiredLocal {
    param([string]$Name, [string]$Executable, [string[]]$Arguments)

    $response = Invoke-WorkflowNative $Executable $Arguments
    if ($response.exit_code -ne 0) {
        Add-WorkflowQuery $Name $false $response.exit_code 'Local Git inspection failed.'
        throw "Local inspection failed: $Name"
    }
    Add-WorkflowQuery $Name $true $response.exit_code $null
    return $response.text
}

function Invoke-GithubValue {
    param([string]$Name, [string]$GhPath, [string[]]$Arguments, [bool]$AllowNotFound = $false)

    $response = Invoke-WorkflowNative $GhPath $Arguments
    if ($response.exit_code -eq 0) {
        Add-WorkflowQuery $Name $true 0 $null
        return [pscustomobject]@{ ok = $true; value = $response.text }
    }
    if ($AllowNotFound -and $response.text -match '(?i)(404|not found)') {
        Add-WorkflowQuery $Name $true $response.exit_code $null
        return [pscustomobject]@{ ok = $true; value = $null }
    }
    Add-WorkflowQuery $Name $false $response.exit_code "GitHub query failed (exit code $($response.exit_code))."
    return [pscustomobject]@{ ok = $false; value = $null }
}

function Convert-GithubJson {
    param([string]$Name, [object]$Response)

    if (-not $Response.ok) { return $null }
    try {
        return $Response.value | ConvertFrom-Json
    }
    catch {
        Add-WorkflowQuery "$Name.parse" $false 1 'GitHub query returned invalid JSON.'
        return $null
    }
}

$state = [pscustomobject]@{
    schema_version = 1
    tool = 'verify_workflow_state'
    generated_at_utc = [DateTime]::UtcNow.ToString('o')
    result = 'fail'
    repository = [pscustomobject]@{ root = $null; full_name = $EXPECTED_REPOSITORY; origin_url = $null; branch = $null; head = $null; origin_main = $null; remote_main = $null; upstream = $null; remote_feature_sha = $null }
    tools = [pscustomobject]@{ git_path = $null; git_version = $null; gh_path = $null; gh_version = $null }
    workspace = [pscustomobject]@{ status_entries = @(); staged_paths = @(); publish_request_present = $false; index_lock_present = $false }
    github = [pscustomobject]@{ login = $null; matching_pr_count = 0; pull_request = $null; check_runs = @(); workflow_runs = @(); review_threads = [pscustomobject]@{ total_count = 0; unresolved_count = 0; items = @() } }
    queries = @()
}

try {
    if ($args.Count -ne 0) {
        Add-WorkflowQuery 'invariant.arguments' $false 1 'This verifier accepts no arguments.'
        throw 'Unsupported arguments.'
    }

    . (Join-Path $PSScriptRoot 'workflow_state_contract.ps1')
    $schema_path = Join-Path $PSScriptRoot 'workflow-state.schema.json'
    try {
        $schema = Get-Content -LiteralPath $schema_path -Raw | ConvertFrom-Json
        if ($schema.'$schema' -ne 'https://json-schema.org/draft/2020-12/schema') { throw 'Unexpected schema dialect.' }
        Add-WorkflowQuery 'schema.document' $true 0 $null
    }
    catch {
        Add-WorkflowQuery 'schema.document' $false 1 'Schema document could not be parsed.'
        throw
    }

    $root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
    $state.repository.root = $root
    $git_path = Get-CommandInfo 'git'
    $gh_path = Get-CommandInfo 'gh'
    $state.tools.git_path = $git_path
    $state.tools.gh_path = $gh_path
    $state.tools.git_version = Invoke-RequiredLocal 'local.git_version' $git_path @('--version')
    $state.tools.gh_version = Invoke-RequiredLocal 'local.gh_version' $gh_path @('--version')

    $git_root = Invoke-RequiredLocal 'local.repository_root' $git_path @('-C', $root, 'rev-parse', '--show-toplevel')
    if ([System.IO.Path]::GetFullPath($git_root) -ne $root.TrimEnd([System.IO.Path]::DirectorySeparatorChar)) {
        Add-WorkflowQuery 'invariant.repository_root' $false 1 'Script location is not the Git repository root.'
        throw 'Repository root mismatch.'
    }
    Add-WorkflowQuery 'invariant.repository_root' $true 0 $null
    $state.repository.branch = Invoke-RequiredLocal 'local.branch' $git_path @('-C', $root, 'branch', '--show-current')
    $state.repository.head = Invoke-RequiredLocal 'local.head' $git_path @('-C', $root, 'rev-parse', 'HEAD')
    $state.repository.origin_main = Invoke-RequiredLocal 'local.origin_main' $git_path @('-C', $root, 'rev-parse', "$EXPECTED_REMOTE/main")
    $origin_raw = Invoke-RequiredLocal 'local.origin_url' $git_path @('-C', $root, 'remote', 'get-url', $EXPECTED_REMOTE)
    $state.repository.origin_url = Get-NormalizedOriginUrl $origin_raw
    if ($state.repository.origin_url -ne "https://github.com/$EXPECTED_REPOSITORY") {
        Add-WorkflowQuery 'invariant.repository_identity' $false 1 'Origin does not identify the expected GitHub repository.'
        throw 'Unexpected origin repository.'
    }
    Add-WorkflowQuery 'invariant.repository_identity' $true 0 $null
    $upstream_response = Invoke-WorkflowNative $git_path @('-C', $root, 'rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{upstream}')
    if ($upstream_response.exit_code -eq 0) { $state.repository.upstream = $upstream_response.text; Add-WorkflowQuery 'local.upstream' $true 0 $null }
    else { Add-WorkflowQuery 'local.upstream' $true $upstream_response.exit_code $null }
    $state.workspace.status_entries = @(Get-WorkflowLines (Invoke-RequiredLocal 'local.status' $git_path @('-C', $root, 'status', '--porcelain=v1', '--untracked-files=all')))
    $state.workspace.staged_paths = @(Get-WorkflowLines (Invoke-RequiredLocal 'local.staged_paths' $git_path @('-C', $root, 'diff', '--cached', '--name-only')) | Sort-Object)
    $state.workspace.publish_request_present = Test-Path -LiteralPath (Join-Path $root '.codex-publish-request.json')
    Add-WorkflowQuery 'local.publish_request' $true 0 $null
    $state.workspace.index_lock_present = Test-Path -LiteralPath (Join-Path $root '.git\index.lock')
    Add-WorkflowQuery 'local.index_lock' $true 0 $null

    $login = Invoke-GithubValue 'github.login' $gh_path @('api', 'user', '--jq', '.login')
    if ($login.ok) { $state.github.login = $login.value }
    $remote_main = Invoke-GithubValue 'github.remote_main' $gh_path @('api', "repos/$EXPECTED_REPOSITORY/git/ref/heads/main", '--jq', '.object.sha')
    if ($remote_main.ok) { $state.repository.remote_main = $remote_main.value }
    if ($state.repository.branch -ne 'main') {
        $feature = Invoke-GithubValue 'github.remote_feature' $gh_path @('api', "repos/$EXPECTED_REPOSITORY/git/ref/heads/$($state.repository.branch)", '--jq', '.object.sha') $true
        if ($feature.ok) { $state.repository.remote_feature_sha = $feature.value }
    }

    $head_filter = [System.Uri]::EscapeDataString("Navandis:$($state.repository.branch)")
    $pr_response = Invoke-GithubValue 'github.matching_prs' $gh_path @('api', "repos/$EXPECTED_REPOSITORY/pulls?state=open&head=$head_filter&per_page=100")
    $pr_list = Convert-GithubJson 'github.matching_prs' $pr_response
    if ($null -ne $pr_list) {
        $prs = @($pr_list)
        $state.github.matching_pr_count = $prs.Count
        if ($prs.Count -gt 1) {
            Add-WorkflowQuery 'invariant.matching_pr_count' $false 1 'More than one matching open pull request exists.'
            throw 'More than one matching pull request exists.'
        }
        if ($prs.Count -eq 1) {
            $number = [int]$prs[0].number
            $detail_response = Invoke-GithubValue 'github.pull_request' $gh_path @('api', "repos/$EXPECTED_REPOSITORY/pulls/$number")
            $detail = Convert-GithubJson 'github.pull_request' $detail_response
            if ($null -ne $detail) {
                $labels = @($detail.labels | ForEach-Object { [string]$_.name } | Sort-Object)
                $state.github.pull_request = [pscustomobject]@{ number = [int]$detail.number; url = $detail.html_url; state = $detail.state; draft = $detail.draft; mergeable = $detail.mergeable; base_ref = $detail.base.ref; head_ref = $detail.head.ref; head_sha = $detail.head.sha; author = $detail.user.login; labels = $labels; auto_merge = ($null -ne $detail.auto_merge) }
                $review_query = 'query($owner:String!, $name:String!, $number:Int!) { repository(owner:$owner,name:$name) { pullRequest(number:$number) { reviewThreads(first:100) { nodes { id isResolved isOutdated path line } } } } }'
                $review_response = Invoke-GithubValue 'github.review_threads' $gh_path @('api', 'graphql', '-f', "query=$review_query", '-F', 'owner=Navandis', '-F', 'name=idle-death', '-F', "number=$number")
                $review_data = Convert-GithubJson 'github.review_threads' $review_response
                if ($null -ne $review_data) {
                    $items = @($review_data.data.repository.pullRequest.reviewThreads.nodes | ForEach-Object { [pscustomobject]@{ id = $_.id; is_resolved = [bool]$_.isResolved; is_outdated = [bool]$_.isOutdated; path = $_.path; line = $_.line } } | Sort-Object id)
                    $state.github.review_threads = [pscustomobject]@{ total_count = $items.Count; unresolved_count = @($items | Where-Object { -not $_.is_resolved }).Count; items = $items }
                }
            }
        }
    }

    if ($null -ne $state.repository.head) {
        $checks_response = Invoke-GithubValue 'github.check_runs' $gh_path @('api', "repos/$EXPECTED_REPOSITORY/commits/$($state.repository.head)/check-runs?per_page=100")
        $checks_data = Convert-GithubJson 'github.check_runs' $checks_response
        if ($null -ne $checks_data) {
            $state.github.check_runs = @($checks_data.check_runs | ForEach-Object { [pscustomobject]@{ id = [int64]$_.id; name = $_.name; status = $_.status; conclusion = $_.conclusion; app_id = if ($null -eq $_.app) { $null } else { [int64]$_.app.id }; app_name = if ($null -eq $_.app) { $null } else { $_.app.name }; app_slug = if ($null -eq $_.app) { $null } else { $_.app.slug }; details_url = $_.details_url } } | Sort-Object name, id)
        }
        $runs_response = Invoke-GithubValue 'github.workflow_runs' $gh_path @('api', "repos/$EXPECTED_REPOSITORY/actions/runs?head_sha=$($state.repository.head)&per_page=100")
        $runs_data = Convert-GithubJson 'github.workflow_runs' $runs_response
        if ($null -ne $runs_data) {
            $state.github.workflow_runs = @($runs_data.workflow_runs | ForEach-Object { [pscustomobject]@{ id = [int64]$_.id; name = $_.name; number = [int]$_.run_number; attempt = [int]$_.run_attempt; event = $_.event; status = $_.status; conclusion = $_.conclusion; head_branch = $_.head_branch; head_sha = $_.head_sha; url = $_.html_url } } | Sort-Object id)
        }
    }

    $failed_github = @($script:queries | Where-Object { -not $_.ok -and $_.name -like 'github.*' })
    $state.result = if ($failed_github.Count -gt 0) { 'partial' } else { 'pass' }
}
catch {
    if (@($script:queries | Where-Object { -not $_.ok }).Count -eq 0) {
        Add-WorkflowQuery 'invariant.unhandled' $false 1 'Verifier setup failed.'
    }
    $state.result = 'fail'
}

$state.queries = @($script:queries | Sort-Object name)
try {
    Test-WorkflowStateContract $state | Out-Null
}
catch {
    Add-WorkflowQuery 'schema.output' $false 1 'Generated output failed contract validation.'
    $state.result = 'fail'
    $state.queries = @($script:queries | Sort-Object name)
    Test-WorkflowStateContract $state | Out-Null
}

[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
[Console]::Out.Write(($state | ConvertTo-Json -Depth 20 -Compress))
if ($state.result -eq 'pass') { exit 0 }
if ($state.result -eq 'partial') { exit 2 }
exit 1
