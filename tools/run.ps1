param(
    [switch]$Release,
    [switch]$Analyze,
    [switch]$Test
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
Set-Location -LiteralPath $ProjectRoot

Write-Host "[WallKraft Windows Test]" -ForegroundColor Cyan

if ($Analyze) {
    Write-Host "[1/3] flutter analyze..." -ForegroundColor Yellow
    $output = flutter analyze 2>&1
    Write-Host $output
    if ($LASTEXITCODE -ne 0) { throw "Analyze failed." }
    Write-Host "[PASS] flutter analyze" -ForegroundColor Green
}

if ($Test) {
    Write-Host "[2/3] flutter test..." -ForegroundColor Yellow
    $output = flutter test 2>&1
    Write-Host $output
    if ($LASTEXITCODE -ne 0) { throw "Tests failed." }
    Write-Host "[PASS] flutter test" -ForegroundColor Green
}

$mode = if ($Release) { '--release' } else { '--debug' }
Write-Host "[3/3] flutter run -d windows $mode..." -ForegroundColor Yellow
Write-Host "(r=hot reload, R=hot restart, q=quit)" -ForegroundColor Gray

$output = flutter run -d windows $mode 2>&1
Write-Host $output
