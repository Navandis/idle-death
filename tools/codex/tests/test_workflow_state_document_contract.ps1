param()

$primitive_path = Join-Path $PSScriptRoot '..\workflow_state_primitives.ps1'
$primitive_test_path = Join-Path $PSScriptRoot 'test_workflow_state_primitives.ps1'
$contract_path = Join-Path $PSScriptRoot '..\workflow_state_document_contract.ps1'
$fixture_directory = Join-Path $PSScriptRoot 'fixtures'
$script:valid_count = 0
$script:acceptance_count = 0
$script:rejection_count = 0

function Assert-TestTrue {
    param([bool]$Condition, [string]$Name)
    if (-not $Condition) { throw "Assertion failed: $Name." }
}

function Test-Accepts {
    param([string]$Name, [scriptblock]$Action)
    try { & $Action } catch { throw "Acceptance failed: $Name. $($_.Exception.Message)" }
    $script:acceptance_count += 1
}

function Test-Rejects {
    param([string]$Name, [scriptblock]$Action)
    $rejected = $false
    try { & $Action } catch { $rejected = $true }
    if (-not $rejected) { throw "Rejection failed: $Name." }
    $script:rejection_count += 1
}

function New-Fixture {
    param([string]$Name)
    return (Get-Content -Raw (Join-Path $fixture_directory $Name) | ConvertFrom-Json)
}

function Assert-NoOutput {
    param([string]$Name, [object]$Document)
    $output = @(& { Assert-WorkflowStateDocument -Document $Document })
    Assert-TestTrue -Condition ($output.Count -eq 0) -Name "$Name emits no success-stream output"
}

function Test-Parser {
    param([string]$Path)
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Path), [ref]$tokens, [ref]$errors)
    Assert-TestTrue -Condition ($errors.Count -eq 0) -Name "PowerShell parser accepts $Path"
}

try {
    Test-Parser -Path $primitive_path
    Test-Parser -Path $primitive_test_path
    Test-Parser -Path $contract_path
    Test-Parser -Path $PSCommandPath

    $contract_source = [System.IO.File]::ReadAllText($contract_path)
    Assert-TestTrue -Condition ($contract_source -match "workflow_state_primitives\.ps1") -Name 'fixed primitive dependency import'
    $primitive_source = [System.IO.File]::ReadAllText($primitive_path)
    $primitive_functions = [regex]::Matches($primitive_source, '(?im)^function\s+([A-Za-z0-9_-]+)') | ForEach-Object { $_.Groups[1].Value }
    foreach ($primitive_function in $primitive_functions) {
        Assert-TestTrue -Condition ($contract_source -notmatch "(?im)^function\s+$([regex]::Escape($primitive_function))\b") -Name "does not redefine $primitive_function"
    }
    $forbidden_functions = @('New-WorkflowStateQuery', 'New-WorkflowStateFailEnvelope', 'New-WorkflowStateEmergencyFailJson', 'Sanitize-WorkflowStateError', 'Redact-WorkflowStateError', 'ConvertTo-Json', 'ConvertFrom-Json', 'Invoke-WebRequest', 'Invoke-RestMethod', 'Start-Process', 'Remove-Item', 'Move-Item', 'git', 'gh')
    foreach ($forbidden in $forbidden_functions) {
        Assert-TestTrue -Condition ($contract_source -notmatch "(?im)^function\s+$([regex]::Escape($forbidden))\b") -Name "no $forbidden production function"
    }
    $contract_tokens = $null
    $contract_parse_errors = $null
    $contract_ast = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $contract_path), [ref]$contract_tokens, [ref]$contract_parse_errors)
    $forbidden_commands = @('git', 'git.exe', 'gh', 'gh.exe', 'curl', 'curl.exe', 'Invoke-WebRequest', 'Invoke-RestMethod', 'Start-Process', 'Remove-Item', 'Move-Item', 'Set-Content', 'Add-Content', 'Out-File')
    foreach ($command in $contract_ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true)) {
        $command_name = $command.GetCommandName()
        Assert-TestTrue -Condition (($null -eq $command_name) -or ($forbidden_commands -notcontains $command_name)) -Name "no forbidden production command $command_name"
    }
    . $contract_path

    foreach ($fixture_name in @('workflow-state-pass-valid.json', 'workflow-state-partial-valid.json', 'workflow-state-fail-valid.json')) {
        $fixture = New-Fixture $fixture_name
        Assert-NoOutput -Name $fixture_name -Document $fixture
        $script:valid_count += 1
    }
    $unknown = New-Fixture 'workflow-state-unknown-field-invalid.json'
    try { Assert-WorkflowStateDocument -Document $unknown; throw 'unknown field was accepted' } catch {
        Assert-TestTrue -Condition ($_.Exception.Message -match 'keys') -Name 'unknown-field fixture rejects only through exact keys'
    }

    Test-Accepts -Name 'no-fraction canonical timestamp' -Action { $d = New-Fixture 'workflow-state-pass-valid.json'; $d.generated_at_utc = '2026-08-02T12:34:56Z'; Assert-NoOutput 'no-fraction timestamp' $d }
    Test-Accepts -Name 'seven-fraction canonical timestamp' -Action { $d = New-Fixture 'workflow-state-pass-valid.json'; $d.generated_at_utc = '2026-08-02T12:34:56.1234567Z'; Assert-NoOutput 'seven-fraction timestamp' $d }
    Test-Accepts -Name 'case-distinct query names remain distinct' -Action { $d = New-Fixture 'workflow-state-pass-valid.json'; $d.queries[1].scope = 'local'; $d.queries[1].name = 'Status'; Assert-TestTrue -Condition (($d.queries[0].scope -ceq 'local') -and ($d.queries[0].name -ceq 'status') -and ($d.queries[1].scope -ceq 'local') -and ($d.queries[1].name -ceq 'Status')) -Name 'case-distinct query acceptance uses same exact scope and names'; Assert-NoOutput 'case-distinct query names' $d }
    Test-Accepts -Name 'case-distinct thread IDs remain distinct' -Action { Assert-NoOutput 'case-distinct thread IDs' (New-Fixture 'workflow-state-pass-valid.json') }
    Test-Accepts -Name 'main permits null remote feature SHA' -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.repository.branch = 'main'; Assert-NoOutput 'main null remote feature SHA' $d }

    Test-Rejects -Name 'wrong-case root key' -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.PSObject.Properties.Remove('result'); $d | Add-Member -NotePropertyName Result -NotePropertyValue 'fail'; Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'wrong-case nested key' -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.repository.PSObject.Properties.Remove('root'); $d.repository | Add-Member -NotePropertyName Root -NotePropertyValue $null; Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'wrong-case result' -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.result = 'FAIL'; Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'wrong-case query scope' -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.queries[0].scope = 'LOCAL'; Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'timestamp space' -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.generated_at_utc = '2026-08-02 12:34:56Z'; Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'timestamp offset' -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.generated_at_utc = '2026-08-02T12:34:56+00:00'; Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'timestamp invalid calendar' -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.generated_at_utc = '2026-02-30T12:34:56Z'; Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'duplicate workspace entry' -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.workspace.status_entries = [object[]]@('x', 'x'); Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'exit code underflow' -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.queries[0].exit_code = [Int64]-2147483649; Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'exit code overflow' -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.queries[0].exit_code = [Int64]2147483648; Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'pass failed query' -Action { $d = New-Fixture 'workflow-state-pass-valid.json'; $d.queries[0].ok = $false; $d.queries[0].error = 'synthetic'; Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'partial local failure' -Action { $d = New-Fixture 'workflow-state-partial-valid.json'; $d.queries[0].ok = $false; $d.queries[0].error = 'synthetic'; Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'fail github-only failure' -Action { $d = New-Fixture 'workflow-state-partial-valid.json'; $d.result = 'fail'; Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'pull-request count contradiction' -Action { $d = New-Fixture 'workflow-state-pass-valid.json'; $d.github.matching_pr_count = 0; Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'main remote feature SHA' -Action { $d = New-Fixture 'workflow-state-pass-valid.json'; $d.repository.branch = 'main'; Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'malformed SHA' -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.repository.head = 'BAD'; Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'malformed URI' -Action { $d = New-Fixture 'workflow-state-pass-valid.json'; $d.github.pull_request.url = 'not uri'; Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'review item count mismatch' -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.github.review_threads.total_count = 1; Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'review unresolved count mismatch' -Action { $d = New-Fixture 'workflow-state-pass-valid.json'; $d.github.review_threads.unresolved_count = 2; Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'duplicate review IDs' -Action { $d = New-Fixture 'workflow-state-pass-valid.json'; $d.github.review_threads.items[1].id = 'A'; Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'duplicate query pair' -Action { $d = New-Fixture 'workflow-state-pass-valid.json'; $d.queries[1].scope = 'local'; $d.queries[1].name = 'status'; Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'unsorted labels' -Action { $d = New-Fixture 'workflow-state-pass-valid.json'; $d.github.pull_request.labels = [object[]]@('zeta', 'alpha'); Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'duplicate origin fetch URLs' -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.repository.origin_fetch_urls = [object[]]@('https://github.com/Navandis/idle-death', 'https://github.com/Navandis/idle-death'); Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'duplicate origin push URLs' -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.repository.origin_push_urls = [object[]]@('https://github.com/Navandis/idle-death', 'https://github.com/Navandis/idle-death'); Assert-WorkflowStateDocument $d }
    foreach ($prefix in @('authorization', 'bearer', 'token', 'hosts.yml', 'ghp_', 'gho_', 'ghu_', 'ghs_', 'ghr_', 'github_pat_')) { Test-Rejects -Name "sensitive error $prefix" -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.queries[0].error = $prefix; Assert-WorkflowStateDocument $d } }
    Test-Rejects -Name 'scalar for array' -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.workspace.status_entries = 'x'; Assert-WorkflowStateDocument $d }
    foreach ($field in @('tool', 'result')) { Test-Rejects -Name "one-item array root $field" -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.$field = [object[]]@($d.$field); Assert-WorkflowStateDocument $d } }
    foreach ($field in @('full_name', 'remote_name')) { Test-Rejects -Name "one-item array repository $field" -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.repository.$field = [object[]]@($d.repository.$field); Assert-WorkflowStateDocument $d } }
    Test-Rejects -Name 'one-item array query scope' -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.queries[0].scope = [object[]]@('local'); Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'non-string dictionary key' -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.repository = [hashtable]@{ 7 = 'bad' }; Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'multidimensional document array' -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.workspace.status_entries = [Array]::CreateInstance([object], 1, 1); Assert-WorkflowStateDocument $d }
    Test-Rejects -Name 'empty queries array' -Action { $d = New-Fixture 'workflow-state-fail-valid.json'; $d.queries = [object[]]@(); Assert-WorkflowStateDocument $d }
    foreach ($field in @('root', 'branch', 'head', 'origin_main', 'origin_fetch_urls', 'origin_push_urls')) { Test-Rejects -Name "pass local evidence $field" -Action { $d = New-Fixture 'workflow-state-pass-valid.json'; if ($field -match 'urls') { $d.repository.$field = [object[]]@() } else { $d.repository.$field = $null }; Assert-WorkflowStateDocument $d } }
    Test-Rejects -Name 'pass local evidence index lock path' -Action { $d = New-Fixture 'workflow-state-pass-valid.json'; $d.workspace.index_lock_path = $null; Assert-WorkflowStateDocument $d }
    foreach ($identity in @('url', 'state', 'base_ref', 'head_ref', 'head_sha', 'author')) { Test-Rejects -Name "pull-request null identity $identity" -Action { $d = New-Fixture 'workflow-state-pass-valid.json'; $d.github.pull_request.$identity = $null; Assert-WorkflowStateDocument $d } }
    Test-Rejects -Name 'pull-request malformed head SHA' -Action { $d = New-Fixture 'workflow-state-pass-valid.json'; $d.github.pull_request.head_sha = 'bad'; Assert-WorkflowStateDocument $d }

    $before = Get-Content -Raw (Join-Path $fixture_directory 'workflow-state-pass-valid.json')
    $representative = New-Fixture 'workflow-state-pass-valid.json'
    Assert-NoOutput -Name 'representative mutation proof' -Document $representative
    $after = $representative | ConvertTo-Json -Depth 20
    $before_snapshot = ConvertFrom-Json $before | ConvertTo-Json -Depth 20
    Assert-TestTrue -Condition ([string]::Equals($before_snapshot, $after, [System.StringComparison]::Ordinal)) -Name 'successful assertion does not mutate input'

    $case_only_baseline = New-Fixture 'workflow-state-pass-valid.json'
    $case_only_baseline_snapshot = $case_only_baseline | ConvertTo-Json -Depth 20
    $case_only_mutation = New-Fixture 'workflow-state-pass-valid.json'
    $case_only_mutation.github.pull_request.state = 'open'
    $case_only_mutation_snapshot = $case_only_mutation | ConvertTo-Json -Depth 20
    Assert-TestTrue -Condition (-not [string]::Equals($case_only_baseline_snapshot, $case_only_mutation_snapshot, [System.StringComparison]::Ordinal)) -Name 'ordinal mutation proof detects case-only change'

    Assert-TestTrue -Condition ($script:valid_count -eq 3) -Name 'exact valid fixture count'
    Assert-TestTrue -Condition ($script:acceptance_count -eq 5) -Name 'exact acceptance count'
    Assert-TestTrue -Condition ($script:rejection_count -eq 57) -Name 'exact rejection count'
    Write-Output 'PASS workflow_state_document_contract valid=3 accepted=5 rejected=57 primitive_composition=PASS assert_no_output=PASS mutation=PASS query_identity=PASS'
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
