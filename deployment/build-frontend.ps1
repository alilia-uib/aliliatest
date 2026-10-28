<#
.SYNOPSIS
    Build a deployment zip for the React/Vite frontend, matching the GitHub
    Actions workflow (.github/workflows/deploy-frontend.yml).

.DESCRIPTION
    Runs `npm ci` and `npm run build` in frontend/, then packages the built
    dist/ output (as public/) plus a small Node.js static-file server
    (server.js) that Azure App Service starts via `node server.js`.

    Output: deployment/frontend-release.zip

    Deploy to Azure App Service:

        az webapp deploy `
            --name lnett-webapp-infrasight1 `
            --resource-group <YOUR_RESOURCE_GROUP> `
            --src-path deployment/frontend-release.zip `
            --type zip

.PARAMETER ViteApiBaseUrl
    Optional value passed as the VITE_API_BASE_URL env var during `npm run
    build`. The value is baked into the bundle and used by
    src/view/components/GraphView.jsx as the API base URL (falls back to
    http://127.0.0.1:8000 when unset, so set it for production builds).

.PARAMETER NodeBinDir
    Optional directory to prepend to PATH so a portable Node.js install can
    be used (e.g. the winget install location). Defaults to $env:NODE_BIN if
    set, otherwise none (assumes node/npm are on PATH).
#>

[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$OutputPath,
    [string]$ViteApiBaseUrl = $env:VITE_API_BASE_URL,
    [string]$NodeBinDir     = $env:NODE_BIN
)

$ErrorActionPreference = 'Stop'

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $RepoRoot)   { $RepoRoot   = Split-Path -Parent $scriptDir }
if (-not $OutputPath) { $OutputPath = Join-Path $scriptDir 'frontend-release.zip' }
$OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)

$frontendPath = Join-Path $RepoRoot 'frontend'
if (-not (Test-Path $frontendPath)) {
    throw "Frontend folder not found: $frontendPath"
}

if ($NodeBinDir -and (Test-Path $NodeBinDir)) {
    $env:Path = "$NodeBinDir;$env:Path"
}

# Verify tooling.
try {
    $nodeVersion = & node --version
    $npmVersion  = & npm.cmd --version
} catch {
    throw "Node.js/npm not found on PATH. Install Node 22+ or pass -NodeBinDir."
}
Write-Host "Using Node $nodeVersion / npm $npmVersion"

Push-Location $frontendPath
try {
    Write-Host "Installing dependencies (npm ci)..."
    & npm.cmd ci
    if ($LASTEXITCODE -ne 0) { throw "npm ci failed with exit code $LASTEXITCODE" }

    if ($ViteApiBaseUrl) {
        $env:VITE_API_BASE_URL = $ViteApiBaseUrl
        Write-Host "Building with VITE_API_BASE_URL=$ViteApiBaseUrl"
    } else {
        Write-Host "Building production bundle..."
    }
    & npm.cmd run build
    if ($LASTEXITCODE -ne 0) { throw "npm run build failed with exit code $LASTEXITCODE" }
}
finally {
    Pop-Location
}

$distPath   = Join-Path $frontendPath 'dist'
$deployPath = Join-Path $frontendPath 'deploy'

if (-not (Test-Path $distPath)) {
    throw "Vite build did not produce a dist/ folder at $distPath"
}

if (Test-Path $deployPath) { Remove-Item $deployPath -Recurse -Force }
New-Item -ItemType Directory -Path $deployPath | Out-Null
Copy-Item -Path $distPath -Destination (Join-Path $deployPath 'public') -Recurse

# Minimal static file server for Azure App Service (matches the workflow).
$serverJs = @'
const http = require('http');
const fs = require('fs');
const path = require('path');

const port = process.env.PORT || 8080;
const root = path.join(__dirname, 'public');
const indexFile = path.join(root, 'index.html');

const mime = {
  '.html': 'text/html; charset=utf-8',
  '.js':   'application/javascript; charset=utf-8',
  '.mjs':  'application/javascript; charset=utf-8',
  '.css':  'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg':  'image/svg+xml',
  '.png':  'image/png',
  '.jpg':  'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif':  'image/gif',
  '.ico':  'image/x-icon',
  '.webp': 'image/webp',
  '.woff': 'font/woff',
  '.woff2':'font/woff2',
  '.ttf':  'font/ttf',
  '.map':  'application/json; charset=utf-8'
};

function send(res, filePath) {
  const ext = path.extname(filePath).toLowerCase();
  const headers = { 'Content-Type': mime[ext] || 'application/octet-stream' };
  // Vite emits content-hashed files under /assets; everything else must revalidate.
  headers['Cache-Control'] = filePath.startsWith(path.join(root, 'assets') + path.sep)
    ? 'public, max-age=31536000, immutable'
    : 'no-cache';
  const stream = fs.createReadStream(filePath);
  stream.on('error', () => {
    if (!res.headersSent) res.writeHead(500);
    res.end();
  });
  res.writeHead(200, headers);
  stream.pipe(res);
}

const server = http.createServer((req, res) => {
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    res.writeHead(405, { Allow: 'GET, HEAD' }); res.end(); return;
  }

  let urlPath;
  try {
    urlPath = decodeURIComponent(req.url.split('?')[0]);
  } catch {
    res.writeHead(400); res.end('Bad Request'); return;
  }

  const filePath = path.join(root, urlPath === '/' ? 'index.html' : urlPath);
  if (filePath !== root && !filePath.startsWith(root + path.sep)) {
    res.writeHead(403); res.end('Forbidden'); return;
  }

  fs.stat(filePath, (err, stat) => {
    send(res, !err && stat.isFile() ? filePath : indexFile);
  });
});

server.listen(port, () => console.log('Frontend listening on ' + port));
'@

$packageJson = @'
{
  "name": "infrasight-frontend-server",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "start": "node server.js"
  }
}
'@

Set-Content -Path (Join-Path $deployPath 'server.js')    -Value $serverJs    -Encoding UTF8
Set-Content -Path (Join-Path $deployPath 'package.json') -Value $packageJson -Encoding UTF8

if (Test-Path $OutputPath) { Remove-Item $OutputPath -Force }
Write-Host "Creating archive: $OutputPath"
# Compress-Archive in Windows PowerShell 5.1 writes '\' separators, which Linux
# App Service extracts as literal file names; write '/' entries explicitly.
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$deployFull = (Resolve-Path $deployPath).Path
$zip = [System.IO.Compression.ZipFile]::Open($OutputPath, 'Create')
try {
    Get-ChildItem -Path $deployFull -Recurse -File -Force | ForEach-Object {
        $entryName = $_.FullName.Substring($deployFull.Length).TrimStart('\', '/').Replace('\', '/')
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $entryName)
    }
}
finally {
    $zip.Dispose()
}
Remove-Item $deployPath -Recurse -Force

$size = (Get-Item $OutputPath).Length
Write-Host ("Frontend package created: {0} ({1:N0} bytes)" -f $OutputPath, $size)
