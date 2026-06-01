param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$ProjectName,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("python", "r", "hybrid")]
    [string]$Type,
    
    [Parameter(Position=1, Mandatory=$false)]
    [string]$DestinationPath
)

$ErrorActionPreference = "Stop"

# Resolve paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if ([string]::IsNullOrEmpty($DestinationPath)) {
    $DestinationPath = Join-Path (Get-Location) $ProjectName
}

# Run the python scaffolder
python3 (Join-Path $ScriptDir "scaffold.py") $ProjectName $Type $DestinationPath
