param()

$primitive_path = Join-Path $PSScriptRoot '..\workflow_state_primitives.ps1'
$contract_path = Join-Path $PSScriptRoot '..\workflow_state_document_contract.ps1'
$schema_path = Join-Path $PSScriptRoot '..\workflow-state.schema.json'
$fixture_directory = Join-Path $PSScriptRoot 'fixtures'
$script:valid_count = 0
$script:acceptance_count = 0
$script:rejection_count = 0
$script:schema_policy_mutation_count = 0

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

function Get-ConditionalCount {
    param([object]$Value)
    $count = 0
    if ($Value -is [System.Collections.IDictionary]) {
        foreach ($key in $Value.Keys) {
            if ($key -eq 'if') { $count += 1 }
            $count += Get-ConditionalCount -Value $Value[$key]
        }
    }
    elseif ($Value -is [pscustomobject]) {
        foreach ($property in $Value.PSObject.Properties) {
            if ($property.Name -eq 'if') { $count += 1 }
            $count += Get-ConditionalCount -Value $property.Value
        }
    }
    elseif ($Value -is [System.Array]) {
        foreach ($item in $Value) { $count += Get-ConditionalCount -Value $item }
    }
    return $count
}

function Assert-ExactStringArray {
    param([object]$Actual, [string[]]$Expected, [string]$Name)
    $actual_values = @($Actual)
    Assert-TestTrue -Condition ($actual_values.Count -eq $Expected.Count) -Name "$Name has the expected item count"
    for ($index = 0; $index -lt $Expected.Count; $index += 1) {
        Assert-TestTrue -Condition (($actual_values[$index] -is [string]) -and ($actual_values[$index] -ceq $Expected[$index])) -Name "$Name item $index matches exactly"
    }
}

function Assert-WorkflowStateSchemaPolicies {
    param([object]$Schema)

    # The schema is parsed data here, rather than an executable validation
    # engine. Inspect every predicate and consequence so a policy can neither
    # disappear nor become a permissive placeholder without this test failing.
    Assert-TestTrue -Condition ($Schema.allOf.Count -eq 3) -Name 'root owns exactly three result conditionals'
    Assert-TestTrue -Condition ($Schema.'$defs'.repository.allOf.Count -eq 1) -Name 'repository owns exactly one conditional'
    Assert-TestTrue -Condition ($Schema.'$defs'.github.allOf.Count -eq 1) -Name 'GitHub owns exactly one conditional'
    Assert-TestTrue -Condition ($Schema.'$defs'.query.allOf.Count -eq 1) -Name 'query owns exactly one conditional'
    Assert-TestTrue -Condition ((Get-ConditionalCount $Schema) -eq 6) -Name 'schema contains exactly six conditional-policy nodes'

    $pass_policy = $Schema.allOf[0]
    Assert-TestTrue -Condition ($pass_policy.if.properties.result.const -ceq 'pass') -Name 'pass predicate requires pass result'
    Assert-TestTrue -Condition (($pass_policy.then.properties.queries.not.contains.properties.ok.const -is [bool]) -and ($pass_policy.then.properties.queries.not.contains.properties.ok.const -eq $false)) -Name 'pass rejects failed queries'
    Assert-ExactStringArray -Actual $pass_policy.then.properties.queries.not.contains.required -Expected @('ok') -Name 'pass failed-query selector required fields'

    $partial_policy = $Schema.allOf[1]
    Assert-TestTrue -Condition ($partial_policy.if.properties.result.const -ceq 'partial') -Name 'partial predicate requires partial result'
    $partial_positive = $partial_policy.then.properties.queries.contains
    Assert-TestTrue -Condition ($partial_positive.properties.scope.const -ceq 'github') -Name 'partial requires a failed GitHub query'
    Assert-TestTrue -Condition (($partial_positive.properties.ok.const -is [bool]) -and ($partial_positive.properties.ok.const -eq $false)) -Name 'partial GitHub query is failed'
    Assert-ExactStringArray -Actual $partial_positive.required -Expected @('scope', 'ok') -Name 'partial positive selector required fields'
    Assert-TestTrue -Condition ($partial_policy.then.properties.queries.allOf.Count -eq 1) -Name 'partial owns one non-GitHub exclusion branch'
    $partial_exclusion = $partial_policy.then.properties.queries.allOf[0].not.contains
    Assert-TestTrue -Condition ($partial_exclusion.properties.scope.not.const -ceq 'github') -Name 'partial excludes non-GitHub failed queries'
    Assert-TestTrue -Condition (($partial_exclusion.properties.ok.const -is [bool]) -and ($partial_exclusion.properties.ok.const -eq $false)) -Name 'partial exclusion selects failed queries'
    Assert-ExactStringArray -Actual $partial_exclusion.required -Expected @('scope', 'ok') -Name 'partial exclusion selector required fields'

    $fail_policy = $Schema.allOf[2]
    Assert-TestTrue -Condition ($fail_policy.if.properties.result.const -ceq 'fail') -Name 'fail predicate requires fail result'
    $fail_query = $fail_policy.then.properties.queries.contains
    Assert-ExactStringArray -Actual $fail_query.properties.scope.enum -Expected @('local', 'invariant', 'schema') -Name 'fail allowed failure scopes'
    Assert-TestTrue -Condition (($fail_query.properties.ok.const -is [bool]) -and ($fail_query.properties.ok.const -eq $false)) -Name 'fail consequence requires a failed query'
    Assert-ExactStringArray -Actual $fail_query.required -Expected @('scope', 'ok') -Name 'fail selector required fields'

    $main_policy = $Schema.'$defs'.repository.allOf[0]
    Assert-TestTrue -Condition ($main_policy.if.properties.branch.const -ceq 'main') -Name 'main predicate selects the main branch'
    Assert-ExactStringArray -Actual $main_policy.if.required -Expected @('branch') -Name 'main predicate required fields'
    Assert-TestTrue -Condition ($main_policy.then.properties.remote_feature_sha.type -ceq 'null') -Name 'main requires a null remote feature SHA'

    $pull_request_policy = $Schema.'$defs'.github.allOf[0]
    Assert-ExactStringArray -Actual $pull_request_policy.if.required -Expected @('pull_request') -Name 'pull-request predicate required fields'
    Assert-TestTrue -Condition ($pull_request_policy.if.properties.pull_request.type -ceq 'null') -Name 'pull-request predicate selects null pull requests'
    Assert-TestTrue -Condition (($pull_request_policy.then.properties.matching_pr_count.const -is [System.Int32]) -and ($pull_request_policy.then.properties.matching_pr_count.const -eq 0)) -Name 'null pull requests require count zero'
    Assert-TestTrue -Condition (($pull_request_policy.else.properties.matching_pr_count.const -is [System.Int32]) -and ($pull_request_policy.else.properties.matching_pr_count.const -eq 1)) -Name 'identified pull requests require count one'

    $query_policy = $Schema.'$defs'.query.allOf[0]
    Assert-ExactStringArray -Actual $query_policy.if.required -Expected @('ok') -Name 'query predicate required fields'
    Assert-TestTrue -Condition (($query_policy.if.properties.ok.const -is [bool]) -and ($query_policy.if.properties.ok.const -eq $true)) -Name 'query predicate selects successful queries'
    Assert-TestTrue -Condition ($query_policy.then.properties.error.type -ceq 'null') -Name 'successful queries require null errors'
    Assert-TestTrue -Condition ($query_policy.else.properties.error.type -ceq 'string') -Name 'failed queries require string errors'
    Assert-TestTrue -Condition ($query_policy.else.properties.error.minLength -eq 1) -Name 'failed query errors require content'
    Assert-TestTrue -Condition ($query_policy.else.properties.error.pattern -ceq '.*\S.*') -Name 'failed query errors require nonwhitespace content'
}

function Copy-WorkflowStateSchema {
    param([object]$Schema)
    return ($Schema | ConvertTo-Json -Depth 100 | ConvertFrom-Json)
}

function Test-SchemaPolicyRejects {
    param([string]$Name, [scriptblock]$Action)
    $rejected = $false
    try { & $Action } catch { $rejected = $true }
    if (-not $rejected) { throw "Schema-policy mutation was accepted: $Name." }
    $script:schema_policy_mutation_count += 1
}

try {
    Test-Parser -Path $primitive_path
    Test-Parser -Path $contract_path
    Test-Parser -Path $PSCommandPath

    $schema = Get-Content -Raw $schema_path | ConvertFrom-Json
    foreach ($fixture_name in @('workflow-state-pass-valid.json', 'workflow-state-partial-valid.json', 'workflow-state-fail-valid.json', 'workflow-state-unknown-field-invalid.json')) {
        [void](New-Fixture $fixture_name)
    }

    # This inspects the local schema's structural policy. It deliberately does
    # not claim to execute an external Draft 2020-12 validation engine.
    Assert-TestTrue -Condition ($schema.'$schema' -eq 'https://json-schema.org/draft/2020-12/schema') -Name 'Draft 2020-12 declaration'
    Assert-TestTrue -Condition ($schema.additionalProperties -eq $false) -Name 'closed root shape'
    Assert-TestTrue -Condition ((@($schema.required) -join '|') -eq 'schema_version|tool|generated_at_utc|result|repository|tools|workspace|github|queries') -Name 'root required keys'
    Assert-TestTrue -Condition ($schema.properties.generated_at_utc.pattern -eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{1,7})?Z$') -Name 'canonical timestamp pattern'
    Assert-TestTrue -Condition (($schema.'$defs'.query.properties.exit_code.minimum -eq -2147483648) -and ($schema.'$defs'.query.properties.exit_code.maximum -eq 2147483647)) -Name 'signed Int32 query bounds'
    Assert-TestTrue -Condition ($schema.properties.queries.minItems -eq 1) -Name 'queries minimum item count'
    Assert-WorkflowStateSchemaPolicies -Schema $schema
    Test-SchemaPolicyRejects -Name 'pass consequence removed' -Action { $copy = Copy-WorkflowStateSchema $schema; $copy.allOf[0].then = [pscustomobject]@{}; Assert-WorkflowStateSchemaPolicies -Schema $copy }
    Test-SchemaPolicyRejects -Name 'partial GitHub scope changed' -Action { $copy = Copy-WorkflowStateSchema $schema; $copy.allOf[1].then.properties.queries.contains.properties.scope.const = 'local'; Assert-WorkflowStateSchemaPolicies -Schema $copy }
    Test-SchemaPolicyRejects -Name 'fail query success changed' -Action { $copy = Copy-WorkflowStateSchema $schema; $copy.allOf[2].then.properties.queries.contains.properties.ok.const = $true; Assert-WorkflowStateSchemaPolicies -Schema $copy }
    Test-SchemaPolicyRejects -Name 'main remote feature SHA type changed' -Action { $copy = Copy-WorkflowStateSchema $schema; $copy.'$defs'.repository.allOf[0].then.properties.remote_feature_sha.type = 'string'; Assert-WorkflowStateSchemaPolicies -Schema $copy }
    Test-SchemaPolicyRejects -Name 'null pull-request count changed' -Action { $copy = Copy-WorkflowStateSchema $schema; $copy.'$defs'.github.allOf[0].then.properties.matching_pr_count.const = 1; Assert-WorkflowStateSchemaPolicies -Schema $copy }
    Test-SchemaPolicyRejects -Name 'successful query error type changed' -Action { $copy = Copy-WorkflowStateSchema $schema; $copy.'$defs'.query.allOf[0].then.properties.error.type = 'string'; Assert-WorkflowStateSchemaPolicies -Schema $copy }
    Assert-TestTrue -Condition (($schema.'$defs'.pull_request.properties.url.type -eq 'string') -and ($schema.'$defs'.pull_request.properties.head_sha.'$ref' -eq '#/$defs/sha') -and ($schema.'$defs'.pull_request.properties.number.minimum -eq 1)) -Name 'identifiable pull-request fields'

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
    Test-Accepts -Name 'case-distinct query names remain distinct' -Action { $d = New-Fixture 'workflow-state-pass-valid.json'; $d.queries[1].name = 'Status'; Assert-NoOutput 'case-distinct query names' $d }
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
    Assert-TestTrue -Condition ((ConvertFrom-Json $before | ConvertTo-Json -Depth 20) -eq $after) -Name 'successful assertion does not mutate input'

    Assert-TestTrue -Condition ($script:valid_count -eq 3) -Name 'exact valid fixture count'
    Assert-TestTrue -Condition ($script:acceptance_count -eq 5) -Name 'exact acceptance count'
    Assert-TestTrue -Condition ($script:rejection_count -eq 57) -Name 'exact rejection count'
    Assert-TestTrue -Condition ($script:schema_policy_mutation_count -eq 6) -Name 'exact schema-policy mutation rejection count'
    Write-Output 'PASS workflow_state_document_contract valid=3 accepted=5 rejected=57 schema_conditionals=6 schema_policy_mutations=6 primitive_composition=PASS assert_no_output=PASS mutation=PASS'
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
