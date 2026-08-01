param()

$library_path = Join-Path $PSScriptRoot '..\workflow_state_primitives.ps1'

$script:acceptance_count = 0
$script:rejection_count = 0
$script:sensitive_count = 0
$script:bypass_count = 0
$script:purity_acceptance_count = 0
$script:purity_rejection_count = 0

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

function Test-ProductionPuritySource {
    <#
    Parses candidate production source without invoking it. The candidate is
    accepted only when every structural primitive used by the current library
    has an exact, literal policy entry below. This fail-closed oracle is test
    infrastructure: it owns no production behavior and never evaluates the
    candidate source it inspects.
    #>
    param([string]$Source)

    $tokens = $null
    $parse_errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Source, [ref]$tokens, [ref]$parse_errors)
    if ($parse_errors.Count -ne 0) {
        throw 'Purity failed: source contains parser errors.'
    }

    $policy = Get-ProductionPurityPolicy

    # Commands are safe only when they resolve to a function defined by this
    # exact source. This excludes cmdlets, aliases, native commands, dot
    # sourcing, and dynamic invocation without relying on command-name lists.
    $defined_function_names = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $function_definitions = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
    foreach ($definition in $function_definitions) {
        [void]$defined_function_names.Add($definition.Name)
    }

    $commands = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true)
    foreach ($command in $commands) {
        $command_name = $command.GetCommandName()
        if (($null -eq $command_name) -or (-not $defined_function_names.Contains($command_name))) {
            throw "Purity failed: command '$($command.Extent.Text)' is not a locally defined function."
        }
    }

    # Namespace imports change how short type names bind. Rejecting every
    # import keeps later type checks deterministic and makes the policy fail
    # closed if a side-effecting type is imported behind a harmless-looking name.
    $namespace_imports = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.UsingStatementAst] }, $true)
    if ($namespace_imports.Count -ne 0) {
        throw 'Purity failed: using statements are not allowed.'
    }

    $type_definitions = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.TypeDefinitionAst] }, $true)
    if ($type_definitions.Count -ne 0) {
        throw 'Purity failed: type definitions are not allowed.'
    }

    # TypeExpressionAst covers member receivers and TypeConstraintAst covers
    # declarations. Both must match the literal set so an unreviewed type
    # cannot enter through a parameter contract or a static member receiver.
    $type_nodes = $ast.FindAll({
            param($node)
            ($node -is [System.Management.Automation.Language.TypeExpressionAst]) -or
            ($node -is [System.Management.Automation.Language.TypeConstraintAst])
        }, $true)
    foreach ($type_node in $type_nodes) {
        if (-not $policy.TypeNames.Contains($type_node.TypeName.FullName)) {
            throw "Purity failed: type '$($type_node.TypeName.FullName)' is not allowlisted."
        }
    }

    # Variables can name ambient state even when they are not environment-drive
    # variables. The literal local/parameter set therefore rejects all unknown
    # automatic variables and every drive-qualified path before it can be read.
    $variable_nodes = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.VariableExpressionAst] }, $true)
    foreach ($variable_node in $variable_nodes) {
        if ($variable_node.VariablePath.IsDriveQualified) {
            throw "Purity failed: drive-qualified variable '$($variable_node.VariablePath.UserPath)' is not allowed."
        }

        if (-not $policy.VariableNames.Contains($variable_node.VariablePath.UserPath)) {
            throw "Purity failed: variable '$($variable_node.VariablePath.UserPath)' is not allowlisted."
        }
    }

    # File redirection mutates or reads files outside the primitive value contract.
    $redirections = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FileRedirectionAst] }, $true)
    if ($redirections.Count -ne 0) {
        throw 'Purity failed: file redirection is not allowed.'
    }

    # Member names are safe only with their intended static type or exact local
    # receiver expression. A name-only rule would accidentally approve a new
    # side effect such as Path.GetTempFileName or string.Intern.
    $member_nodes = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.MemberExpressionAst] }, $true)
    foreach ($member_node in $member_nodes) {
        $fingerprint = Get-ProductionPurityMemberFingerprint -MemberExpression $member_node
        $allowed_members = if ($member_node -is [System.Management.Automation.Language.InvokeMemberExpressionAst]) {
            $policy.InvocationFingerprints
        }
        else {
            $policy.AccessFingerprints
        }

        if (-not $allowed_members.Contains($fingerprint)) {
            throw "Purity failed: member '$fingerprint' is not allowlisted."
        }
    }
}

function Get-ProductionPurityMemberFingerprint {
    <#
    Produces an ordinal policy key for one member AST. Static members identify
    their declared receiver type; instance members identify their exact local
    expression. Dynamic member names and receiver expressions fail before a
    policy lookup because they cannot be reviewed as stable capabilities.
    #>
    param([System.Management.Automation.Language.MemberExpressionAst]$MemberExpression)

    if ($MemberExpression.Member -isnot [System.Management.Automation.Language.StringConstantExpressionAst]) {
        throw 'Purity failed: dynamically selected member name is not allowed.'
    }

    $operation = if ($MemberExpression -is [System.Management.Automation.Language.InvokeMemberExpressionAst]) {
        'invoke'
    }
    else {
        'access'
    }
    $member_name = $MemberExpression.Member.Value
    $receiver = $MemberExpression.Expression

    if ($receiver -is [System.Management.Automation.Language.TypeExpressionAst]) {
        return ('static|{0}|{1}|{2}' -f $operation, $receiver.TypeName.FullName, $member_name)
    }

    if ($receiver -is [System.Management.Automation.Language.VariableExpressionAst]) {
        return ('instance|{0}|${1}|{2}' -f $operation, $receiver.VariablePath.UserPath, $member_name)
    }

    if ($receiver -is [System.Management.Automation.Language.MemberExpressionAst]) {
        return ('instance|{0}|{1}|{2}' -f $operation, $receiver.Extent.Text, $member_name)
    }

    throw "Purity failed: member receiver '$($receiver.Extent.Text)' is not allowlisted."
}

function Get-ProductionPurityPolicy {
    <#
    Returns the complete, literal policy for the checked-in production library.
    These lists are intentionally written by hand and never learned from the
    candidate source. Reviewers can compare each entry to the production AST.
    #>
    $type_names = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($type_name in @(
            'bool', 'byte', 'DateTime', 'Int16', 'Int32', 'Int64', 'object',
            'pscustomobject', 'ref', 'sbyte', 'string', 'switch', 'System.Array',
            'System.Collections.Generic.HashSet[string]', 'System.Collections.Generic.List[string]',
            'System.Collections.IDictionary', 'System.Globalization.CultureInfo',
            'System.Globalization.DateTimeStyles', 'System.StringComparer',
            'System.StringComparison', 'System.Text.RegularExpressions.Regex',
            'System.Text.RegularExpressions.RegexOptions', 'System.Uri', 'System.UriKind',
            'UInt16', 'UInt32', 'void'
        )) {
        [void]$type_names.Add($type_name)
    }

    $invocation_fingerprints = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($fingerprint in @(
            'static|invoke|DateTime|TryParseExact',
            'static|invoke|string|CompareOrdinal',
            'static|invoke|string|Equals',
            'static|invoke|string|IsNullOrWhiteSpace',
            'static|invoke|System.Collections.Generic.HashSet[string]|new',
            'static|invoke|System.Collections.Generic.List[string]|new',
            'static|invoke|System.Text.RegularExpressions.Regex|IsMatch',
            'static|invoke|System.Uri|TryCreate',
            'instance|invoke|$Value|Contains',
            'instance|invoke|$Value|GetEnumerator',
            'instance|invoke|$Value|GetType',
            'instance|invoke|$Value|IndexOf',
            'instance|invoke|$actual|Add',
            'instance|invoke|$actual|Contains',
            'instance|invoke|$candidate|GetType',
            'instance|invoke|$expected|Add',
            'instance|invoke|$name|GetType',
            'instance|invoke|$names|Add',
            'instance|invoke|$names|ToArray',
            'instance|invoke|$seen|Add'
        )) {
        [void]$invocation_fingerprints.Add($fingerprint)
    }

    $access_fingerprints = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($fingerprint in @(
            'static|access|DateTime|MinValue',
            'static|access|Int64|MaxValue',
            'static|access|Int64|MinValue',
            'static|access|System.Globalization.CultureInfo|InvariantCulture',
            'static|access|System.Globalization.DateTimeStyles|None',
            'static|access|System.StringComparer|Ordinal',
            'static|access|System.StringComparison|Ordinal',
            'static|access|System.StringComparison|OrdinalIgnoreCase',
            'static|access|System.Text.RegularExpressions.RegexOptions|CultureInvariant',
            'static|access|System.Text.RegularExpressions.RegexOptions|IgnoreCase',
            'static|access|System.UriKind|Absolute',
            'instance|access|$Value|Length',
            'instance|access|$Value|PSObject',
            'instance|access|$Value|Rank',
            'instance|access|$Value.PSObject|Properties',
            'instance|access|$Candidates|Length',
            'instance|access|$Candidates|Rank',
            'instance|access|$ExpectedNames|Rank',
            'instance|access|$actual|Count',
            'instance|access|$entry|Key',
            'instance|access|$entry|Value',
            'instance|access|$expected|Count',
            'instance|access|$property|Name',
            'instance|access|$property|Value'
        )) {
        [void]$access_fingerprints.Add($fingerprint)
    }

    $variable_names = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($variable_name in @(
            'accepted', 'actual', 'AllowNull', 'candidate', 'Candidates', 'entry',
            'expected', 'ExpectedNames', 'false', 'format', 'grammar', 'has_previous',
            'integer_value', 'item', 'Literal', 'match_count', 'matched_value', 'Maximum',
            'Minimum', 'name', 'Name', 'names', 'null', 'options', 'parsed', 'prefix', 'previous',
            'property', 'RequireNonEmpty', 'RequireNonWhitespace', 'seen', 'term_options',
            'true', 'type', 'uri', 'Value'
        )) {
        [void]$variable_names.Add($variable_name)
    }

    return [pscustomobject]@{
        TypeNames = $type_names
        InvocationFingerprints = $invocation_fingerprints
        AccessFingerprints = $access_fingerprints
        VariableNames = $variable_names
    }
}

function Test-ProductionPurity {
    <# Reads the checked-in library and delegates all source analysis to the in-memory oracle. #>
    param([string]$LibraryPath)

    $source = [System.IO.File]::ReadAllText($LibraryPath)
    Test-ProductionPuritySource -Source $source
}

function Test-PurityAccepts {
    <# Records a source snippet that the parser-only purity oracle must accept. #>
    param([string]$Name, [scriptblock]$Action)

    try {
        & $Action
    }
    catch {
        throw "Purity acceptance failed: $Name. $($_.Exception.Message)"
    }

    $script:purity_acceptance_count += 1
}

function Test-PurityRejects {
    <# Records a source snippet that must fail parsing policy without being executed. #>
    param([string]$Name, [string]$Source)

    $rejected = $false
    try {
        Test-ProductionPuritySource -Source $Source
    }
    catch {
        $rejected = $true
    }

    if (-not $rejected) {
        throw "Purity rejection failed: $Name."
    }

    $script:purity_rejection_count += 1
}

try {
    # Validate the production source before it can be evaluated. This ordering
    # prevents a future top-level side effect from running when the oracle
    # rejects a new capability.
    Test-PurityAccepts 'actual production primitive library before dot-sourcing' {
        Test-ProductionPurity -LibraryPath $library_path
    }
    . $library_path

    # The policy constructor contains only literal entries. These checks make
    # its intended closed surface and reported counts explicit in the test run.
    $purity_policy = Get-ProductionPurityPolicy
    Assert-TestTrue -Condition ($purity_policy.TypeNames.Count -eq 27) -Name 'literal type allowlist count'
    Assert-TestTrue -Condition ($purity_policy.InvocationFingerprints.Count -eq 20) -Name 'literal invocation allowlist count'
    Assert-TestTrue -Condition ($purity_policy.AccessFingerprints.Count -eq 24) -Name 'literal property allowlist count'
    Assert-TestTrue -Condition ($purity_policy.VariableNames.Count -eq 36) -Name 'literal variable allowlist count'
    Assert-TestTrue -Condition (-not $purity_policy.TypeNames.Contains('System.IO.Path')) -Name 'Path excluded from literal type allowlist'
    Assert-TestTrue -Condition (-not $purity_policy.InvocationFingerprints.Contains('static|invoke|string|Intern')) -Name 'string Intern excluded from literal invocation allowlist'
    Assert-TestTrue -Condition (-not $purity_policy.AccessFingerprints.Contains('static|access|DateTime|Now')) -Name 'DateTime Now excluded from literal property allowlist'
    Assert-TestTrue -Condition (-not $purity_policy.VariableNames.Contains('PWD')) -Name 'PWD excluded from literal variable allowlist'

    $object_value = [pscustomobject]@{
        Alpha = 'value'
        nullable = $null
        empty = @()
        one = @('only')
        many = @('first', 'second')
    }
    $dictionary_value = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
    $dictionary_value.Add('Alpha', 'dictionary value')

    Test-Accepts 'exact PSCustomObject property retrieval' {
        Assert-TestTrue -Condition ((Get-WorkflowStateExactProperty -Value $object_value -Name 'Alpha') -eq 'value') -Name 'PSCustomObject exact property'
        Assert-TestTrue -Condition ((Get-WorkflowStatePropertyNames -Value $object_value) -contains 'Alpha') -Name 'PSCustomObject property names'
        Assert-WorkflowStateExactKeys -Value $object_value -ExpectedNames @('Alpha', 'nullable', 'empty', 'one', 'many')
    }
    Test-Accepts 'exact case-sensitive dictionary property retrieval' {
        Assert-TestTrue -Condition ((Get-WorkflowStateExactProperty -Value $dictionary_value -Name 'Alpha') -eq 'dictionary value') -Name 'dictionary exact property'
        Assert-WorkflowStateExactKeys -Value $dictionary_value -ExpectedNames @('Alpha')
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

    Test-Accepts 'nullable scalar string' { Assert-WorkflowStateScalarString -Value $null -AllowNull }
    Test-Accepts 'nonempty scalar string' { Assert-WorkflowStateScalarString -Value 'valid' -RequireNonEmpty -RequireNonWhitespace }
    Test-Accepts 'exact literal string' { Assert-WorkflowStateLiteralString -Value 'Literal' -Literal 'Literal' }
    foreach ($member in @('Alpha', 'Beta')) {
        Test-Accepts "exact enum member $member" { Assert-WorkflowStateEnumString -Value $member -Candidates @('Alpha', 'Beta') }
    }
    Test-Accepts 'ordinal member rejects non-string by returning false' {
        Assert-TestTrue -Condition (-not (Test-WorkflowStateOrdinalMember -Value @( 'Alpha' ) -Candidates @('Alpha'))) -Name 'ordinal member array false'
    }
    Test-Accepts 'true Boolean' { Assert-WorkflowStateBoolean -Value $true }
    Test-Accepts 'false Boolean' { Assert-WorkflowStateBoolean -Value $false }
    foreach ($integer in @([sbyte]7, [byte]7, [Int16]7, [UInt16]7, [Int32]7, [UInt32]7, [Int64]7)) {
        Test-Accepts "supported integral type $($integer.GetType().Name)" { Assert-WorkflowStateInteger -Value $integer }
    }
    Test-Accepts 'negative native exit value' { Assert-WorkflowStateInteger -Value ([Int32]-1073741819) }
    Test-Accepts 'empty rank-one array' { Assert-WorkflowStateArray -Value @() }
    Test-Accepts 'one-item rank-one array' { Assert-WorkflowStateArray -Value @('item') }
    Test-Accepts 'many-item rank-one array' { Assert-WorkflowStateArray -Value @('first', 'second') }
    Test-Accepts 'absolute HTTPS URI' { Assert-WorkflowStateAbsoluteUri -Value 'https://example.test/path' }
    Test-Accepts 'lowercase SHA' { Assert-WorkflowStateSha -Value '0123456789abcdef0123456789abcdef01234567' }
    Test-Accepts 'nullable SHA' { Assert-WorkflowStateSha -Value $null -AllowNull }
    foreach ($timestamp in @('2024-01-02T03:04:05Z', '2024-01-02T03:04:05.1Z', '2024-01-02T03:04:05.1234567Z', '2024-02-29T03:04:05Z')) {
        Test-Accepts "canonical timestamp $timestamp" { Assert-WorkflowStateCanonicalUtcTimestamp -Value $timestamp }
    }
    Test-Accepts 'unsorted ordinal unique strings' { Assert-WorkflowStateOrdinalUniqueStrings -Value @('Zulu', 'Alpha') }
    Test-Accepts 'case-distinct ordinal unique strings' { Assert-WorkflowStateOrdinalUniqueStrings -Value @('Alpha', 'alpha') }
    Test-Accepts 'correctly sorted ordinal strings' { Assert-WorkflowStateSortedUniqueStrings -Value @('Alpha', 'Zulu', 'alpha') }
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

    # These sources are parsed only. They prove that the test-only purity oracle
    # rejects side effects and accepts the library's narrow, pure .NET surface.
    Test-PurityAccepts 'local function calling local function' {
        Test-ProductionPuritySource -Source "function Invoke-Local { return }`nfunction Invoke-Caller { Invoke-Local }"
    }
    Test-PurityAccepts 'string Equals' { Test-ProductionPuritySource -Source "[string]::Equals('a', 'a')" }
    Test-PurityAccepts 'generic List constructor' { Test-ProductionPuritySource -Source '[System.Collections.Generic.List[string]]::new()' }
    Test-PurityAccepts 'Regex IsMatch' { Test-ProductionPuritySource -Source "[System.Text.RegularExpressions.Regex]::IsMatch('a', 'a')" }
    Test-PurityAccepts 'StringComparer Ordinal property' { Test-ProductionPuritySource -Source '[System.StringComparer]::Ordinal' }
    Test-PurityAccepts 'CultureInfo InvariantCulture property' { Test-ProductionPuritySource -Source '[System.Globalization.CultureInfo]::InvariantCulture' }
    Test-PurityAccepts 'Int64 MinValue property' { Test-ProductionPuritySource -Source '[Int64]::MinValue' }
    Test-PurityAccepts 'DateTime MinValue property' { Test-ProductionPuritySource -Source '[DateTime]::MinValue' }
    Test-PurityAccepts 'UriKind Absolute property' { Test-ProductionPuritySource -Source '[System.UriKind]::Absolute' }

    foreach ($purity_rejection in @(
            @{ Name = 'dynamic command invocation'; Source = '& $cmd' },
            @{ Name = 'literal dynamic git invocation'; Source = "& 'git' status" },
            @{ Name = 'git command'; Source = 'git status' },
            @{ Name = 'gh command'; Source = 'gh api user' },
            @{ Name = 'curl alias'; Source = 'curl https://example.test' },
            @{ Name = 'wget alias'; Source = 'wget https://example.test' },
            @{ Name = 'iwr alias'; Source = 'iwr https://example.test' },
            @{ Name = 'irm alias'; Source = 'irm https://example.test' },
            @{ Name = 'whoami command'; Source = 'whoami' },
            @{ Name = 'Console shorthand'; Source = "[Console]::WriteLine('x')" },
            @{ Name = 'System.Console'; Source = "[System.Console]::WriteLine('x')" },
            @{ Name = 'IO.File shorthand'; Source = "[IO.File]::WriteAllText('x', 'y')" },
            @{ Name = 'System.IO.File'; Source = "[System.IO.File]::ReadAllText('x')" },
            @{ Name = 'Diagnostics.Process shorthand'; Source = "[Diagnostics.Process]::Start('x')" },
            @{ Name = 'System.Diagnostics.Process'; Source = "[System.Diagnostics.Process]::Start('x')" },
            @{ Name = 'Environment shorthand'; Source = "[Environment]::GetEnvironmentVariable('TEMP')" },
            @{ Name = 'Net.WebClient shorthand'; Source = '[Net.WebClient]::new()' },
            @{ Name = 'System.Net.NetworkCredential'; Source = "[System.Net.NetworkCredential]::new('u', 'p')" },
            @{ Name = 'namespace import'; Source = "using namespace System.IO`n[File]::WriteAllText('x', 'y')" },
            @{ Name = 'environment variable read'; Source = '$env:TEMP' },
            @{ Name = 'file redirection'; Source = "'x' > output.txt" },
            @{ Name = 'Write-Information command'; Source = "Write-Information 'x'" },
            @{ Name = 'unknown receiver denied member'; Source = '$value.DownloadString()' },
            @{ Name = 'allowlist self-check unknown type Path temporary-file creation'; Source = '[System.IO.Path]::GetTempFileName()' },
            @{ Name = 'Path temporary-directory lookup'; Source = '[System.IO.Path]::GetTempPath()' },
            @{ Name = 'Path static property'; Source = '[System.IO.Path]::DirectorySeparatorChar' },
            @{ Name = 'Dns host-address lookup'; Source = "[System.Net.Dns]::GetHostAddresses('example.test')" },
            @{ Name = 'Assembly LoadFrom'; Source = "[System.Reflection.Assembly]::LoadFrom('example.dll')" },
            @{ Name = 'allowlist self-check unknown static property DateTime Now'; Source = '[DateTime]::Now' },
            @{ Name = 'DateTime UtcNow'; Source = '[DateTime]::UtcNow' },
            @{ Name = 'CultureInfo CurrentCulture'; Source = '[System.Globalization.CultureInfo]::CurrentCulture' },
            @{ Name = 'StringComparer CurrentCulture'; Source = '[System.StringComparer]::CurrentCulture' },
            @{ Name = 'allowlist self-check unknown static invocation string Intern'; Source = "[string]::Intern('x')" },
            @{ Name = 'PWD ambient variable'; Source = '$PWD' },
            @{ Name = 'HOME ambient variable'; Source = '$HOME' },
            @{ Name = 'PID ambient variable'; Source = '$PID' },
            @{ Name = 'PSVersionTable ambient variable'; Source = '$PSVersionTable' },
            @{ Name = 'ExecutionContext ambient variable'; Source = '$ExecutionContext' },
            @{ Name = 'Path type constraint'; Source = 'param([System.IO.Path]$Value)' },
            @{ Name = 'unapproved member on approved local receiver'; Source = '$Value.ToString()' },
            @{ Name = 'class type definition'; Source = 'class Example {}' },
            @{ Name = 'unknown static property on approved type'; Source = '[DateTime]::Today' },
            @{ Name = 'unknown static invocation on approved type'; Source = "[string]::Concat('x', 'y')" }
        )) {
        Test-PurityRejects -Name $purity_rejection.Name -Source $purity_rejection.Source
    }

    [Console]::WriteLine("PASS workflow_state_primitives acceptance=$script:acceptance_count rejection=$script:rejection_count sensitive=$script:sensitive_count bypass=$script:bypass_count purity_acceptance=$script:purity_acceptance_count purity_rejection=$script:purity_rejection_count allowed_types=$($purity_policy.TypeNames.Count) allowed_invocations=$($purity_policy.InvocationFingerprints.Count) allowed_properties=$($purity_policy.AccessFingerprints.Count) allowed_variables=$($purity_policy.VariableNames.Count) purity=PASS")
    exit 0
}
catch {
    [Console]::Error.WriteLine("FAIL workflow_state_primitives $($_.Exception.Message)")
    exit 1
}
