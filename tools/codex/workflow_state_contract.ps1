Set-StrictMode -Version Latest

## Validates the public workflow-state document without collecting repository or GitHub data.
## This library owns structural and semantic trust checks only; callers own evidence collection.

function Get-WorkflowStatePropertyNames {
    param([Parameter(Mandatory = $true)]$Value)
    if ($Value -is [System.Collections.IDictionary]) { return @($Value.Keys | ForEach-Object { [string]$_ }) }
    if ($Value -is [pscustomobject]) { return @($Value.PSObject.Properties.Name) }
    throw 'Expected an object.'
}

function Get-WorkflowStateProperty {
    param([Parameter(Mandatory = $true)]$Value, [Parameter(Mandatory = $true)][string]$Name)
    # JSON arrays must cross this helper as one object. PowerShell otherwise
    # enumerates them and a one-item array becomes indistinguishable from a scalar.
    $matches = @()
    if ($Value -is [System.Collections.IDictionary]) {
        foreach ($key in $Value.Keys) {
            if ([string]::Equals([string]$key, $Name, [System.StringComparison]::Ordinal)) { $matches += $key }
        }
        if ($matches.Count -ne 1) { throw "Expected exactly one property named $Name." }
        $propertyValue = $Value[$matches[0]]
    } else {
        foreach ($property in $Value.PSObject.Properties) {
            if ([string]::Equals($property.Name, $Name, [System.StringComparison]::Ordinal)) { $matches += $property }
        }
        if ($matches.Count -ne 1) { throw "Expected exactly one property named $Name." }
        $propertyValue = $matches[0].Value
    }
    if ($propertyValue -is [System.Array]) { return ,$propertyValue }
    return $propertyValue
}

function Test-WorkflowStateOrdinalMember {
    param([string]$Value, [string[]]$Candidates)
    foreach ($candidate in $Candidates) {
        if ([string]::Equals($Value, $candidate, [System.StringComparison]::Ordinal)) { return $true }
    }
    return $false
}

function Assert-WorkflowStateExactKeys {
    param($Value, [string[]]$Expected, [string]$Path)
    if ($null -eq $Value -or (($Value -isnot [System.Collections.IDictionary]) -and ($Value -isnot [pscustomobject]))) { throw "$Path must be an object." }
    $actual = @(Get-WorkflowStatePropertyNames $Value)
    if ($actual.Count -ne $Expected.Count) { throw "$Path has unexpected or missing fields." }
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($name in $actual) {
        if ((-not $seen.Add($name)) -or (-not (Test-WorkflowStateOrdinalMember $name $Expected))) { throw "$Path has unexpected or missing fields." }
    }
}

function Assert-WorkflowStateString {
    param($Value, [string]$Path, [bool]$Nullable = $false, [bool]$NonEmpty = $false)
    if ($null -eq $Value) { if ($Nullable) { return }; throw "$Path must not be null." }
    if ($Value -isnot [string]) { throw "$Path must be a string." }
    if ($NonEmpty -and [string]::IsNullOrWhiteSpace($Value)) { throw "$Path must not be empty." }
}

function Assert-WorkflowStateBoolean { param($Value, [string]$Path) if ($Value -isnot [bool]) { throw "$Path must be Boolean." } }

function Assert-WorkflowStateInteger {
    param($Value, [string]$Path, [Int64]$Minimum = [Int64]::MinValue, [Int64]$Maximum = [Int64]::MaxValue, [bool]$Nullable = $false)
    if ($null -eq $Value) { if ($Nullable) { return }; throw "$Path must not be null." }
    if (($Value -isnot [byte]) -and ($Value -isnot [sbyte]) -and ($Value -isnot [int16]) -and ($Value -isnot [uint16]) -and ($Value -isnot [int32]) -and ($Value -isnot [uint32]) -and ($Value -isnot [int64])) { throw "$Path must be an integer." }
    if (([Int64]$Value -lt $Minimum) -or ([Int64]$Value -gt $Maximum)) { throw "$Path is outside its allowed range." }
}

function Assert-WorkflowStateArray { param($Value, [string]$Path) if ($null -eq $Value -or $Value -is [string] -or $Value -isnot [System.Array]) { throw "$Path must be an array." } }

function Assert-WorkflowStateUri {
    param($Value, [string]$Path, [bool]$Nullable = $true)
    Assert-WorkflowStateString $Value $Path $Nullable $false
    if ($null -ne $Value) { $uri = $null; if (-not [uri]::TryCreate($Value, [UriKind]::Absolute, [ref]$uri) -or $uri.AbsoluteUri -cne $Value) { throw "$Path must be a normalized absolute URI." } }
}

function Assert-WorkflowStateSha { param($Value, [string]$Path) Assert-WorkflowStateString $Value $Path $true $false; if ($null -ne $Value -and $Value -cnotmatch '^[0-9a-f]{40}$') { throw "$Path must be a lowercase 40-character SHA." } }

function Assert-WorkflowStateSortedUniqueStrings {
    param($Value, [string]$Path)
    Assert-WorkflowStateArray $Value $Path
    $previous = $null
    foreach ($item in $Value) {
        Assert-WorkflowStateString $item "$Path item" $false $false
        if ($null -ne $previous -and [string]::CompareOrdinal($previous, $item) -ge 0) { throw "$Path must be strictly sorted with no duplicates." }
        $previous = $item
    }
}

function Assert-WorkflowStateOrdinalUniqueStrings {
    param($Value, [string]$Path)
    Assert-WorkflowStateArray $Value $Path
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($item in $Value) {
        Assert-WorkflowStateString $item "$Path item" $false $false
        if (-not $seen.Add($item)) { throw "$Path must not contain duplicate strings." }
    }
}

function Test-WorkflowStateSensitiveError {
    param([string]$ErrorText)
    return [regex]::IsMatch($ErrorText, '(authorization|bearer|token|hosts\.yml|ghp_[a-z0-9_]+|gho_[a-z0-9_]+|ghu_[a-z0-9_]+|ghs_[a-z0-9_]+|ghr_[a-z0-9_]+|github_pat_[a-z0-9_]+)', ([System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::CultureInvariant))
}

function Assert-WorkflowStateCanonicalUtcTimestamp {
    param([string]$Timestamp, [string]$Path)
    $pattern = '\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,7})?Z\z'
    if (-not [regex]::IsMatch($Timestamp, $pattern, [System.Text.RegularExpressions.RegexOptions]::CultureInvariant)) { throw "$Path must be a canonical RFC3339 UTC timestamp." }
    $parsed = [DateTime]::MinValue
    if (-not [DateTime]::TryParseExact($Timestamp, "yyyy-MM-dd'T'HH:mm:ss.FFFFFFFK", [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind, [ref]$parsed)) { throw "$Path must be a canonical RFC3339 UTC timestamp." }
}

function Assert-WorkflowStateQuery {
    param($Query, [string]$Path)
    Assert-WorkflowStateExactKeys $Query @('scope','name','ok','exit_code','error') $Path
    $scope = Get-WorkflowStateProperty $Query 'scope'
    Assert-WorkflowStateString $scope "$Path.scope" $false $true
    if (-not (Test-WorkflowStateOrdinalMember $scope @('local','github','invariant','schema'))) { throw "$Path.scope is invalid." }
    Assert-WorkflowStateString (Get-WorkflowStateProperty $Query 'name') "$Path.name" $false $true
    $ok = Get-WorkflowStateProperty $Query 'ok'; Assert-WorkflowStateBoolean $ok "$Path.ok"
    Assert-WorkflowStateInteger (Get-WorkflowStateProperty $Query 'exit_code') "$Path.exit_code" -2147483648 2147483647 $true
    $errorValue = Get-WorkflowStateProperty $Query 'error'
    Assert-WorkflowStateString $errorValue "$Path.error" $true $false
    if ($ok -and $null -ne $errorValue) { throw "$Path.error must be null for a successful query." }
    if ((-not $ok) -and ([string]::IsNullOrWhiteSpace($errorValue) -or $errorValue.Length -gt 512)) { throw "$Path.error must be a bounded nonempty string for a failed query." }
    if ($null -ne $errorValue -and (Test-WorkflowStateSensitiveError $errorValue)) { throw "$Path.error contains credential-like material." }
}

function Assert-WorkflowStatePullRequest {
    param($PullRequest, [string]$Path)
    Assert-WorkflowStateExactKeys $PullRequest @('number','url','state','draft','mergeable','base_ref','head_ref','head_sha','author','labels','auto_merge') $Path
    Assert-WorkflowStateInteger (Get-WorkflowStateProperty $PullRequest 'number') "$Path.number" 1 ([Int64]::MaxValue) $true
    Assert-WorkflowStateUri (Get-WorkflowStateProperty $PullRequest 'url') "$Path.url" $true
    foreach ($name in @('state','base_ref','head_ref','author')) { Assert-WorkflowStateString (Get-WorkflowStateProperty $PullRequest $name) "$Path.$name" $true $false }
    foreach ($name in @('draft','mergeable','auto_merge')) { $value = Get-WorkflowStateProperty $PullRequest $name; if ($null -ne $value) { Assert-WorkflowStateBoolean $value "$Path.$name" } }
    Assert-WorkflowStateSha (Get-WorkflowStateProperty $PullRequest 'head_sha') "$Path.head_sha"
    Assert-WorkflowStateSortedUniqueStrings (Get-WorkflowStateProperty $PullRequest 'labels') "$Path.labels"
}

function Test-WorkflowStateContract {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)]$Document)
    Assert-WorkflowStateExactKeys $Document @('schema_version','tool','generated_at_utc','result','repository','tools','workspace','github','queries') 'root'
    Assert-WorkflowStateInteger (Get-WorkflowStateProperty $Document 'schema_version') 'schema_version' 1 1
    if ((Get-WorkflowStateProperty $Document 'tool') -cne 'verify_workflow_state') { throw 'tool must be verify_workflow_state.' }
    $timestamp = Get-WorkflowStateProperty $Document 'generated_at_utc'; Assert-WorkflowStateString $timestamp 'generated_at_utc' $false $true
    Assert-WorkflowStateCanonicalUtcTimestamp $timestamp 'generated_at_utc'
    $result = Get-WorkflowStateProperty $Document 'result'; if (-not (Test-WorkflowStateOrdinalMember $result @('pass','partial','fail'))) { throw 'result is invalid.' }

    $repository = Get-WorkflowStateProperty $Document 'repository'
    Assert-WorkflowStateExactKeys $repository @('root','full_name','remote_name','origin_fetch_urls','origin_push_urls','branch','head','origin_main','remote_main','upstream','remote_feature_sha') 'repository'
    foreach ($name in @('root','branch','upstream')) { Assert-WorkflowStateString (Get-WorkflowStateProperty $repository $name) "repository.$name" $true $false }
    if ((Get-WorkflowStateProperty $repository 'full_name') -cne 'Navandis/idle-death') { throw 'repository.full_name is invalid.' }
    if ((Get-WorkflowStateProperty $repository 'remote_name') -cne 'origin') { throw 'repository.remote_name is invalid.' }
    foreach ($name in @('origin_fetch_urls','origin_push_urls')) {
        $urls = Get-WorkflowStateProperty $repository $name; Assert-WorkflowStateSortedUniqueStrings $urls "repository.$name"
        foreach ($url in $urls) { Assert-WorkflowStateUri $url "repository.$name item" $false; if ($url -cne 'https://github.com/Navandis/idle-death') { throw "repository.$name must contain the normalized repository URL." } }
    }
    foreach ($name in @('head','origin_main','remote_main','remote_feature_sha')) { Assert-WorkflowStateSha (Get-WorkflowStateProperty $repository $name) "repository.$name" }
    if ((Get-WorkflowStateProperty $repository 'branch') -ceq 'main' -and $null -ne (Get-WorkflowStateProperty $repository 'remote_feature_sha')) { throw 'repository.remote_feature_sha must be null on main.' }

    $tools = Get-WorkflowStateProperty $Document 'tools'; Assert-WorkflowStateExactKeys $tools @('git_path','git_version','gh_path','gh_version') 'tools'
    foreach ($name in @('git_path','git_version','gh_path','gh_version')) { Assert-WorkflowStateString (Get-WorkflowStateProperty $tools $name) "tools.$name" $true $false }
    $workspace = Get-WorkflowStateProperty $Document 'workspace'; Assert-WorkflowStateExactKeys $workspace @('status_entries','staged_paths','publish_request_present','index_lock_path','index_lock_present') 'workspace'
    foreach ($name in @('status_entries','staged_paths')) { Assert-WorkflowStateOrdinalUniqueStrings (Get-WorkflowStateProperty $workspace $name) "workspace.$name" }
    Assert-WorkflowStateBoolean (Get-WorkflowStateProperty $workspace 'publish_request_present') 'workspace.publish_request_present'
    Assert-WorkflowStateString (Get-WorkflowStateProperty $workspace 'index_lock_path') 'workspace.index_lock_path' $true $false
    Assert-WorkflowStateBoolean (Get-WorkflowStateProperty $workspace 'index_lock_present') 'workspace.index_lock_present'

    $github = Get-WorkflowStateProperty $Document 'github'; Assert-WorkflowStateExactKeys $github @('login','matching_pr_count','pull_request','check_runs','workflow_runs','review_threads') 'github'
    Assert-WorkflowStateString (Get-WorkflowStateProperty $github 'login') 'github.login' $true $false
    $prCount = Get-WorkflowStateProperty $github 'matching_pr_count'; Assert-WorkflowStateInteger $prCount 'github.matching_pr_count' 0 1
    $pr = Get-WorkflowStateProperty $github 'pull_request'; if ($null -eq $pr) { if ($prCount -ne 0) { throw 'github.matching_pr_count must be zero without a pull request.' } } else { Assert-WorkflowStatePullRequest $pr 'github.pull_request'; if ($prCount -ne 1) { throw 'github.matching_pr_count must be one with a pull request.' } }
    foreach ($name in @('check_runs','workflow_runs')) { Assert-WorkflowStateArray (Get-WorkflowStateProperty $github $name) "github.$name" }
    foreach ($check in (Get-WorkflowStateProperty $github 'check_runs')) { Assert-WorkflowStateExactKeys $check @('id','name','status','conclusion','app_id','app_name','app_slug','details_url') 'github.check_runs item'; foreach ($name in @('id','app_id')) { Assert-WorkflowStateInteger (Get-WorkflowStateProperty $check $name) "github.check_runs.$name" ([Int64]::MinValue) ([Int64]::MaxValue) $true }; foreach ($name in @('name','status','conclusion','app_name','app_slug')) { Assert-WorkflowStateString (Get-WorkflowStateProperty $check $name) "github.check_runs.$name" $true $false }; Assert-WorkflowStateUri (Get-WorkflowStateProperty $check 'details_url') 'github.check_runs.details_url' $true }
    foreach ($run in (Get-WorkflowStateProperty $github 'workflow_runs')) { Assert-WorkflowStateExactKeys $run @('id','name','number','attempt','event','status','conclusion','head_branch','head_sha','url') 'github.workflow_runs item'; foreach ($name in @('id','number','attempt')) { Assert-WorkflowStateInteger (Get-WorkflowStateProperty $run $name) "github.workflow_runs.$name" ([Int64]::MinValue) ([Int64]::MaxValue) $true }; foreach ($name in @('name','event','status','conclusion','head_branch')) { Assert-WorkflowStateString (Get-WorkflowStateProperty $run $name) "github.workflow_runs.$name" $true $false }; Assert-WorkflowStateSha (Get-WorkflowStateProperty $run 'head_sha') 'github.workflow_runs.head_sha'; Assert-WorkflowStateUri (Get-WorkflowStateProperty $run 'url') 'github.workflow_runs.url' $true }
    $threads = Get-WorkflowStateProperty $github 'review_threads'; Assert-WorkflowStateExactKeys $threads @('total_count','unresolved_count','items') 'github.review_threads'; $total = Get-WorkflowStateProperty $threads 'total_count'; $unresolved = Get-WorkflowStateProperty $threads 'unresolved_count'; Assert-WorkflowStateInteger $total 'github.review_threads.total_count' 0 ([Int64]::MaxValue); Assert-WorkflowStateInteger $unresolved 'github.review_threads.unresolved_count' 0 ([Int64]::MaxValue); $items = Get-WorkflowStateProperty $threads 'items'; Assert-WorkflowStateArray $items 'github.review_threads.items'; if ($items.Count -ne $total -or $unresolved -gt $total) { throw 'github.review_threads counts do not match items.' }; $seenThreadIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal); $recount = 0; foreach ($item in $items) { Assert-WorkflowStateExactKeys $item @('id','is_resolved','is_outdated','path','line') 'github.review_threads item'; Assert-WorkflowStateString (Get-WorkflowStateProperty $item 'id') 'github.review_threads.id' $false $true; $threadId = Get-WorkflowStateProperty $item 'id'; if (-not $seenThreadIds.Add($threadId)) { throw 'github.review_threads IDs must be unique.' }; Assert-WorkflowStateBoolean (Get-WorkflowStateProperty $item 'is_resolved') 'github.review_threads.is_resolved'; Assert-WorkflowStateBoolean (Get-WorkflowStateProperty $item 'is_outdated') 'github.review_threads.is_outdated'; Assert-WorkflowStateString (Get-WorkflowStateProperty $item 'path') 'github.review_threads.path' $true $false; Assert-WorkflowStateInteger (Get-WorkflowStateProperty $item 'line') 'github.review_threads.line' 1 ([Int64]::MaxValue) $true; if (-not (Get-WorkflowStateProperty $item 'is_resolved')) { $recount++ } }; if ($recount -ne $unresolved) { throw 'github.review_threads unresolved_count does not match items.' }

    $queries = Get-WorkflowStateProperty $Document 'queries'; Assert-WorkflowStateArray $queries 'queries'; $failed = @(); $seenQueries = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal); foreach ($query in $queries) { Assert-WorkflowStateQuery $query 'queries item'; $key = "$(Get-WorkflowStateProperty $query 'scope')`u001f$(Get-WorkflowStateProperty $query 'name')"; if (-not $seenQueries.Add($key)) { throw 'queries must not duplicate scope/name pairs.' }; if (-not (Get-WorkflowStateProperty $query 'ok')) { $failed += $query } }
    if ([string]::Equals($result, 'pass', [System.StringComparison]::Ordinal) -and $failed.Count -ne 0) { throw 'pass must contain no failed query.' }
    if ([string]::Equals($result, 'partial', [System.StringComparison]::Ordinal) -and (($failed.Count -eq 0) -or @($failed | Where-Object { -not [string]::Equals((Get-WorkflowStateProperty $_ 'scope'), 'github', [System.StringComparison]::Ordinal) }).Count -ne 0)) { throw 'partial requires only failed GitHub queries.' }
    if ([string]::Equals($result, 'fail', [System.StringComparison]::Ordinal) -and @($failed | Where-Object { Test-WorkflowStateOrdinalMember (Get-WorkflowStateProperty $_ 'scope') @('local','invariant','schema') }).Count -eq 0) { throw 'fail requires a failed local, invariant, or schema query.' }
    if (([string]::Equals($result, 'pass', [System.StringComparison]::Ordinal)) -or ([string]::Equals($result, 'partial', [System.StringComparison]::Ordinal))) { if ([string]::IsNullOrWhiteSpace((Get-WorkflowStateProperty $repository 'root')) -or [string]::IsNullOrWhiteSpace((Get-WorkflowStateProperty $repository 'branch')) -or $null -eq (Get-WorkflowStateProperty $repository 'head') -or $null -eq (Get-WorkflowStateProperty $repository 'origin_main') -or (Get-WorkflowStateProperty $repository 'origin_fetch_urls').Count -eq 0 -or (Get-WorkflowStateProperty $repository 'origin_push_urls').Count -eq 0 -or [string]::IsNullOrWhiteSpace((Get-WorkflowStateProperty $workspace 'index_lock_path'))) { throw 'pass and partial require complete local-state evidence.' } }
    return $true
}
