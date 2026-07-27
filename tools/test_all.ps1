param()

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
Set-Location -LiteralPath $ProjectRoot

$Global:AllPassed = $true

function Write-Step {
    param([string]$Label, [string]$Status, [string]$Detail = '')
    $color = if ($Status -eq 'PASS') { 'Green' } elseif ($Status -eq 'FAIL') { 'Red' } else { 'Yellow' }
    Write-Host "[$Status] $Label $Detail" -ForegroundColor $color
}

function Invoke-StepHard {
    param([string]$Label, [scriptblock]$Block)
    Write-Host "`n========== $Label ==========" -ForegroundColor Cyan
    try {
        & $Block
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE" }
        Write-Step -Label $Label -Status 'PASS'
    } catch {
        Write-Step -Label $Label -Status 'FAIL' -Detail "- $_"
        $Global:AllPassed = $false
        Write-Host "`nStopping due to failure." -ForegroundColor Red
        exit 1
    }
}

# ── Step 1: Analyze ──────────────────────────────────────────────
Invoke-StepHard -Label 'flutter analyze' -Block {
    $output = flutter analyze 2>&1
    $output | Out-String | Write-Host
    if ($LASTEXITCODE -ne 0) { throw "Analyze found issues." }
}

# ── Step 2: Unit/Widget tests ────────────────────────────────────
Invoke-StepHard -Label 'flutter test' -Block {
    $output = flutter test 2>&1
    $output | Out-String | Write-Host
    if ($LASTEXITCODE -ne 0) { throw "Tests failed." }
}

# ── Step 3: Clean (prevents stale cache issues) ──────────────────
Invoke-StepHard -Label 'flutter clean' -Block {
    $output = flutter clean 2>&1
    Write-Host $output
}

# ── Step 4: Release build ─────────────────────────────────────────
Invoke-StepHard -Label 'flutter build apk --release --split-per-abi' -Block {
    $output = flutter build apk --release --split-per-abi 2>&1
    Write-Host $output
    if ($LASTEXITCODE -ne 0) { throw "Build failed." }
}

# ── Summary ───────────────────────────────────────────────────────
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  ALL CHECKS PASSED" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
