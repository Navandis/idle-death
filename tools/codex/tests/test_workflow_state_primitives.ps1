param()

$library_path = Join-Path $PSScriptRoot '..\workflow_state_primitives.ps1'
. $library_path

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

function Test-ProductionPurity {
    param([string]$LibraryPath)

    $tokens = $null
    $parse_errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($LibraryPath, [ref]$tokens, [ref]$parse_errors)
    Assert-TestTrue -Condition ($parse_errors.Count -eq 0) -Name 'library parser validation'

    $forbidden_commands = @(
        'git', 'gh', 'Start-Process', 'Invoke-Expression', 'Invoke-WebRequest',
        'Invoke-RestMethod', 'Write-Host', 'Write-Output', 'Write-Error', 'Write-Warning'
    )
    $commands = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true)
    foreach ($command in $commands) {
        $command_name = $command.GetCommandName()
        if (($null -ne $command_name) -and ($forbidden_commands -contains $command_name)) {
            throw "Purity failed: forbidden command '$command_name'."
        }
    }

    $source = [System.IO.File]::ReadAllText($LibraryPath)
    $forbidden_patterns = @(
        '(?im)\$env:[A-Za-z_][A-Za-z0-9_]*\s*=',
        '(?im)\[System\.IO\.(File|Directory|FileInfo|DirectoryInfo)\]',
        '(?im)\[System\.Console\]'
    )
    foreach ($pattern in $forbidden_patterns) {
        if ([System.Text.RegularExpressions.Regex]::IsMatch($source, $pattern)) {
            throw 'Purity failed: forbidden direct side-effect pattern.'
        }
    }
}

try {
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

    Test-ProductionPurity -LibraryPath $library_path
    [Console]::WriteLine("PASS workflow_state_primitives acceptance=$script:acceptance_count rejection=$script:rejection_count sensitive=$script:sensitive_count bypass=$script:bypass_count purity=PASS")
    exit 0
}
catch {
    [Console]::Error.WriteLine("FAIL workflow_state_primitives $($_.Exception.Message)")
    exit 1
}
