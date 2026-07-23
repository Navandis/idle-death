#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot,

    [Parameter(Mandatory = $true)]
    [string]$ExpectedBranch,

    [string]$BaseBranch = 'main',

    [Parameter(Mandatory = $true)]
    [string]$Title,

    [Parameter(Mandatory = $true)]
    [string]$BodyFile,

    [switch]$Draft
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-Captured {
    param(
        [Parameter(Mandatory = $true)][string]$Executable,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [string]$Label = $Executable
    )

    $output = & $Executable @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        $rendered = ($output | Out-String).Trim()
        throw "$Label failed with exit code $exitCode.`n$rendered"
    }
    return (($output | Out-String).Trim())
}

function Assert-Command {
    param([Parameter(Mandatory = $true)][string]$Name)
    if ($null -eq (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command is unavailable: $Name"
    }
}

Assert-Command 'git'
Assert-Command 'gh'

$repo = [System.IO.Path]::GetFullPath($RepoRoot)
if (-not (Test-Path -LiteralPath $repo -PathType Container)) {
    throw "Repository root does not exist: $repo"
}

$bodyPath = $BodyFile
if (-not [System.IO.Path]::IsPathRooted($bodyPath)) {
    $bodyPath = Join-Path $repo $bodyPath
}
$bodyPath = [System.IO.Path]::GetFullPath($bodyPath)
if (-not (Test-Path -LiteralPath $bodyPath -PathType Leaf)) {
    throw "PR body file does not exist: $bodyPath"
}

Push-Location $repo
try {
    $resolvedRoot = Invoke-Captured 'git' @('rev-parse', '--show-toplevel') 'git repository check'
    if ([System.IO.Path]::GetFullPath($resolvedRoot) -ne $repo.TrimEnd([System.IO.Path]::DirectorySeparatorChar)) {
        throw "RepoRoot is not the checkout root. Git reported: $resolvedRoot"
    }

    $currentBranch = Invoke-Captured 'git' @('branch', '--show-current') 'current branch check'
    if ([string]::IsNullOrWhiteSpace($currentBranch)) {
        throw 'Detached HEAD is not allowed for milestone publication.'
    }
    if ($currentBranch -eq $BaseBranch) {
        throw "Refusing to publish from protected base branch '$BaseBranch'."
    }
    if ($currentBranch -ne $ExpectedBranch) {
        throw "Current branch '$currentBranch' does not match expected branch '$ExpectedBranch'."
    }

    $statusLines = @(& git status --porcelain=v1 --untracked-files=all 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw 'git status failed.'
    }
    $trackedChanges = @($statusLines | Where-Object { $_ -notmatch '^\?\?' -and -not [string]::IsNullOrWhiteSpace($_) })
    if ($trackedChanges.Count -gt 0) {
        throw "Tracked or staged changes remain. Commit them before publication:`n$($trackedChanges -join "`n")"
    }
    $untracked = @($statusLines | Where-Object { $_ -match '^\?\?' })
    if ($untracked.Count -gt 0) {
        Write-Warning "Untracked files are present and will not be published unless already ignored or intentionally added:`n$($untracked -join "`n")"
    }

    Invoke-Captured 'gh' @('auth', 'status') 'GitHub CLI authentication' | Write-Host
    Invoke-Captured 'git' @('fetch', 'origin', $BaseBranch) 'fetch base branch' | Write-Host

    $remoteBase = "origin/$BaseBranch"
    & git merge-base --is-ancestor $remoteBase HEAD *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "Current HEAD is not based on $remoteBase. Stop for an explicit branch-update decision; this helper will not merge, rebase, or force-push."
    }

    $aheadText = Invoke-Captured 'git' @('rev-list', '--count', "$remoteBase..HEAD") 'ahead-of-base check'
    $ahead = 0
    if (-not [int]::TryParse($aheadText, [ref]$ahead) -or $ahead -le 0) {
        throw "Current branch has no commits ahead of $remoteBase."
    }

    $headSha = Invoke-Captured 'git' @('rev-parse', 'HEAD') 'HEAD resolution'
    Invoke-Captured 'git' @('push', '--set-upstream', 'origin', $currentBranch) 'feature-branch push' | Write-Host

    $existingJson = Invoke-Captured 'gh' @('pr', 'list', '--head', $currentBranch, '--base', $BaseBranch, '--state', 'open', '--limit', '10', '--json', 'number,url') 'open PR lookup'
    $existing = @($existingJson | ConvertFrom-Json)
    if ($existing.Count -gt 1) {
        throw "More than one open PR exists for branch '$currentBranch'. Stop for owner review."
    }

    if ($existing.Count -eq 1) {
        $prNumber = [int]$existing[0].number
        Invoke-Captured 'gh' @('pr', 'edit', "$prNumber", '--title', $Title, '--body-file', $bodyPath) 'PR update' | Write-Host
    }
    else {
        $createArgs = @('pr', 'create', '--base', $BaseBranch, '--head', $currentBranch, '--title', $Title, '--body-file', $bodyPath)
        if ($Draft) {
            $createArgs += '--draft'
        }
        Invoke-Captured 'gh' $createArgs 'PR creation' | Write-Host
    }

    $prJson = Invoke-Captured 'gh' @('pr', 'view', $currentBranch, '--json', 'number,url,headRefName,baseRefName,state,isDraft') 'PR verification'
    $pr = $prJson | ConvertFrom-Json
    if ($pr.baseRefName -ne $BaseBranch -or $pr.headRefName -ne $currentBranch -or $pr.state -ne 'OPEN') {
        throw 'Created or updated PR does not match the expected open head/base contract.'
    }

    Write-Host ''
    Write-Host 'Milestone PR published without merge.'
    Write-Host "PR_NUMBER=$($pr.number)"
    Write-Host "PR_URL=$($pr.url)"
    Write-Host "HEAD_BRANCH=$currentBranch"
    Write-Host "BASE_BRANCH=$BaseBranch"
    Write-Host "HEAD_SHA=$headSha"
    Write-Host "IS_DRAFT=$($pr.isDraft)"
    Write-Host 'STOP: Do not merge, close, delete, or force-push. Return control to the project owner.'
}
finally {
    Pop-Location
}
