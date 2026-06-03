$dryRun = $false; $autoConfirm = $false
foreach ($arg in $args) {
    if ($arg -eq "--dry-run") { $dryRun = $true }
    if ($arg -eq "-y" -or $arg -eq "--yes") { $autoConfirm = $true }
}

if (-not (Test-Path -Path ".git") -and -not (Test-Path -Path "AGENTS.md")) {
    [Console]::Error.WriteLine("Error: Not inside a valid project")
    exit 1
}

$tDir = Join-Path $PSScriptRoot "../templates/project"
if (-not (Test-Path -Path $tDir -PathType Container)) {
    [Console]::Error.WriteLine("Error: Templates directory not found at $tDir")
    exit 1
}

$dirs = @(".agents", ".agents/rules", ".agents/skills", "docs", "docs/adr", "docs/research", "data", "data/raw", "data/interim", "data/processed", "src", "tests", "notebooks", "scripts")
$files = @("AGENTS.md", "GEMINI.md", "CLAUDE.md", ".agents/rules/code-style.md", ".agents/rules/safety.md", ".gitignore", ".skillsrc", "README.md")

Write-Host "--- Alpha-Zero-G Project Upgrade Audit ---"
$add = 0; $skip = 0
foreach ($d in $dirs) {
    if (Test-Path -Path $d -PathType Container) { Write-Host "[EXISTS]  Directory: $d"; $skip++ }
    else { Write-Host "[MISSING] Directory: $d"; $add++ }
}
foreach ($f in $files) {
    if (Test-Path -Path $f -PathType Leaf) { Write-Host "[EXISTS]  File: $f"; $skip++ }
    else { Write-Host "[MISSING] File: $f"; $add++ }
}

if ($dryRun) { Write-Host "Dry-run mode. Stopping."; exit 0 }
if (-not $autoConfirm -and [Environment]::UserInteractive) {
    $resp = Read-Host "Proceed with upgrade? (y/N)"
    if ($resp -notmatch "^[Yy]$") { Write-Host "Upgrade cancelled."; exit 0 }
}

$projName = Split-Path -Leaf $pwd
foreach ($d in $dirs) { if (-not (Test-Path -Path $d)) { New-Item -ItemType Directory -Path $d -Force > $null } }

function Write-DefaultFile($path) {
    if (Test-Path -Path $path) { return }
    switch ($path) {
        "AGENTS.md" {
            (Get-Content -Path (Join-Path $tDir "AGENTS.md") -Raw) -replace '\{\{PROJECT_NAME\}\}', $projName | Out-File -FilePath $path -Encoding utf8
        }
        "GEMINI.md" { Copy-Item -Path (Join-Path $tDir "GEMINI.md") -Destination $path -Force }
        "CLAUDE.md" { Copy-Item -Path (Join-Path $tDir "CLAUDE.md") -Destination $path -Force }
        ".agents/rules/code-style.md" { Copy-Item -Path (Join-Path $tDir ".agents/rules/code-style.md") -Destination $path -Force }
        ".agents/rules/safety.md" { Copy-Item -Path (Join-Path $tDir ".agents/rules/safety.md") -Destination $path -Force }
        ".gitignore" { Copy-Item -Path (Join-Path $tDir "gitignore.template") -Destination $path -Force }
        ".skillsrc" { Copy-Item -Path (Join-Path $tDir "skillsrc.template") -Destination $path -Force }
        "README.md" {
            (Get-Content -Path (Join-Path $tDir "README.md") -Raw) -replace '\{\{PROJECT_NAME\}\}', $projName -replace '\{\{PROJECT_DESCRIPTION\}\}', "" | Out-File -FilePath $path -Encoding utf8
        }
    }
}

foreach ($f in $files) {
    if ($f -eq "AGENTS.md" -and (Test-Path -Path "AGENTS.md")) {
        $content = Get-Content -Path "AGENTS.md" -Raw
        if ($content -notmatch "## Alpha-Zero-G") {
            $block = "`n`n## Alpha-Zero-G`n- **Deterministic Python**: Always execute via \`uv run\` (\`uv run pytest\`, \`uv run python\`).`n- **No Symlink Portability**: All project rules are physical copies and use relative links.`n- **Explicit Typings**: Require strict type hints in Python."
            Add-Content -Path "AGENTS.md" -Value $block
        }
    } else {
        Write-DefaultFile $f
    }
}

$max = 0
if (Test-Path -Path "docs/adr") {
    $adrFiles = Get-ChildItem -Path "docs/adr" -Filter "ADR-*.md"
    foreach ($file in $adrFiles) {
        if ($file.Name -match "ADR-(\d+)-") {
            $num = [int]$Matches[1]
            if ($num -gt $max) { $max = $num }
        }
    }
}
$next = $max + 1
$nextPad = "{0:D3}" -f $next
$dateStr = (Get-Date).ToString("yyyy-MM-dd")
$adrFile = "docs/adr/ADR-$nextPad-alpha-zero-g-upgrade.md"

@"
# ADR-$($nextPad): Alpha-Zero-G Upgrade
**Status:** Accepted
**Date:** $dateStr

## Context
We need to upgrade the existing project to the latest Alpha-Zero-G canonical structure.

## Decision
Upgrade the project structure, append missing instructions to AGENTS.md, and ensure all canonical files/directories are present.

## Alternatives Considered
- Manual upgrade: Rejected because it is error-prone and time-consuming.

## Consequences
- Good: Project aligns with the latest Alpha-Zero-G standards.
- Bad: None.
"@ | Out-File -FilePath $adrFile -Encoding utf8
$add++

Write-Host "Upgrade complete. $add items added, $skip items skipped (already present)."
