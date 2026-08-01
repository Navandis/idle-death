param()

$library_path = Join-Path $PSScriptRoot '..\workflow_state_primitives.ps1'

$script:acceptance_count = 0
$script:rejection_count = 0
$script:sensitive_count = 0
$script:bypass_count = 0

function Test-Accepts {
    param([string]$Name, [scriptblock]$Action)

    try {
        & $Action
    }
    catch {
        throw "Acceptance failed: $Name. $($_.Exception.Message)"
    }

    $script:acceptance_count += 1
}

function Test-Rejects {
    param([string]$Name, [scriptblock]$Action, [bool]$IsBypass = $false)

    $rejected = $false
    try {
        & $Action
    }
    catch {
        $rejected = $true
    }

    if (-not $rejected) {
        throw "Rejection failed: $Name."
    }

    $script:rejection_count += 1
    if ($IsBypass) {
        $script:bypass_count += 1
    }
}

function Assert-TestTrue {
    param([bool]$Condition, [string]$Name)

    if (-not $Condition) {
        throw "Assertion failed: $Name."
    }
}

function Test-Sensitive {
    param([string]$Name, [object]$Value, [bool]$Expected)

    Assert-TestTrue -Condition ((Test-WorkflowStateSensitiveError -Value $Value) -eq $Expected) -Name $Name
    $script:sensitive_count += 1
}

function Test-ProductionLoadSafety {
    <#
    Parses production source without executing it and permits only a
    function-library load surface. This is deliberately not a general-purpose
    .NET purity analyzer; source review retains that broader responsibility.
    #>
    param([string]$Source)

    $tokens = $null
    $parse_errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Source, [ref]$tokens, [ref]$parse_errors)
    if ($parse_errors.Count -ne 0) {
        throw 'Load safety failed: source contains parser errors.'
    }

    # Root named blocks execute while the library is dot-sourced. The
    # production library is a function-only surface, so reject every root
    # block other than EndBlock before inspecting its statements.
    foreach ($root_block in @(
            @{ Name = 'parameter block'; Value = $ast.ParamBlock },
            @{ Name = 'dynamicparam block'; Value = $ast.DynamicParamBlock },
            @{ Name = 'begin block'; Value = $ast.BeginBlock },
            @{ Name = 'process block'; Value = $ast.ProcessBlock }
        )) {
        if ($null -ne $root_block.Value) {
            throw "Load safety failed: root $($root_block.Name) is not allowed."
        }
    }

    # Dot-sourcing is the first execution boundary. Only definitions may occur
    # at root scope, so no top-level expression can run during the later load.
    foreach ($statement in $ast.EndBlock.Statements) {
        if ($statement -isnot [System.Management.Automation.Language.FunctionDefinitionAst]) {
            throw "Load safety failed: top-level executable statement '$($statement.Extent.Text)' is not a function definition."
        }
    }

    foreach ($rule in @(
            @{ Name = 'exit statement'; Type = [System.Management.Automation.Language.ExitStatementAst] },
            @{ Name = 'using statement'; Type = [System.Management.Automation.Language.UsingStatementAst] },
            @{ Name = 'type definition'; Type = [System.Management.Automation.Language.TypeDefinitionAst] },
            @{ Name = 'file redirection'; Type = [System.Management.Automation.Language.FileRedirectionAst] }
        )) {
        if ($ast.FindAll({ param($node) $node -is $rule.Type }.GetNewClosure(), $true).Count -ne 0) {
            throw "Load safety failed: $($rule.Name) is not allowed."
        }
    }

    $defined_function_names = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($definition in $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
        [void]$defined_function_names.Add($definition.Name)
    }

    foreach ($command in $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true)) {
        $command_name = $command.GetCommandName()
        if (($command.InvocationOperator -eq [System.Management.Automation.Language.TokenKind]::Dot) -or
            ($null -eq $command_name) -or
            (-not $defined_function_names.Contains($command_name))) {
            throw "Load safety failed: command '$($command.Extent.Text)' is not a direct call to a local function."
        }
    }

    # A member-expression target would mutate caller-owned objects while still
    # looking like an ordinary property access in a parser-only inspection.
    foreach ($assignment in $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.AssignmentStatementAst] }, $true)) {
        if ($assignment.Left.FindAll({ param($node) $node -is [System.Management.Automation.Language.MemberExpressionAst] }, $true).Count -ne 0) {
            throw "Load safety failed: member assignment '$($assignment.Extent.Text)' is not allowed."
        }
    }
}

function Test-LoadSafetyAccepts {
    <# Runs a parser-only positive control without changing behavioral totals. #>
    param([string]$Name, [string]$Source)

    try {
        Test-ProductionLoadSafety -Source $Source
    }
    catch {
        throw "Load-safety acceptance failed: $Name. $($_.Exception.Message)"
    }
}

function Test-LoadSafetyRejects {
    <# Runs a parser-only negative control; Source is never evaluated. #>
    param([string]$Name, [string]$Source)

    $rejected = $false
    try {
        Test-ProductionLoadSafety -Source $Source
    }
    catch {
        $rejected = $true
    }

    if (-not $rejected) {
        throw "Load-safety rejection failed: $Name."
    }
}

function Test-AssertAcceptsNoOutput {
    <#
    Invokes one successful production Assert-* action, requires an empty
    success stream, and records exactly one existing behavioral acceptance.
    Thrown production errors intentionally propagate to fail the test.
    #>
    param([string]$Name, [scriptblock]$Action)

    $output = @(& $Action)
    if ($output.Count -ne 0) {
        throw "Assert no-output failed: $Name emitted $($output.Count) success-stream object(s)."
    }

    $script:acceptance_count += 1
}

function Test-AssertNoOutputRejects {
    <# Proves the test helper detects a synthetic success-stream leak. #>
    param([string]$Name, [scriptblock]$Action)

    $rejected = $false
    try {
        Test-AssertAcceptsNoOutput -Name $Name -Action $Action
    }
    catch {
        $rejected = $true
    }

    if (-not $rejected) {
        throw "Assert no-output negative control failed: $Name."
    }
}

try {
    # Validate the production source before it can be evaluated. This blocks a
    # future load-time statement or command surface before dot-sourcing occurs.
    $production_source = [System.IO.File]::ReadAllText($library_path)
    Test-LoadSafetyAccepts -Name 'actual production primitive library before dot-sourcing' -Source $production_source
    . $library_path

    $object_value = [pscustomobject]@{
        Alpha = 'value'
        nullable = $null
        empty = @()
        one = @('only')
        many = @('first', 'second')
    }
    $dictionary_value = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
    $dictionary_value.Add('Alpha', 'dictionary value')
    $dictionary_value.Add('alpha', 'different dictionary value')

    Test-AssertAcceptsNoOutput 'exact PSCustomObject property retrieval' {
        Assert-TestTrue -Condition ((Get-WorkflowStateExactProperty -Value $object_value -Name 'Alpha') -eq 'value') -Name 'PSCustomObject exact property'
        Assert-TestTrue -Condition ((Get-WorkflowStatePropertyNames -Value $object_value) -contains 'Alpha') -Name 'PSCustomObject property names'
        Assert-WorkflowStateExactKeys -Value $object_value -ExpectedNames @('Alpha', 'nullable', 'empty', 'one', 'many')
        Assert-TestTrue -Condition (($object_value.Alpha -eq 'value') -and ($object_value.many.Length -eq 2) -and ($object_value.many[0] -eq 'first') -and ($object_value.many[1] -eq 'second')) -Name 'PSCustomObject and nested array remain unchanged'
    }
    Test-Accepts 'exact case-sensitive dictionary property retrieval' {
        Assert-TestTrue -Condition ((Get-WorkflowStateExactProperty -Value $dictionary_value -Name 'Alpha') -eq 'dictionary value') -Name 'dictionary exact property'
        Assert-TestTrue -Condition ((Get-WorkflowStateExactProperty -Value $dictionary_value -Name 'alpha') -eq 'different dictionary value') -Name 'dictionary lower-case exact property'
        Assert-WorkflowStateExactKeys -Value $dictionary_value -ExpectedNames @('Alpha', 'alpha')
        Assert-TestTrue -Condition (($dictionary_value['Alpha'] -eq 'dictionary value') -and ($dictionary_value['alpha'] -eq 'different dictionary value')) -Name 'case-sensitive dictionary remains unchanged'
    }
    Test-Accepts 'present null property' {
        Assert-TestTrue -Condition ($null -eq (Get-WorkflowStateExactProperty -Value $object_value -Name 'nullable')) -Name 'present null'
    }
    Test-Accepts 'empty array property remains array' {
        $value = Get-WorkflowStateExactProperty -Value $object_value -Name 'empty'
        Assert-TestTrue -Condition (($value -is [array]) -and ($value.Length -eq 0)) -Name 'empty array preservation'
    }
    Test-Accepts 'one-item array property remains array' {
        $value = Get-WorkflowStateExactProperty -Value $object_value -Name 'one'
        Assert-TestTrue -Condition (($value -is [array]) -and ($value.Length -eq 1) -and ($value[0] -eq 'only')) -Name 'one-item array preservation'
    }
    Test-Accepts 'many-item array property remains array' {
        $value = Get-WorkflowStateExactProperty -Value $object_value -Name 'many'
        Assert-TestTrue -Condition (($value -is [array]) -and ($value.Length -eq 2)) -Name 'many-item array preservation'
    }

    Test-AssertAcceptsNoOutput 'nullable scalar string' { Assert-WorkflowStateScalarString -Value $null -AllowNull }
    Test-Accepts 'nonempty scalar string' { Assert-WorkflowStateScalarString -Value 'valid' -RequireNonEmpty -RequireNonWhitespace }
    Test-AssertAcceptsNoOutput 'exact literal string' { Assert-WorkflowStateLiteralString -Value 'Literal' -Literal 'Literal' }
    foreach ($member in @('Alpha', 'Beta')) {
        if ($member -eq 'Alpha') {
            Test-AssertAcceptsNoOutput "exact enum member $member" { Assert-WorkflowStateEnumString -Value $member -Candidates @('Alpha', 'Beta') }
        }
        else {
            Test-Accepts "exact enum member $member" { Assert-WorkflowStateEnumString -Value $member -Candidates @('Alpha', 'Beta') }
        }
    }
    Test-Accepts 'ordinal member rejects non-string by returning false' {
        Assert-TestTrue -Condition (-not (Test-WorkflowStateOrdinalMember -Value @( 'Alpha' ) -Candidates @('Alpha'))) -Name 'ordinal member array false'
    }
    Test-AssertAcceptsNoOutput 'true Boolean' { Assert-WorkflowStateBoolean -Value $true }
    Test-Accepts 'false Boolean' { Assert-WorkflowStateBoolean -Value $false }
    foreach ($integer in @([sbyte]7, [byte]7, [Int16]7, [UInt16]7, [Int32]7, [UInt32]7, [Int64]7)) {
        if ($integer -is [sbyte]) {
            Test-AssertAcceptsNoOutput "supported integral type $($integer.GetType().Name)" { Assert-WorkflowStateInteger -Value $integer }
        }
        else {
            Test-Accepts "supported integral type $($integer.GetType().Name)" { Assert-WorkflowStateInteger -Value $integer }
        }
    }
    Test-Accepts 'negative native exit value' { Assert-WorkflowStateInteger -Value ([Int32]-1073741819) }
    Test-AssertAcceptsNoOutput 'empty rank-one array' { Assert-WorkflowStateArray -Value @() }
    Test-Accepts 'one-item rank-one array' { Assert-WorkflowStateArray -Value @('item') }
    Test-Accepts 'many-item rank-one array' { Assert-WorkflowStateArray -Value @('first', 'second') }
    Test-AssertAcceptsNoOutput 'absolute HTTPS URI' { Assert-WorkflowStateAbsoluteUri -Value 'https://example.test/path' }
    Test-AssertAcceptsNoOutput 'lowercase SHA' { Assert-WorkflowStateSha -Value '0123456789abcdef0123456789abcdef01234567' }
    Test-Accepts 'nullable SHA' { Assert-WorkflowStateSha -Value $null -AllowNull }
    foreach ($timestamp in @('2024-01-02T03:04:05Z', '2024-01-02T03:04:05.1Z', '2024-01-02T03:04:05.1234567Z', '2024-02-29T03:04:05Z')) {
        if ($timestamp -eq '2024-01-02T03:04:05Z') {
            Test-AssertAcceptsNoOutput "canonical timestamp $timestamp" { Assert-WorkflowStateCanonicalUtcTimestamp -Value $timestamp }
        }
        else {
            Test-Accepts "canonical timestamp $timestamp" { Assert-WorkflowStateCanonicalUtcTimestamp -Value $timestamp }
        }
    }
    Test-AssertAcceptsNoOutput 'unsorted ordinal unique strings' {
        $caller_value = @('Zulu', 'Alpha')
        Assert-WorkflowStateOrdinalUniqueStrings -Value $caller_value
        Assert-TestTrue -Condition (($caller_value.Length -eq 2) -and ($caller_value[0] -eq 'Zulu') -and ($caller_value[1] -eq 'Alpha')) -Name 'ordinal-unique input remains unchanged'
    }
    Test-Accepts 'case-distinct ordinal unique strings' { Assert-WorkflowStateOrdinalUniqueStrings -Value @('Alpha', 'alpha') }
    Test-AssertAcceptsNoOutput 'correctly sorted ordinal strings' {
        $caller_value = @('Alpha', 'Zulu', 'alpha')
        Assert-WorkflowStateSortedUniqueStrings -Value $caller_value
        Assert-TestTrue -Condition (($caller_value.Length -eq 3) -and ($caller_value[0] -eq 'Alpha') -and ($caller_value[1] -eq 'Zulu') -and ($caller_value[2] -eq 'alpha')) -Name 'sorted-unique input remains unchanged'
    }
    Test-Sensitive -Name 'ordinary diagnostic is not sensitive' -Value 'offline query returned no workflow records' -Expected $false
    Test-Sensitive -Name 'null diagnostic is not sensitive' -Value $null -Expected $false

    Test-Rejects 'non-object exact keys' { Assert-WorkflowStateExactKeys -Value 'not an object' -ExpectedNames @('Alpha') }
    Test-Rejects 'missing exact key' { Assert-WorkflowStateExactKeys -Value ([pscustomobject]@{ Alpha = 'x' }) -ExpectedNames @('Alpha', 'Beta') }
    Test-Rejects 'extra exact key' { Assert-WorkflowStateExactKeys -Value ([pscustomobject]@{ Alpha = 'x'; Beta = 'y' }) -ExpectedNames @('Alpha') }
    Test-Rejects 'wrong-case root key' { Assert-WorkflowStateExactKeys -Value ([pscustomobject]@{ alpha = 'x' }) -ExpectedNames @('Alpha') }
    Test-Rejects 'case-sensitive dictionary expected plus wrong-case key' {
        $dictionary = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
        $dictionary.Add('Alpha', 'x')
        $dictionary.Add('alpha', 'y')
        Assert-WorkflowStateExactKeys -Value $dictionary -ExpectedNames @('Alpha')
    }
    Test-Rejects 'wrong-case exact property' { Get-WorkflowStateExactProperty -Value $object_value -Name 'alpha' }
    Test-Rejects 'missing exact property' { Get-WorkflowStateExactProperty -Value $object_value -Name 'Missing' }
    Test-Rejects 'one-item array scalar string' { Assert-WorkflowStateScalarString -Value @('text') }
    Test-Rejects 'multi-item array scalar string' { Assert-WorkflowStateScalarString -Value @('text', 'more') }
    Test-Rejects 'null nonnullable string' { Assert-WorkflowStateScalarString -Value $null }
    Test-Rejects 'whitespace nonempty string' { Assert-WorkflowStateScalarString -Value ' ' -RequireNonWhitespace }
    Test-Rejects 'wrong-case literal' { Assert-WorkflowStateLiteralString -Value 'literal' -Literal 'Literal' }
    Test-Rejects 'array literal bypass' { Assert-WorkflowStateLiteralString -Value @('Literal') -Literal 'Literal' } $true
    Test-Rejects 'wrong-case enum' { Assert-WorkflowStateEnumString -Value 'alpha' -Candidates @('Alpha') }
    Test-Rejects 'array enum bypass' { Assert-WorkflowStateEnumString -Value @('Alpha') -Candidates @('Alpha') } $true
    Test-Rejects 'integer is not string' { Assert-WorkflowStateScalarString -Value 1 }
    Test-Rejects 'Boolean is not string' { Assert-WorkflowStateScalarString -Value $true }
    Test-Rejects 'character is not string' { Assert-WorkflowStateScalarString -Value ([char]'x') }
    Test-Rejects 'StringBuilder is not string' { Assert-WorkflowStateScalarString -Value ([System.Text.StringBuilder]::new('text')) }
    Test-Rejects 'zero is not Boolean' { Assert-WorkflowStateBoolean -Value 0 }
    Test-Rejects 'one is not Boolean' { Assert-WorkflowStateBoolean -Value 1 }
    Test-Rejects 'Boolean string is not Boolean' { Assert-WorkflowStateBoolean -Value 'true' }
    Test-Rejects 'Double is not integer' { Assert-WorkflowStateInteger -Value ([double]1) }
    Test-Rejects 'Decimal is not integer' { Assert-WorkflowStateInteger -Value ([decimal]1) }
    Test-Rejects 'Boolean is not integer' { Assert-WorkflowStateInteger -Value $true }
    Test-Rejects 'numeric string is not integer' { Assert-WorkflowStateInteger -Value '1' }
    Test-Rejects 'UInt64 is not integer' { Assert-WorkflowStateInteger -Value ([UInt64]1) }
    Test-Rejects 'array is not integer' { Assert-WorkflowStateInteger -Value @(1) }
    Test-Rejects 'integer below minimum' { Assert-WorkflowStateInteger -Value 1 -Minimum 2 -Maximum 3 }
    Test-Rejects 'integer above maximum' { Assert-WorkflowStateInteger -Value 4 -Minimum 2 -Maximum 3 }
    Test-Rejects 'integer minimum exceeds maximum' { Assert-WorkflowStateInteger -Value 2 -Minimum 3 -Maximum 2 }
    $array_list = [System.Collections.ArrayList]::new()
    [void]$array_list.Add('item')
    $two_dimensional = [System.Array]::CreateInstance([int], 2, 2)
    Test-Rejects 'scalar is not array' { Assert-WorkflowStateArray -Value 1 }
    Test-Rejects 'string is not array' { Assert-WorkflowStateArray -Value 'item' }
    Test-Rejects 'ArrayList is not array' { Assert-WorkflowStateArray -Value $array_list }
    Test-Rejects 'multidimensional array is not array' { Assert-WorkflowStateArray -Value $two_dimensional }
    Test-Rejects 'relative URI' { Assert-WorkflowStateAbsoluteUri -Value '/relative/path' }
    Test-Rejects 'malformed URI' { Assert-WorkflowStateAbsoluteUri -Value 'http://[bad' }
    Test-Rejects 'whitespace URI' { Assert-WorkflowStateAbsoluteUri -Value 'https://example.test/a path' }
    Test-Rejects 'array URI bypass' { Assert-WorkflowStateAbsoluteUri -Value @('https://example.test') } $true
    Test-Rejects 'uppercase SHA' { Assert-WorkflowStateSha -Value '0123456789ABCDEF0123456789abcdef01234567' }
    Test-Rejects 'short SHA' { Assert-WorkflowStateSha -Value '0123456789abcdef0123456789abcdef0123456' }
    Test-Rejects 'nonhex SHA' { Assert-WorkflowStateSha -Value 'g123456789abcdef0123456789abcdef01234567' }
    Test-Rejects 'whitespace SHA' { Assert-WorkflowStateSha -Value '0123456789abcdef0123456789abcdef0123456 ' }
    Test-Rejects 'array SHA bypass' { Assert-WorkflowStateSha -Value @('0123456789abcdef0123456789abcdef01234567') } $true
    Test-Rejects 'timestamp space' { Assert-WorkflowStateCanonicalUtcTimestamp -Value '2024-01-02 03:04:05Z' }
    Test-Rejects 'timestamp offset' { Assert-WorkflowStateCanonicalUtcTimestamp -Value '2024-01-02T03:04:05+00:00' }
    Test-Rejects 'timestamp lowercase t' { Assert-WorkflowStateCanonicalUtcTimestamp -Value '2024-01-02t03:04:05Z' }
    Test-Rejects 'timestamp lowercase z' { Assert-WorkflowStateCanonicalUtcTimestamp -Value '2024-01-02T03:04:05z' }
    Test-Rejects 'timestamp missing seconds' { Assert-WorkflowStateCanonicalUtcTimestamp -Value '2024-01-02T03:04Z' }
    Test-Rejects 'timestamp eighth fractional digit' { Assert-WorkflowStateCanonicalUtcTimestamp -Value '2024-01-02T03:04:05.12345678Z' }
    Test-Rejects 'timestamp invalid leap day' { Assert-WorkflowStateCanonicalUtcTimestamp -Value '2023-02-29T03:04:05Z' }
    Test-Rejects 'timestamp hour 24' { Assert-WorkflowStateCanonicalUtcTimestamp -Value '2024-01-02T24:04:05Z' }
    Test-Rejects 'timestamp minute 60' { Assert-WorkflowStateCanonicalUtcTimestamp -Value '2024-01-02T03:60:05Z' }
    Test-Rejects 'timestamp invalid seconds' { Assert-WorkflowStateCanonicalUtcTimestamp -Value '2024-01-02T03:04:60Z' }
    Test-Rejects 'array timestamp bypass' { Assert-WorkflowStateCanonicalUtcTimestamp -Value @('2024-01-02T03:04:05Z') } $true
    Test-Rejects 'ordinal exact duplicate' { Assert-WorkflowStateOrdinalUniqueStrings -Value @('Alpha', 'Alpha') }
    Test-Rejects 'ordinal unique nonstring item' { Assert-WorkflowStateOrdinalUniqueStrings -Value @('Alpha', 1) }
    Test-Rejects 'sorted duplicate' { Assert-WorkflowStateSortedUniqueStrings -Value @('Alpha', 'Alpha') }
    Test-Rejects 'sorted unsorted input' { Assert-WorkflowStateSortedUniqueStrings -Value @('Zulu', 'Alpha') }
    Test-Rejects 'sorted nonstring item' { Assert-WorkflowStateSortedUniqueStrings -Value @('Alpha', 1) }
    Test-Rejects 'nonstring sensitive input' { Test-WorkflowStateSensitiveError -Value 1 }

    foreach ($prefix in @('ghp_', 'gho_', 'ghu_', 'ghs_', 'ghr_', 'github_pat_')) {
        Test-Sensitive -Name "$prefix embedded" -Value "diagnostic $prefix sample" -Expected $true
        Test-Sensitive -Name "$prefix case variant" -Value "diagnostic $($prefix.ToUpperInvariant()) sample" -Expected $true
        Test-Sensitive -Name "$prefix URL user-info" -Value "https://$prefix sample@example.test/path" -Expected $true
    }
    Test-Sensitive -Name 'Authorization header' -Value 'Authorization: value' -Expected $true
    Test-Sensitive -Name 'Bearer text' -Value 'Bearer value' -Expected $true
    Test-Sensitive -Name 'standalone token text' -Value 'token value' -Expected $true
    Test-Sensitive -Name 'hosts.yml indicator' -Value 'hosts.yml could not be read' -Expected $true

    # Synthetic controls are parsed only. They specifically protect the
    # dot-source boundary and avoid claiming to analyze arbitrary .NET members.
    Test-LoadSafetyAccepts -Name 'local function calling local function' -Source "function Invoke-Local { return }`nfunction Invoke-Caller { Invoke-Local }"
    Test-LoadSafetyAccepts -Name 'ordinary local-variable assignment' -Source 'function Set-Local { $value = $null }'
    Test-LoadSafetyAccepts -Name 'function-local parameter block' -Source 'function Invoke-Local { param([string]$Value) return }'
    foreach ($load_safety_rejection in @(
            @{ Name = 'empty root parameter block'; Source = "param()`nfunction Invoke-Local { return }" },
            @{ Name = 'root parameter executable default'; Source = "param(`$x = [Console]::WriteLine('load-time output'))`nfunction Invoke-Local { return }" },
            @{ Name = 'root dynamicparam block'; Source = "dynamicparam { 1 }`nend { function Invoke-Local { return } }" },
            @{ Name = 'root begin block'; Source = "begin { `$null = `$null }`nend { function Invoke-Local { return } }" },
            @{ Name = 'root process block'; Source = "process { `$null = `$null }`nend { function Invoke-Local { return } }" },
            @{ Name = 'top-level exit'; Source = 'exit 0' },
            @{ Name = 'exit inside function'; Source = 'function Stop-Local { exit 0 }' },
            @{ Name = 'member assignment'; Source = 'function Set-Property { $property.Value = $null }' },
            @{ Name = 'external command'; Source = 'function Invoke-External { Get-ChildItem }' },
            @{ Name = 'dynamically selected command'; Source = 'function Invoke-Dynamic { & $command }' },
            @{ Name = 'dot sourcing'; Source = 'function Import-Other { . ./other.ps1 }' },
            @{ Name = 'top-level expression'; Source = '$value = $null' },
            @{ Name = 'namespace import'; Source = "using namespace System.IO`nfunction Invoke-Local { return }" },
            @{ Name = 'type definition'; Source = 'class Example {}' },
            @{ Name = 'file redirection'; Source = "function Write-File { 'x' > output.txt }" }
        )) {
        Test-LoadSafetyRejects -Name $load_safety_rejection.Name -Source $load_safety_rejection.Source
    }

    Test-AssertNoOutputRejects -Name 'synthetic success-stream leak' -Action { [pscustomobject]@{ leaked = $true } }

    Assert-TestTrue -Condition ($script:acceptance_count -eq 35) -Name 'acceptance count'
    Assert-TestTrue -Condition ($script:rejection_count -eq 61) -Name 'rejection count'
    Assert-TestTrue -Condition ($script:sensitive_count -eq 24) -Name 'sensitive count'
    Assert-TestTrue -Condition ($script:bypass_count -eq 5) -Name 'bypass count'

    [Console]::WriteLine("PASS workflow_state_primitives acceptance=$script:acceptance_count rejection=$script:rejection_count sensitive=$script:sensitive_count bypass=$script:bypass_count load_safety=PASS assert_no_output=PASS mutation=PASS")
    exit 0
}
catch {
    [Console]::Error.WriteLine("FAIL workflow_state_primitives $($_.Exception.Message)")
    exit 1
}
