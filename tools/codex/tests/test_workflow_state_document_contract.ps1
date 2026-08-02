param()

$primitive_path = Join-Path $PSScriptRoot '..\workflow_state_primitives.ps1'
$contract_path = Join-Path $PSScriptRoot '..\workflow_state_document_contract.ps1'
$schema_path = Join-Path $PSScriptRoot '..\workflow-state.schema.json'
$fixture_directory = Join-Path $PSScriptRoot 'fixtures'
$script:valid_count = 0
$script:acceptance_count = 0
$script:rejection_count = 0
$script:schema_policy_mutation_count = 0
$script:schema_keyword_case_mutation_count = 0

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

function Get-WorkflowStateSchemaExactProperty {
    param([object]$Object, [string]$Name)

    # ConvertFrom-Json returns PSCustomObject values whose normal member lookup
    # is case-insensitive in Windows PowerShell 5.1. JSON Schema keywords are
    # case-sensitive, so enumerate actual names and select one ordinal match.
    $matches = @()
    if ($Object -is [System.Collections.IDictionary]) {
        foreach ($entry in $Object.GetEnumerator()) {
            if (($entry.Key -is [string]) -and [string]::Equals($entry.Key, $Name, [System.StringComparison]::Ordinal)) {
                $matches += [pscustomobject]@{ Name = $entry.Key; Value = $entry.Value }
            }
        }
    }
    elseif ($Object -is [pscustomobject]) {
        foreach ($property in $Object.PSObject.Properties) {
            if ([string]::Equals($property.Name, $Name, [System.StringComparison]::Ordinal)) {
                $matches += [pscustomobject]@{ Name = $property.Name; Value = $property.Value }
            }
        }
    }
    else {
        throw "Schema value does not expose property '$Name'."
    }

    if ($matches.Count -ne 1) {
        throw "Schema property '$Name' must have exactly one ordinal match."
    }
    # Do not enumerate a JSON array into the success stream. Callers must
    # receive the property value itself so array-valued schema keywords retain
    # their type and length instead of becoming unrelated pipeline results.
    Write-Output -NoEnumerate $matches[0].Value
}

function Set-WorkflowStateSchemaExactProperty {
    param([object]$Object, [string]$Name, [object]$NewValue)

    # Locate the property by the same ordinal rule used by the evidence oracle;
    # otherwise a mutation control could accidentally alter a differently cased
    # keyword and prove nothing about the committed schema spelling.
    $matches = @()
    if ($Object -is [System.Collections.IDictionary]) {
        foreach ($entry in $Object.GetEnumerator()) {
            if (($entry.Key -is [string]) -and [string]::Equals($entry.Key, $Name, [System.StringComparison]::Ordinal)) {
                $matches += $entry.Key
            }
        }
        if ($matches.Count -ne 1) { throw "Schema property '$Name' must have exactly one ordinal match." }
        $Object[$matches[0]] = $NewValue
        return
    }
    if ($Object -is [pscustomobject]) {
        foreach ($property in $Object.PSObject.Properties) {
            if ([string]::Equals($property.Name, $Name, [System.StringComparison]::Ordinal)) {
                $matches += $property
            }
        }
        if ($matches.Count -ne 1) { throw "Schema property '$Name' must have exactly one ordinal match." }
        $matches[0].Value = $NewValue
        return
    }
    throw "Schema value does not expose property '$Name'."
}

function Rename-WorkflowStateSchemaExactProperty {
    param([object]$Object, [string]$OldName, [string]$NewName)

    # The case-mutation controls must rename the exact source member. PowerShell
    # has case-insensitive member APIs, so use enumerated names before removal.
    $matches = @()
    if ($Object -is [System.Collections.IDictionary]) {
        foreach ($entry in $Object.GetEnumerator()) {
            if (($entry.Key -is [string]) -and [string]::Equals($entry.Key, $OldName, [System.StringComparison]::Ordinal)) {
                $matches += [pscustomobject]@{ Name = $entry.Key; Value = $entry.Value }
            }
        }
        if ($matches.Count -ne 1) { throw "Schema property '$OldName' must have exactly one ordinal match." }
        [void]$Object.Remove($matches[0].Name)
        $Object.Add($NewName, $matches[0].Value)
        return
    }
    if ($Object -is [pscustomobject]) {
        foreach ($property in $Object.PSObject.Properties) {
            if ([string]::Equals($property.Name, $OldName, [System.StringComparison]::Ordinal)) {
                $matches += [pscustomobject]@{ Name = $property.Name; Value = $property.Value }
            }
        }
        if ($matches.Count -ne 1) { throw "Schema property '$OldName' must have exactly one ordinal match." }
        [void]$Object.PSObject.Properties.Remove($matches[0].Name)
        $Object | Add-Member -NotePropertyName $NewName -NotePropertyValue $matches[0].Value
        return
    }
    throw "Schema value does not expose property '$OldName'."
}

function Get-ConditionalCount {
    param([object]$Value)
    $count = 0
    if ($Value -is [System.Collections.IDictionary]) {
        foreach ($entry in $Value.GetEnumerator()) {
            if (($entry.Key -is [string]) -and [string]::Equals($entry.Key, 'if', [System.StringComparison]::Ordinal)) { $count += 1 }
            $count += Get-ConditionalCount -Value $entry.Value
        }
    }
    elseif ($Value -is [pscustomobject]) {
        foreach ($property in $Value.PSObject.Properties) {
            if ([string]::Equals($property.Name, 'if', [System.StringComparison]::Ordinal)) { $count += 1 }
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
    $root_all_of = Get-WorkflowStateSchemaExactProperty -Object $Schema -Name 'allOf'
    $definitions = Get-WorkflowStateSchemaExactProperty -Object $Schema -Name '$defs'
    $repository_definition = Get-WorkflowStateSchemaExactProperty -Object $definitions -Name 'repository'
    $github_definition = Get-WorkflowStateSchemaExactProperty -Object $definitions -Name 'github'
    $query_definition = Get-WorkflowStateSchemaExactProperty -Object $definitions -Name 'query'
    $repository_all_of = Get-WorkflowStateSchemaExactProperty -Object $repository_definition -Name 'allOf'
    $github_all_of = Get-WorkflowStateSchemaExactProperty -Object $github_definition -Name 'allOf'
    $query_all_of = Get-WorkflowStateSchemaExactProperty -Object $query_definition -Name 'allOf'
    Assert-TestTrue -Condition (@($root_all_of).Count -eq 3) -Name 'root owns exactly three result conditionals'
    Assert-TestTrue -Condition (@($repository_all_of).Count -eq 1) -Name 'repository owns exactly one conditional'
    Assert-TestTrue -Condition (@($github_all_of).Count -eq 1) -Name 'GitHub owns exactly one conditional'
    Assert-TestTrue -Condition (@($query_all_of).Count -eq 1) -Name 'query owns exactly one conditional'
    Assert-TestTrue -Condition ((Get-ConditionalCount $Schema) -eq 6) -Name 'schema contains exactly six conditional-policy nodes'

    $pass_policy = $root_all_of[0]
    $pass_if = Get-WorkflowStateSchemaExactProperty -Object $pass_policy -Name 'if'
    $pass_if_properties = Get-WorkflowStateSchemaExactProperty -Object $pass_if -Name 'properties'
    $pass_result = Get-WorkflowStateSchemaExactProperty -Object $pass_if_properties -Name 'result'
    Assert-TestTrue -Condition ((Get-WorkflowStateSchemaExactProperty -Object $pass_result -Name 'const') -ceq 'pass') -Name 'pass predicate requires pass result'
    $pass_then = Get-WorkflowStateSchemaExactProperty -Object $pass_policy -Name 'then'
    $pass_then_properties = Get-WorkflowStateSchemaExactProperty -Object $pass_then -Name 'properties'
    $pass_queries = Get-WorkflowStateSchemaExactProperty -Object $pass_then_properties -Name 'queries'
    $pass_not = Get-WorkflowStateSchemaExactProperty -Object $pass_queries -Name 'not'
    $pass_contains = Get-WorkflowStateSchemaExactProperty -Object $pass_not -Name 'contains'
    $pass_contains_properties = Get-WorkflowStateSchemaExactProperty -Object $pass_contains -Name 'properties'
    $pass_ok = Get-WorkflowStateSchemaExactProperty -Object $pass_contains_properties -Name 'ok'
    $pass_ok_const = Get-WorkflowStateSchemaExactProperty -Object $pass_ok -Name 'const'
    Assert-TestTrue -Condition (($pass_ok_const -is [bool]) -and ($pass_ok_const -eq $false)) -Name 'pass rejects failed queries'
    Assert-ExactStringArray -Actual (Get-WorkflowStateSchemaExactProperty -Object $pass_contains -Name 'required') -Expected @('ok') -Name 'pass failed-query selector required fields'

    $partial_policy = $root_all_of[1]
    $partial_if = Get-WorkflowStateSchemaExactProperty -Object $partial_policy -Name 'if'
    $partial_if_properties = Get-WorkflowStateSchemaExactProperty -Object $partial_if -Name 'properties'
    $partial_result = Get-WorkflowStateSchemaExactProperty -Object $partial_if_properties -Name 'result'
    Assert-TestTrue -Condition ((Get-WorkflowStateSchemaExactProperty -Object $partial_result -Name 'const') -ceq 'partial') -Name 'partial predicate requires partial result'
    $partial_then = Get-WorkflowStateSchemaExactProperty -Object $partial_policy -Name 'then'
    $partial_then_properties = Get-WorkflowStateSchemaExactProperty -Object $partial_then -Name 'properties'
    $partial_queries = Get-WorkflowStateSchemaExactProperty -Object $partial_then_properties -Name 'queries'
    $partial_positive = Get-WorkflowStateSchemaExactProperty -Object $partial_queries -Name 'contains'
    $partial_positive_properties = Get-WorkflowStateSchemaExactProperty -Object $partial_positive -Name 'properties'
    $partial_scope = Get-WorkflowStateSchemaExactProperty -Object $partial_positive_properties -Name 'scope'
    Assert-TestTrue -Condition ((Get-WorkflowStateSchemaExactProperty -Object $partial_scope -Name 'const') -ceq 'github') -Name 'partial requires a failed GitHub query'
    $partial_ok = Get-WorkflowStateSchemaExactProperty -Object $partial_positive_properties -Name 'ok'
    $partial_ok_const = Get-WorkflowStateSchemaExactProperty -Object $partial_ok -Name 'const'
    Assert-TestTrue -Condition (($partial_ok_const -is [bool]) -and ($partial_ok_const -eq $false)) -Name 'partial GitHub query is failed'
    Assert-ExactStringArray -Actual (Get-WorkflowStateSchemaExactProperty -Object $partial_positive -Name 'required') -Expected @('scope', 'ok') -Name 'partial positive selector required fields'
    $partial_queries_all_of = Get-WorkflowStateSchemaExactProperty -Object $partial_queries -Name 'allOf'
    Assert-TestTrue -Condition (@($partial_queries_all_of).Count -eq 1) -Name 'partial owns one non-GitHub exclusion branch'
    $partial_exclusion_not = Get-WorkflowStateSchemaExactProperty -Object $partial_queries_all_of[0] -Name 'not'
    $partial_exclusion = Get-WorkflowStateSchemaExactProperty -Object $partial_exclusion_not -Name 'contains'
    $partial_exclusion_properties = Get-WorkflowStateSchemaExactProperty -Object $partial_exclusion -Name 'properties'
    $partial_exclusion_scope = Get-WorkflowStateSchemaExactProperty -Object $partial_exclusion_properties -Name 'scope'
    $partial_exclusion_scope_not = Get-WorkflowStateSchemaExactProperty -Object $partial_exclusion_scope -Name 'not'
    Assert-TestTrue -Condition ((Get-WorkflowStateSchemaExactProperty -Object $partial_exclusion_scope_not -Name 'const') -ceq 'github') -Name 'partial excludes non-GitHub failed queries'
    $partial_exclusion_ok = Get-WorkflowStateSchemaExactProperty -Object $partial_exclusion_properties -Name 'ok'
    $partial_exclusion_ok_const = Get-WorkflowStateSchemaExactProperty -Object $partial_exclusion_ok -Name 'const'
    Assert-TestTrue -Condition (($partial_exclusion_ok_const -is [bool]) -and ($partial_exclusion_ok_const -eq $false)) -Name 'partial exclusion selects failed queries'
    Assert-ExactStringArray -Actual (Get-WorkflowStateSchemaExactProperty -Object $partial_exclusion -Name 'required') -Expected @('scope', 'ok') -Name 'partial exclusion selector required fields'

    $fail_policy = $root_all_of[2]
    $fail_if = Get-WorkflowStateSchemaExactProperty -Object $fail_policy -Name 'if'
    $fail_if_properties = Get-WorkflowStateSchemaExactProperty -Object $fail_if -Name 'properties'
    $fail_result = Get-WorkflowStateSchemaExactProperty -Object $fail_if_properties -Name 'result'
    Assert-TestTrue -Condition ((Get-WorkflowStateSchemaExactProperty -Object $fail_result -Name 'const') -ceq 'fail') -Name 'fail predicate requires fail result'
    $fail_then = Get-WorkflowStateSchemaExactProperty -Object $fail_policy -Name 'then'
    $fail_then_properties = Get-WorkflowStateSchemaExactProperty -Object $fail_then -Name 'properties'
    $fail_queries = Get-WorkflowStateSchemaExactProperty -Object $fail_then_properties -Name 'queries'
    $fail_query = Get-WorkflowStateSchemaExactProperty -Object $fail_queries -Name 'contains'
    $fail_query_properties = Get-WorkflowStateSchemaExactProperty -Object $fail_query -Name 'properties'
    $fail_scope = Get-WorkflowStateSchemaExactProperty -Object $fail_query_properties -Name 'scope'
    Assert-ExactStringArray -Actual (Get-WorkflowStateSchemaExactProperty -Object $fail_scope -Name 'enum') -Expected @('local', 'invariant', 'schema') -Name 'fail allowed failure scopes'
    $fail_ok = Get-WorkflowStateSchemaExactProperty -Object $fail_query_properties -Name 'ok'
    $fail_ok_const = Get-WorkflowStateSchemaExactProperty -Object $fail_ok -Name 'const'
    Assert-TestTrue -Condition (($fail_ok_const -is [bool]) -and ($fail_ok_const -eq $false)) -Name 'fail consequence requires a failed query'
    Assert-ExactStringArray -Actual (Get-WorkflowStateSchemaExactProperty -Object $fail_query -Name 'required') -Expected @('scope', 'ok') -Name 'fail selector required fields'

    $main_policy = $repository_all_of[0]
    $main_if = Get-WorkflowStateSchemaExactProperty -Object $main_policy -Name 'if'
    $main_if_properties = Get-WorkflowStateSchemaExactProperty -Object $main_if -Name 'properties'
    $main_branch = Get-WorkflowStateSchemaExactProperty -Object $main_if_properties -Name 'branch'
    Assert-TestTrue -Condition ((Get-WorkflowStateSchemaExactProperty -Object $main_branch -Name 'const') -ceq 'main') -Name 'main predicate selects the main branch'
    Assert-ExactStringArray -Actual (Get-WorkflowStateSchemaExactProperty -Object $main_if -Name 'required') -Expected @('branch') -Name 'main predicate required fields'
    $main_then = Get-WorkflowStateSchemaExactProperty -Object $main_policy -Name 'then'
    $main_then_properties = Get-WorkflowStateSchemaExactProperty -Object $main_then -Name 'properties'
    $main_remote_feature_sha = Get-WorkflowStateSchemaExactProperty -Object $main_then_properties -Name 'remote_feature_sha'
    Assert-TestTrue -Condition ((Get-WorkflowStateSchemaExactProperty -Object $main_remote_feature_sha -Name 'type') -ceq 'null') -Name 'main requires a null remote feature SHA'

    $pull_request_policy = $github_all_of[0]
    $pull_request_if = Get-WorkflowStateSchemaExactProperty -Object $pull_request_policy -Name 'if'
    Assert-ExactStringArray -Actual (Get-WorkflowStateSchemaExactProperty -Object $pull_request_if -Name 'required') -Expected @('pull_request') -Name 'pull-request predicate required fields'
    $pull_request_if_properties = Get-WorkflowStateSchemaExactProperty -Object $pull_request_if -Name 'properties'
    $pull_request = Get-WorkflowStateSchemaExactProperty -Object $pull_request_if_properties -Name 'pull_request'
    Assert-TestTrue -Condition ((Get-WorkflowStateSchemaExactProperty -Object $pull_request -Name 'type') -ceq 'null') -Name 'pull-request predicate selects null pull requests'
    $pull_request_then = Get-WorkflowStateSchemaExactProperty -Object $pull_request_policy -Name 'then'
    $pull_request_then_properties = Get-WorkflowStateSchemaExactProperty -Object $pull_request_then -Name 'properties'
    $pull_request_then_count = Get-WorkflowStateSchemaExactProperty -Object $pull_request_then_properties -Name 'matching_pr_count'
    $pull_request_then_count_const = Get-WorkflowStateSchemaExactProperty -Object $pull_request_then_count -Name 'const'
    Assert-TestTrue -Condition (($pull_request_then_count_const -is [System.Int32]) -and ($pull_request_then_count_const -eq 0)) -Name 'null pull requests require count zero'
    $pull_request_else = Get-WorkflowStateSchemaExactProperty -Object $pull_request_policy -Name 'else'
    $pull_request_else_properties = Get-WorkflowStateSchemaExactProperty -Object $pull_request_else -Name 'properties'
    $pull_request_else_count = Get-WorkflowStateSchemaExactProperty -Object $pull_request_else_properties -Name 'matching_pr_count'
    $pull_request_else_count_const = Get-WorkflowStateSchemaExactProperty -Object $pull_request_else_count -Name 'const'
    Assert-TestTrue -Condition (($pull_request_else_count_const -is [System.Int32]) -and ($pull_request_else_count_const -eq 1)) -Name 'identified pull requests require count one'

    $query_policy = $query_all_of[0]
    $query_if = Get-WorkflowStateSchemaExactProperty -Object $query_policy -Name 'if'
    Assert-ExactStringArray -Actual (Get-WorkflowStateSchemaExactProperty -Object $query_if -Name 'required') -Expected @('ok') -Name 'query predicate required fields'
    $query_if_properties = Get-WorkflowStateSchemaExactProperty -Object $query_if -Name 'properties'
    $query_ok = Get-WorkflowStateSchemaExactProperty -Object $query_if_properties -Name 'ok'
    $query_ok_const = Get-WorkflowStateSchemaExactProperty -Object $query_ok -Name 'const'
    Assert-TestTrue -Condition (($query_ok_const -is [bool]) -and ($query_ok_const -eq $true)) -Name 'query predicate selects successful queries'
    $query_then = Get-WorkflowStateSchemaExactProperty -Object $query_policy -Name 'then'
    $query_then_properties = Get-WorkflowStateSchemaExactProperty -Object $query_then -Name 'properties'
    $query_then_error = Get-WorkflowStateSchemaExactProperty -Object $query_then_properties -Name 'error'
    Assert-TestTrue -Condition ((Get-WorkflowStateSchemaExactProperty -Object $query_then_error -Name 'type') -ceq 'null') -Name 'successful queries require null errors'
    $query_else = Get-WorkflowStateSchemaExactProperty -Object $query_policy -Name 'else'
    $query_else_properties = Get-WorkflowStateSchemaExactProperty -Object $query_else -Name 'properties'
    $query_else_error = Get-WorkflowStateSchemaExactProperty -Object $query_else_properties -Name 'error'
    Assert-TestTrue -Condition ((Get-WorkflowStateSchemaExactProperty -Object $query_else_error -Name 'type') -ceq 'string') -Name 'failed queries require string errors'
    Assert-TestTrue -Condition ((Get-WorkflowStateSchemaExactProperty -Object $query_else_error -Name 'minLength') -eq 1) -Name 'failed query errors require content'
    Assert-TestTrue -Condition ((Get-WorkflowStateSchemaExactProperty -Object $query_else_error -Name 'pattern') -ceq '.*\S.*') -Name 'failed query errors require nonwhitespace content'
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

function Test-SchemaKeywordCaseRejects {
    param([string]$Name, [scriptblock]$Action)
    $rejected = $false
    try { & $Action } catch { $rejected = $true }
    if (-not $rejected) { throw "Schema keyword-case mutation was accepted: $Name." }
    $script:schema_keyword_case_mutation_count += 1
}

function Assert-ExactAccessorRejects {
    param([string]$Name, [scriptblock]$Action)
    $rejected = $false
    try { & $Action } catch { $rejected = $true }
    Assert-TestTrue -Condition $rejected -Name $Name
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
    Assert-TestTrue -Condition ((Get-WorkflowStateSchemaExactProperty -Object $schema -Name '$schema') -eq 'https://json-schema.org/draft/2020-12/schema') -Name 'Draft 2020-12 declaration'
    Assert-TestTrue -Condition ((Get-WorkflowStateSchemaExactProperty -Object $schema -Name 'additionalProperties') -eq $false) -Name 'closed root shape'
    $root_required = Get-WorkflowStateSchemaExactProperty -Object $schema -Name 'required'
    Assert-TestTrue -Condition ((@($root_required) -join '|') -eq 'schema_version|tool|generated_at_utc|result|repository|tools|workspace|github|queries') -Name 'root required keys'
    $root_properties = Get-WorkflowStateSchemaExactProperty -Object $schema -Name 'properties'
    $generated_at_utc = Get-WorkflowStateSchemaExactProperty -Object $root_properties -Name 'generated_at_utc'
    Assert-TestTrue -Condition ((Get-WorkflowStateSchemaExactProperty -Object $generated_at_utc -Name 'pattern') -eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{1,7})?Z$') -Name 'canonical timestamp pattern'
    $definitions = Get-WorkflowStateSchemaExactProperty -Object $schema -Name '$defs'
    $query_definition = Get-WorkflowStateSchemaExactProperty -Object $definitions -Name 'query'
    $query_properties = Get-WorkflowStateSchemaExactProperty -Object $query_definition -Name 'properties'
    $exit_code = Get-WorkflowStateSchemaExactProperty -Object $query_properties -Name 'exit_code'
    Assert-TestTrue -Condition (((Get-WorkflowStateSchemaExactProperty -Object $exit_code -Name 'minimum') -eq -2147483648) -and ((Get-WorkflowStateSchemaExactProperty -Object $exit_code -Name 'maximum') -eq 2147483647)) -Name 'signed Int32 query bounds'
    $queries = Get-WorkflowStateSchemaExactProperty -Object $root_properties -Name 'queries'
    Assert-TestTrue -Condition ((Get-WorkflowStateSchemaExactProperty -Object $queries -Name 'minItems') -eq 1) -Name 'queries minimum item count'
    Assert-WorkflowStateSchemaPolicies -Schema $schema
    Test-SchemaPolicyRejects -Name 'pass consequence removed' -Action { $copy = Copy-WorkflowStateSchema $schema; $all_of = Get-WorkflowStateSchemaExactProperty -Object $copy -Name 'allOf'; Set-WorkflowStateSchemaExactProperty -Object $all_of[0] -Name 'then' -NewValue ([pscustomobject]@{}); Assert-WorkflowStateSchemaPolicies -Schema $copy }
    Test-SchemaPolicyRejects -Name 'partial GitHub scope changed' -Action { $copy = Copy-WorkflowStateSchema $schema; $all_of = Get-WorkflowStateSchemaExactProperty -Object $copy -Name 'allOf'; $then = Get-WorkflowStateSchemaExactProperty -Object $all_of[1] -Name 'then'; $properties = Get-WorkflowStateSchemaExactProperty -Object $then -Name 'properties'; $queries = Get-WorkflowStateSchemaExactProperty -Object $properties -Name 'queries'; $contains = Get-WorkflowStateSchemaExactProperty -Object $queries -Name 'contains'; $contains_properties = Get-WorkflowStateSchemaExactProperty -Object $contains -Name 'properties'; $scope = Get-WorkflowStateSchemaExactProperty -Object $contains_properties -Name 'scope'; Set-WorkflowStateSchemaExactProperty -Object $scope -Name 'const' -NewValue 'local'; Assert-WorkflowStateSchemaPolicies -Schema $copy }
    Test-SchemaPolicyRejects -Name 'fail query success changed' -Action { $copy = Copy-WorkflowStateSchema $schema; $all_of = Get-WorkflowStateSchemaExactProperty -Object $copy -Name 'allOf'; $then = Get-WorkflowStateSchemaExactProperty -Object $all_of[2] -Name 'then'; $properties = Get-WorkflowStateSchemaExactProperty -Object $then -Name 'properties'; $queries = Get-WorkflowStateSchemaExactProperty -Object $properties -Name 'queries'; $contains = Get-WorkflowStateSchemaExactProperty -Object $queries -Name 'contains'; $contains_properties = Get-WorkflowStateSchemaExactProperty -Object $contains -Name 'properties'; $ok = Get-WorkflowStateSchemaExactProperty -Object $contains_properties -Name 'ok'; Set-WorkflowStateSchemaExactProperty -Object $ok -Name 'const' -NewValue $true; Assert-WorkflowStateSchemaPolicies -Schema $copy }
    Test-SchemaPolicyRejects -Name 'main remote feature SHA type changed' -Action { $copy = Copy-WorkflowStateSchema $schema; $definitions = Get-WorkflowStateSchemaExactProperty -Object $copy -Name '$defs'; $repository = Get-WorkflowStateSchemaExactProperty -Object $definitions -Name 'repository'; $all_of = Get-WorkflowStateSchemaExactProperty -Object $repository -Name 'allOf'; $then = Get-WorkflowStateSchemaExactProperty -Object $all_of[0] -Name 'then'; $properties = Get-WorkflowStateSchemaExactProperty -Object $then -Name 'properties'; $remote_feature_sha = Get-WorkflowStateSchemaExactProperty -Object $properties -Name 'remote_feature_sha'; Set-WorkflowStateSchemaExactProperty -Object $remote_feature_sha -Name 'type' -NewValue 'string'; Assert-WorkflowStateSchemaPolicies -Schema $copy }
    Test-SchemaPolicyRejects -Name 'null pull-request count changed' -Action { $copy = Copy-WorkflowStateSchema $schema; $definitions = Get-WorkflowStateSchemaExactProperty -Object $copy -Name '$defs'; $github = Get-WorkflowStateSchemaExactProperty -Object $definitions -Name 'github'; $all_of = Get-WorkflowStateSchemaExactProperty -Object $github -Name 'allOf'; $then = Get-WorkflowStateSchemaExactProperty -Object $all_of[0] -Name 'then'; $properties = Get-WorkflowStateSchemaExactProperty -Object $then -Name 'properties'; $matching_pr_count = Get-WorkflowStateSchemaExactProperty -Object $properties -Name 'matching_pr_count'; Set-WorkflowStateSchemaExactProperty -Object $matching_pr_count -Name 'const' -NewValue 1; Assert-WorkflowStateSchemaPolicies -Schema $copy }
    Test-SchemaPolicyRejects -Name 'successful query error type changed' -Action { $copy = Copy-WorkflowStateSchema $schema; $definitions = Get-WorkflowStateSchemaExactProperty -Object $copy -Name '$defs'; $query = Get-WorkflowStateSchemaExactProperty -Object $definitions -Name 'query'; $all_of = Get-WorkflowStateSchemaExactProperty -Object $query -Name 'allOf'; $then = Get-WorkflowStateSchemaExactProperty -Object $all_of[0] -Name 'then'; $properties = Get-WorkflowStateSchemaExactProperty -Object $then -Name 'properties'; $error = Get-WorkflowStateSchemaExactProperty -Object $properties -Name 'error'; Set-WorkflowStateSchemaExactProperty -Object $error -Name 'type' -NewValue 'string'; Assert-WorkflowStateSchemaPolicies -Schema $copy }
    Test-SchemaKeywordCaseRejects -Name 'pass if keyword wrong case' -Action { $copy = Copy-WorkflowStateSchema $schema; $all_of = Get-WorkflowStateSchemaExactProperty -Object $copy -Name 'allOf'; Rename-WorkflowStateSchemaExactProperty -Object $all_of[0] -OldName 'if' -NewName 'IF'; Assert-WorkflowStateSchemaPolicies -Schema $copy }
    Test-SchemaKeywordCaseRejects -Name 'pass then keyword wrong case' -Action { $copy = Copy-WorkflowStateSchema $schema; $all_of = Get-WorkflowStateSchemaExactProperty -Object $copy -Name 'allOf'; Rename-WorkflowStateSchemaExactProperty -Object $all_of[0] -OldName 'then' -NewName 'THEN'; Assert-WorkflowStateSchemaPolicies -Schema $copy }
    Test-SchemaKeywordCaseRejects -Name 'pull-request else keyword wrong case' -Action { $copy = Copy-WorkflowStateSchema $schema; $definitions = Get-WorkflowStateSchemaExactProperty -Object $copy -Name '$defs'; $github = Get-WorkflowStateSchemaExactProperty -Object $definitions -Name 'github'; $all_of = Get-WorkflowStateSchemaExactProperty -Object $github -Name 'allOf'; Rename-WorkflowStateSchemaExactProperty -Object $all_of[0] -OldName 'else' -NewName 'ELSE'; Assert-WorkflowStateSchemaPolicies -Schema $copy }
    Test-SchemaKeywordCaseRejects -Name 'pass result const keyword wrong case' -Action { $copy = Copy-WorkflowStateSchema $schema; $all_of = Get-WorkflowStateSchemaExactProperty -Object $copy -Name 'allOf'; $if = Get-WorkflowStateSchemaExactProperty -Object $all_of[0] -Name 'if'; $properties = Get-WorkflowStateSchemaExactProperty -Object $if -Name 'properties'; $result = Get-WorkflowStateSchemaExactProperty -Object $properties -Name 'result'; Rename-WorkflowStateSchemaExactProperty -Object $result -OldName 'const' -NewName 'CONST'; Assert-WorkflowStateSchemaPolicies -Schema $copy }
    $committed_all_of = Get-WorkflowStateSchemaExactProperty -Object $schema -Name 'allOf'
    $committed_pass_policy = $committed_all_of[0]
    Assert-TestTrue -Condition ((Get-WorkflowStateSchemaExactProperty -Object $committed_pass_policy -Name 'if') -is [pscustomobject]) -Name 'exact pass if lookup succeeds'
    Assert-ExactAccessorRejects -Name 'exact if lookup rejects IF-only spelling' -Action { $copy = Copy-WorkflowStateSchema $schema; $all_of = Get-WorkflowStateSchemaExactProperty -Object $copy -Name 'allOf'; Rename-WorkflowStateSchemaExactProperty -Object $all_of[0] -OldName 'if' -NewName 'IF'; [void](Get-WorkflowStateSchemaExactProperty -Object $all_of[0] -Name 'if') }
    Assert-ExactAccessorRejects -Name 'exact then lookup rejects THEN-only spelling' -Action { $copy = Copy-WorkflowStateSchema $schema; $all_of = Get-WorkflowStateSchemaExactProperty -Object $copy -Name 'allOf'; Rename-WorkflowStateSchemaExactProperty -Object $all_of[0] -OldName 'then' -NewName 'THEN'; [void](Get-WorkflowStateSchemaExactProperty -Object $all_of[0] -Name 'then') }
    Assert-ExactAccessorRejects -Name 'exact defs lookup rejects $DEFS-only spelling' -Action { $copy = Copy-WorkflowStateSchema $schema; Rename-WorkflowStateSchemaExactProperty -Object $copy -OldName '$defs' -NewName '$DEFS'; [void](Get-WorkflowStateSchemaExactProperty -Object $copy -Name '$defs') }
    Assert-TestTrue -Condition ((Get-WorkflowStateSchemaExactProperty -Object $schema -Name 'allOf') -is [System.Array]) -Name 'array-valued allOf remains one array value'
    Assert-TestTrue -Condition (@($committed_all_of).Count -eq 3) -Name 'array-valued allOf retains expected length'
    $pull_request_definition = Get-WorkflowStateSchemaExactProperty -Object $definitions -Name 'pull_request'
    $pull_request_properties = Get-WorkflowStateSchemaExactProperty -Object $pull_request_definition -Name 'properties'
    $pull_request_url = Get-WorkflowStateSchemaExactProperty -Object $pull_request_properties -Name 'url'
    $pull_request_head_sha = Get-WorkflowStateSchemaExactProperty -Object $pull_request_properties -Name 'head_sha'
    $pull_request_number = Get-WorkflowStateSchemaExactProperty -Object $pull_request_properties -Name 'number'
    Assert-TestTrue -Condition (((Get-WorkflowStateSchemaExactProperty -Object $pull_request_url -Name 'type') -eq 'string') -and ((Get-WorkflowStateSchemaExactProperty -Object $pull_request_head_sha -Name '$ref') -eq '#/$defs/sha') -and ((Get-WorkflowStateSchemaExactProperty -Object $pull_request_number -Name 'minimum') -eq 1)) -Name 'identifiable pull-request fields'

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
    Assert-TestTrue -Condition ($script:schema_keyword_case_mutation_count -eq 4) -Name 'exact schema keyword-case mutation rejection count'
    Write-Output 'PASS workflow_state_document_contract valid=3 accepted=5 rejected=57 schema_conditionals=6 schema_policy_mutations=6 schema_keyword_case_mutations=4 primitive_composition=PASS assert_no_output=PASS mutation=PASS'
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
