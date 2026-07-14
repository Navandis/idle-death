param([string]$CommitSha = "")
$ErrorActionPreference = "Continue"
$LogDir = Join-Path $PSScriptRoot "logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$Log = Join-Path $LogDir "m03-owner-$Stamp.log"
function Run-Step($Name, $Command) {
    Add-Content $Log "--- $Name ---"
    Write-Host "Running $Name"
    cmd /c $Command 2>&1 | Tee-Object -FilePath $Log -Append
    if ($LASTEXITCODE -ne 0) { Add-Content $Log "FAILED $Name exit $LASTEXITCODE"; exit $LASTEXITCODE }
}
Add-Content $Log "M03 owner verification for $CommitSha"
Run-Step "Godot version" "godot --version"
Run-Step "Full GUT before" "bash ./tools/test/run_gut.sh"
Run-Step "Focused M03" "bash ./tools/test/run_gut.sh -- -gdir=res://tests/unit/content -gdir=res://tests/integration/content"
Run-Step "Import" "godot --headless --path . --import"
Run-Step "Trace" "godot --headless --path . -s res://tools/test/m03/m03_content_catalog_trace.gd"
Run-Step "Full GUT after" "bash ./tools/test/run_gut.sh"
Add-Content $Log "Inspector checklist: Pending owner verification"
Write-Host "PASS. Log: $Log"
