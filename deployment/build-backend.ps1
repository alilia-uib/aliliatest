<#
.SYNOPSIS
    Build a deployment zip for the FastAPI backend, matching the GitHub Actions
    workflow (.github/workflows/deploy-backend.yml).

.DESCRIPTION
    Packages the backend/ folder into deployment/backend-release.zip.
    Excludes local development artifacts (venv, __pycache__, *.pyc,
    .pytest_cache, .env). Dependencies are installed on Azure App Service
    during deployment via Oryx (requirements.txt is included in the zip), which
    requires the SCM_DO_BUILD_DURING_DEPLOYMENT=true app setting.

    After running this script, deploy backend-release.zip to Azure App Service:

        az webapp config appsettings set `
            --name lnett-webapp-infrasight1-api `
            --resource-group <YOUR_RESOURCE_GROUP> `
            --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true WEBSITES_PORT=8000

        az webapp config set `
            --name lnett-webapp-infrasight1-api `
            --resource-group <YOUR_RESOURCE_GROUP> `
            --startup-file "python -m uvicorn main:app --host 0.0.0.0 --port 8000"

        az webapp deploy `
            --name lnett-webapp-infrasight1-api `
            --resource-group <YOUR_RESOURCE_GROUP> `
            --src-path deployment/backend-release.zip `
            --type zip
#>

[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $RepoRoot)   { $RepoRoot   = Split-Path -Parent $scriptDir }
if (-not $OutputPath) { $OutputPath = Join-Path $scriptDir 'backend-release.zip' }
$OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)

$backendPath = Join-Path $RepoRoot 'backend'
if (-not (Test-Path $backendPath)) {
    throw "Backend folder not found: $backendPath"
}

# Exclusion patterns (relative to $backendPath) that mirror the workflow's zip -x flags.
$excludeDirs  = @('venv', '__pycache__', '.pytest_cache', '.venv', '.mypy_cache')
$excludeExts  = @('.pyc', '.pyo')
$excludeFiles = @('.env')

function Test-ShouldInclude {
    param([System.IO.FileSystemInfo]$Item, [string]$Root)

    $relative = $Item.FullName.Substring($Root.Length).TrimStart('\', '/')
    $segments = $relative -split '[\\/]'

    foreach ($seg in $segments) {
        if ($excludeDirs -contains $seg) { return $false }
    }
    if ($Item -is [System.IO.FileInfo]) {
        if ($excludeExts -contains $Item.Extension.ToLower()) { return $false }
        if ($excludeFiles -contains $Item.Name)              { return $false }
    }
    return $true
}

if (Test-Path $OutputPath) { Remove-Item $OutputPath -Force }

$staging = Join-Path ([System.IO.Path]::GetTempPath()) ("infrasight-backend-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $staging | Out-Null

try {
    Write-Host "Staging backend files..."
    $rootFull = (Resolve-Path $backendPath).Path

    Get-ChildItem -Path $backendPath -Recurse -Force | ForEach-Object {
        if (-not (Test-ShouldInclude -Item $_ -Root $rootFull)) { return }

        $relative = $_.FullName.Substring($rootFull.Length).TrimStart('\', '/')
        $target   = Join-Path $staging $relative

        if ($_ -is [System.IO.DirectoryInfo]) {
            New-Item -ItemType Directory -Force -Path $target | Out-Null
        } else {
            $parent = Split-Path $target -Parent
            if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
            Copy-Item -LiteralPath $_.FullName -Destination $target -Force
        }
    }

    Write-Host "Creating archive: $OutputPath"
    # Compress-Archive in Windows PowerShell 5.1 writes '\' separators, which Linux
    # App Service extracts as literal file names; write '/' entries explicitly.
    Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
    $stagingFull = (Resolve-Path $staging).Path
    $zip = [System.IO.Compression.ZipFile]::Open($OutputPath, 'Create')
    try {
        Get-ChildItem -Path $stagingFull -Recurse -File -Force | ForEach-Object {
            $entryName = $_.FullName.Substring($stagingFull.Length).TrimStart('\', '/').Replace('\', '/')
            [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $entryName)
        }
    }
    finally {
        $zip.Dispose()
    }
}
finally {
    Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue
}

$size = (Get-Item $OutputPath).Length
Write-Host ("Backend package created: {0} ({1:N0} bytes)" -f $OutputPath, $size)
