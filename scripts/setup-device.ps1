$script:OkCount = 0

# Resolve paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$ManifestPath = Join-Path $RepoRoot "templates\skills_manifest.txt"
$GlobalTemplatesDir = Join-Path $RepoRoot "templates\global"
$StatuslineSrc = Join-Path $ScriptDir "statusline.py"

# Step 1: Clone mattpocock/skills to ~/.agent-skills/mattpocock/ (skip if exists)
Write-Host -NoNewline "Step 1: Clone mattpocock/skills to ~/.agent-skills/mattpocock/... "
$TargetSkillsDir = Join-Path $HOME ".agent-skills\mattpocock"
if (Test-Path $TargetSkillsDir) {
    Write-Host "SKIP"
} else {
    git clone --depth 1 https://github.com/mattpocock/skills.git $TargetSkillsDir > $null 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK"
        $script:OkCount++
    } else {
        Write-Host "FAIL"
    }
}

# Step 2: Physically copy the 10 selected skills (read from templates/skills_manifest.txt) to ~/.gemini/antigravity-cli/skills/ (create path if missing)
Write-Host -NoNewline "Step 2: Copy selected skills to ~/.gemini/antigravity-cli/skills/... "
$DestSkillsDir = Join-Path $HOME ".gemini\antigravity-cli\skills"
if (!(Test-Path $DestSkillsDir)) {
    $null = New-Item -ItemType Directory -Force -Path $DestSkillsDir
}

if (!(Test-Path $ManifestPath)) {
    Write-Host "FAIL (manifest missing)"
} else {
    $Failed = $false
    $Skills = Get-Content $ManifestPath
    foreach ($Line in $Skills) {
        $Skill = $Line.Split("#")[0].Trim()
        if ([string]::IsNullOrWhiteSpace($Skill)) { continue }
        
        $SrcSkill = Join-Path $TargetSkillsDir $Skill
        $DstSkill = Join-Path $DestSkillsDir $Skill
        
        if (Test-Path $SrcSkill) {
            if (Test-Path $DstSkill) {
                Remove-Item -Recurse -Force $DstSkill > $null 2>&1
            }
            Copy-Item -Recurse -Force $SrcSkill $DstSkill > $null 2>&1
        } else {
            $Failed = $true
        }
    }
    
    if (!$Failed) {
        Write-Host "OK"
        $script:OkCount++
    } else {
        Write-Host "FAIL (some skills missing in source)"
    }
}

# Function to deploy global files
function Deploy-GlobalFile {
    param(
        [int]$StepNum,
        [string]$Filename
    )
    Write-Host -NoNewline "Step $StepNum: Deploy global $Filename to ~/.gemini/$Filename... "
    $Src = Join-Path $GlobalTemplatesDir $Filename
    $Dest = Join-Path $HOME ".gemini\$Filename"
    
    $GeminiDir = Join-Path $HOME ".gemini"
    if (!(Test-Path $GeminiDir)) {
        $null = New-Item -ItemType Directory -Force -Path $GeminiDir
    }
    
    if (!(Test-Path $Src)) {
        Write-Host "FAIL (source file missing)"
        return
    }
    
    if (Test-Path $Dest) {
        Write-Host -NoNewline "File $Dest already exists. Overwrite? (y/n): "
        try {
            $Choice = $Host.UI.ReadLine()
        } catch {
            $Choice = "n"
        }
        if ([string]::IsNullOrEmpty($Choice)) { $Choice = "n" }
        
        if ($Choice.Trim().ToLower() -eq 'y') {
            Copy-Item -Force $Src $Dest > $null 2>&1
            Write-Host "OK"
            $script:OkCount++
        } else {
            Write-Host "SKIP"
        }
    } else {
        Copy-Item -Force $Src $Dest > $null 2>&1
        Write-Host "OK"
        $script:OkCount++
    }
}

# Step 3-5
Deploy-GlobalFile 3 "AGENTS.md"
Deploy-GlobalFile 4 "GEMINI.md"
Deploy-GlobalFile 5 "CLAUDE.md"

# Step 6: Copy scripts/statusline.py to ~/.agent-config/statusline.py
Write-Host -NoNewline "Step 6: Copy statusline.py to ~/.agent-config/statusline.py... "
$AgentConfigDir = Join-Path $HOME ".agent-config"
if (!(Test-Path $AgentConfigDir)) {
    $null = New-Item -ItemType Directory -Force -Path $AgentConfigDir
}

try {
    Copy-Item -Force $StatuslineSrc (Join-Path $AgentConfigDir "statusline.py") > $null 2>&1
    Write-Host "OK"
    $script:OkCount++
} catch {
    Write-Host "FAIL"
}

# Step 7: Patch ~/.gemini/antigravity-cli/settings.json using an inline Python command block
Write-Host -NoNewline "Step 7: Patch ~/.gemini/antigravity-cli/settings.json... "
$PyCode = @"
import os, json
path = os.path.expanduser('~/.gemini/antigravity-cli/settings.json')
os.makedirs(os.path.dirname(path), exist_ok=True)
data = {}
if os.path.exists(path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception:
        pass
if 'statusLine' not in data or not isinstance(data['statusLine'], dict):
    data['statusLine'] = {}
data['statusLine'].update({
    'type': 'custom',
    'command': 'python %USERPROFILE%\\\\.agent-config\\\\statusline.py',
    'enabled': True
})
with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2)
"@

python -c $PyCode 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "OK"
    $script:OkCount++
} else {
    Write-Host "FAIL"
}

# Step 8: Verify by executing python ~/.agent-config/statusline.py and print stdout
Write-Host -NoNewline "Step 8: Verify statusline execution... "
$StatuslinePath = Join-Path $AgentConfigDir "statusline.py"
if (Test-Path $StatuslinePath) {
    $Output = python $StatuslinePath 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK"
        Write-Host "Stdout: $Output"
        $script:OkCount++
    } else {
        Write-Host "FAIL (execution failed)"
    }
} else {
    Write-Host "FAIL (statusline.py not found)"
}

# Step 9: Print exit summary: N/8 steps OK
Write-Host "Step 9: Exit summary: $script:OkCount/8 steps OK."
exit 0
