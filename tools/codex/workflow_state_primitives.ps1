<#
Workflow-state structural primitive library.

This library owns only reusable, side-effect-free runtime checks for values that
may later appear in a workflow-state document. It does not own a document
contract, collection, serialization, process execution, or mutation. Candidate
values deliberately use [object] parameters so PowerShell cannot coerce a
one-item array into a scalar before the primitive inspects its runtime type.
#>

function Get-WorkflowStatePropertyNames {
    <# Returns the original-cased names from a PSCustomObject or IDictionary. #>
    param(
        [object]$Value
    )

    $names = [System.Collections.Generic.List[string]]::new()

    if ($Value -is [pscustomobject]) {
        foreach ($property in $Value.PSObject.Properties) {
            [void]$names.Add($property.Name)
        }
    }
    elseif ($Value -is [System.Collections.IDictionary]) {
        foreach ($entry in $Value.GetEnumerator()) {
            if ($entry.Key -isnot [string]) {
                throw 'Workflow-state dictionary keys must be strings.'
            }

            [void]$names.Add($entry.Key)
        }
    }
    else {
        throw 'Workflow-state properties require a PSCustomObject or IDictionary.'
    }

    return ,($names.ToArray())
}

function Get-WorkflowStateExactProperty {
    <#
    Gets exactly one ordinally named property. The unary comma preserves an
    array-valued property as one returned object, including empty arrays.
    #>
    param(
        [object]$Value,
        [string]$Name
    )

    $match_count = 0
    $matched_value = $null

    if ($Value -is [pscustomobject]) {
        foreach ($property in $Value.PSObject.Properties) {
            if ([string]::Equals($property.Name, $Name, [System.StringComparison]::Ordinal)) {
                $match_count += 1
                $matched_value = $property.Value
            }
        }
    }
    elseif ($Value -is [System.Collections.IDictionary]) {
        foreach ($entry in $Value.GetEnumerator()) {
            if ($entry.Key -isnot [string]) {
                throw 'Workflow-state dictionary keys must be strings.'
            }

            if ([string]::Equals($entry.Key, $Name, [System.StringComparison]::Ordinal)) {
                $match_count += 1
                $matched_value = $entry.Value
            }
        }
    }
    else {
        throw 'Workflow-state properties require a PSCustomObject or IDictionary.'
    }

    if ($match_count -eq 0) {
        throw "Workflow-state property '$Name' is missing."
    }

    if ($match_count -ne 1) {
        throw "Workflow-state property '$Name' is ambiguous."
    }

    return ,$matched_value
}

function Test-WorkflowStateOrdinalMember {
    <# Returns true only when Value is an actual scalar string in Candidates. #>
    param(
        [object]$Value,
        [object]$Candidates
    )

    if (($null -eq $Value) -or ($Value.GetType() -ne [string])) {
        return $false
    }

    if (($Candidates -isnot [System.Array]) -or ($Candidates.Rank -ne 1)) {
        throw 'Workflow-state enum candidates must be a rank-one array.'
    }

    foreach ($candidate in $Candidates) {
        if (($candidate -isnot [string]) -or ($candidate.GetType() -ne [string])) {
            throw 'Workflow-state enum candidates must be scalar strings.'
        }

        if ([string]::Equals($Value, $candidate, [System.StringComparison]::Ordinal)) {
            return $true
        }
    }

    return $false
}

function Assert-WorkflowStateExactKeys {
    <# Requires an exact ordinal, case-sensitive match between actual and expected names. #>
    param(
        [object]$Value,
        [object]$ExpectedNames
    )

    if (($ExpectedNames -isnot [System.Array]) -or ($ExpectedNames.Rank -ne 1)) {
        throw 'Workflow-state expected keys must be a rank-one array.'
    }

    $expected = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($name in $ExpectedNames) {
        if (($name -isnot [string]) -or ($name.GetType() -ne [string])) {
            throw 'Workflow-state expected keys must be scalar strings.'
        }

        if (-not $expected.Add($name)) {
            throw "Workflow-state expected key '$name' is repeated."
        }
    }

    $actual = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($name in (Get-WorkflowStatePropertyNames -Value $Value)) {
        if (-not $actual.Add($name)) {
            throw "Workflow-state key '$name' is repeated."
        }
    }

    if ($actual.Count -ne $expected.Count) {
        throw 'Workflow-state keys do not match the expected set.'
    }

    foreach ($name in $expected) {
        if (-not $actual.Contains($name)) {
            throw "Workflow-state key '$name' is missing or has different casing."
        }
    }
}

function Assert-WorkflowStateScalarString {
    <# Requires an actual System.String without converting another runtime value. #>
    param(
        [object]$Value,
        [switch]$AllowNull,
        [switch]$RequireNonEmpty,
        [switch]$RequireNonWhitespace
    )

    if ($null -eq $Value) {
        if ($AllowNull) {
            return
        }

        throw 'Workflow-state string value cannot be null.'
    }

    if ($Value.GetType() -ne [string]) {
        throw 'Workflow-state value must be an actual scalar string.'
    }

    if ($RequireNonEmpty -and ($Value.Length -eq 0)) {
        throw 'Workflow-state string value cannot be empty.'
    }

    if ($RequireNonWhitespace -and [string]::IsNullOrWhiteSpace($Value)) {
        throw 'Workflow-state string value cannot be whitespace.'
    }
}

function Assert-WorkflowStateLiteralString {
    <# Requires one scalar string equal to Literal using ordinal comparison. #>
    param(
        [object]$Value,
        [string]$Literal
    )

    Assert-WorkflowStateScalarString -Value $Value
    if (-not [string]::Equals($Value, $Literal, [System.StringComparison]::Ordinal)) {
        throw "Workflow-state string must equal '$Literal'."
    }
}

function Assert-WorkflowStateEnumString {
    <# Requires one scalar string from a nonempty ordinal candidate array. #>
    param(
        [object]$Value,
        [object]$Candidates
    )

    Assert-WorkflowStateScalarString -Value $Value

    if (($Candidates -isnot [System.Array]) -or ($Candidates.Rank -ne 1) -or ($Candidates.Length -eq 0)) {
        throw 'Workflow-state enum candidates must be a nonempty rank-one array.'
    }

    if (-not (Test-WorkflowStateOrdinalMember -Value $Value -Candidates $Candidates)) {
        throw 'Workflow-state string is not an allowed enum member.'
    }
}

function Assert-WorkflowStateBoolean {
    <# Requires an actual System.Boolean and rejects string or numeric lookalikes. #>
    param(
        [object]$Value
    )

    if (($null -eq $Value) -or ($Value.GetType() -ne [bool])) {
        throw 'Workflow-state value must be an actual Boolean.'
    }
}

function Assert-WorkflowStateInteger {
    <#
    Requires one signed-Int64-representable integral CLR value. Bounds use
    signed Int64 values so negative native exit codes remain valid values.
    #>
    param(
        [object]$Value,
        [switch]$AllowNull,
        [Int64]$Minimum = [Int64]::MinValue,
        [Int64]$Maximum = [Int64]::MaxValue
    )

    if ($Minimum -gt $Maximum) {
        throw 'Workflow-state integer minimum cannot exceed maximum.'
    }

    if ($null -eq $Value) {
        if ($AllowNull) {
            return
        }

        throw 'Workflow-state integer value cannot be null.'
    }

    $type = $Value.GetType()
    $accepted = ($type -eq [sbyte]) -or ($type -eq [byte]) -or ($type -eq [Int16]) -or `
        ($type -eq [UInt16]) -or ($type -eq [Int32]) -or ($type -eq [UInt32]) -or ($type -eq [Int64])
    if (-not $accepted) {
        throw 'Workflow-state value must be a signed-Int64-representable integral CLR value.'
    }

    $integer_value = [Int64]$Value
    if (($integer_value -lt $Minimum) -or ($integer_value -gt $Maximum)) {
        throw 'Workflow-state integer value is outside the allowed inclusive bounds.'
    }
}

function Assert-WorkflowStateArray {
    <# Requires a one-dimensional CLR array without enumerating or converting it. #>
    param(
        [object]$Value
    )

    if (($Value -isnot [System.Array]) -or ($Value.Rank -ne 1)) {
        throw 'Workflow-state value must be a rank-one System.Array.'
    }
}

function Assert-WorkflowStateAbsoluteUri {
    <# Requires a scalar absolute URI; scheme and host policy belong to a later contract. #>
    param(
        [object]$Value,
        [switch]$AllowNull
    )

    Assert-WorkflowStateScalarString -Value $Value -AllowNull:$AllowNull
    if ($null -eq $Value) {
        return
    }

    if ($Value -match '\s') {
        throw 'Workflow-state URI cannot contain whitespace.'
    }

    $uri = $null
    if (-not [System.Uri]::TryCreate($Value, [System.UriKind]::Absolute, [ref]$uri)) {
        throw 'Workflow-state value must be an absolute URI.'
    }
}

function Assert-WorkflowStateSha {
    <# Requires lowercase, forty-character hexadecimal SHA text. #>
    param(
        [object]$Value,
        [switch]$AllowNull
    )

    Assert-WorkflowStateScalarString -Value $Value -AllowNull:$AllowNull
    if ($null -eq $Value) {
        return
    }

    $options = [System.Text.RegularExpressions.RegexOptions]::CultureInvariant
    if (-not [System.Text.RegularExpressions.Regex]::IsMatch($Value, '\A[0-9a-f]{40}\z', $options)) {
        throw 'Workflow-state SHA must be lowercase forty-character hexadecimal text.'
    }
}

function Assert-WorkflowStateCanonicalUtcTimestamp {
    <# Requires the documented UTC grammar and exact invariant Gregorian parsing. #>
    param(
        [object]$Value
    )

    Assert-WorkflowStateScalarString -Value $Value

    $options = [System.Text.RegularExpressions.RegexOptions]::CultureInvariant
    $grammar = '\A[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{1,7})?Z\z'
    if (-not [System.Text.RegularExpressions.Regex]::IsMatch($Value, $grammar, $options)) {
        throw 'Workflow-state timestamp does not use canonical UTC grammar.'
    }

    $format = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    if ($Value.Contains('.')) {
        $format = "yyyy-MM-dd'T'HH:mm:ss.FFFFFFF'Z'"
    }

    $parsed = [DateTime]::MinValue
    if (-not [DateTime]::TryParseExact(
            $Value,
            $format,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::None,
            [ref]$parsed)) {
        throw 'Workflow-state timestamp is not a valid Gregorian UTC time.'
    }
}

function Assert-WorkflowStateOrdinalUniqueStrings {
    <# Requires unique scalar strings while preserving arbitrary caller order. #>
    param(
        [object]$Value
    )

    Assert-WorkflowStateArray -Value $Value
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($item in $Value) {
        Assert-WorkflowStateScalarString -Value $item
        if (-not $seen.Add($item)) {
            throw "Workflow-state string '$item' is repeated."
        }
    }
}

function Assert-WorkflowStateSortedUniqueStrings {
    <# Requires scalar strings in strictly increasing ordinal order. #>
    param(
        [object]$Value
    )

    Assert-WorkflowStateArray -Value $Value
    $has_previous = $false
    $previous = $null
    foreach ($item in $Value) {
        Assert-WorkflowStateScalarString -Value $item
        if ($has_previous -and ([string]::CompareOrdinal($previous, $item) -ge 0)) {
            throw 'Workflow-state strings must be strictly increasing in ordinal order.'
        }

        $previous = $item
        $has_previous = $true
    }
}

function Test-WorkflowStateSensitiveError {
    <#
    Detects known credential indicators for an error boundary. It intentionally
    returns only a Boolean; redaction and output handling belong to later code.
    #>
    param(
        [object]$Value
    )

    if ($null -eq $Value) {
        return $false
    }

    Assert-WorkflowStateScalarString -Value $Value

    $term_options = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor `
        [System.Text.RegularExpressions.RegexOptions]::CultureInvariant
    if ([System.Text.RegularExpressions.Regex]::IsMatch(
            $Value,
            '(?<![A-Za-z0-9_])(authorization|bearer|token)(?![A-Za-z0-9_])',
            $term_options)) {
        return $true
    }

    if ($Value.IndexOf('hosts.yml', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        return $true
    }

    foreach ($prefix in @('ghp_', 'gho_', 'ghu_', 'ghs_', 'ghr_', 'github_pat_')) {
        if ($Value.IndexOf($prefix, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            return $true
        }
    }

    return $false
}
