# start_setup.ps1 - idempotent installer
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Src  = Join-Path $Root "src"
$Data = Join-Path $Root "data"

New-Item -ItemType Directory -Force -Path $Src, $Data | Out-Null
New-Item -ItemType Directory -Force -Path "$Src\python", "$Src\node", "$Src\ollama", "$Src\claude-code" | Out-Null

# 1. Python 3.11 embeddable (без изменений)
$pyExe = "$Src\python\python.exe"
if (Test-Path $pyExe) {
    Write-Host "[1/6] Python - already exists, skip" -ForegroundColor DarkGray
} else {
    Write-Host "[1/6] Downloading Python 3.11" -ForegroundColor Cyan
    $pyZip = Join-Path $Src "python.zip"
    Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip" -OutFile $pyZip
    Expand-Archive -Path $pyZip -DestinationPath "$Src\python" -Force
    Remove-Item $pyZip
    $pth = Join-Path $Src "python\python311._pth"
    if (Test-Path $pth) {
        (Get-Content $pth) -replace '^\#\s*import site', 'import site' | Set-Content $pth
    }
}

# 2. pip (без изменений)
$pipExe = "$Src\python\Scripts\pip.exe"
if (Test-Path $pipExe) {
    Write-Host "[2/6] pip - already exists, skip" -ForegroundColor DarkGray
} else {
    Write-Host "[2/6] Installing pip" -ForegroundColor Cyan
    $getPip = Join-Path $Src "python\get-pip.py"
    Invoke-WebRequest -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile $getPip
    & $pyExe $getPip
    Remove-Item $getPip
}

# 3. Node.js 22.22.0 (без изменений)
$nodeExe = "$Src\node\node.exe"
if (Test-Path $nodeExe) {
    Write-Host "[3/6] Node.js - already exists, skip" -ForegroundColor DarkGray
} else {
    Write-Host "[3/6] Downloading Node.js 22.22.0" -ForegroundColor Cyan
    $nodeZip = Join-Path $Src "node.zip"
    Invoke-WebRequest -Uri "https://nodejs.org/dist/v22.22.0/node-v22.22.0-win-x64.zip" -OutFile $nodeZip
    Expand-Archive -Path $nodeZip -DestinationPath "$Src\node" -Force
    Remove-Item $nodeZip
    $inner = Get-ChildItem "$Src\node" -Directory | Select-Object -First 1
    if ($inner) {
        Get-ChildItem $inner.FullName | Move-Item -Destination "$Src\node" -Force
        Remove-Item $inner.FullName -Recurse -Force
    }
}

# 4. Ollama (без изменений)
$ollamaExe = "$Src\ollama\ollama.exe"
if (Test-Path $ollamaExe) {
    Write-Host "[4/6] Ollama - already exists, skip" -ForegroundColor DarkGray
} else {
    Write-Host "[4/6] Downloading Ollama" -ForegroundColor Cyan
    $ollamaZip = Join-Path $Src "ollama.zip"
    Invoke-WebRequest -Uri "https://ollama.com/download/ollama-windows-amd64.zip" -OutFile $ollamaZip
    Expand-Archive -Path $ollamaZip -DestinationPath "$Src\ollama" -Force
    Remove-Item $ollamaZip
}

# 5. Claude Code CLI - DIRECT DOWNLOAD (no install.ps1, no hang)
$claudeExe = "$Src\claude-code\claude.exe"
if (Test-Path $claudeExe) {
    # Проверяем, что файл не битый (размер > 50 MB)
    $size = (Get-Item $claudeExe).Length
    if ($size -gt 50MB) {
        Write-Host "[5/6] claude.exe - already exists ($([math]::Round($size/1MB,1)) MB), skip" -ForegroundColor DarkGray
    } else {
        Write-Host "[5/6] claude.exe is corrupted ($size bytes), re-downloading..." -ForegroundColor Yellow
        Remove-Item $claudeExe -Force
    }
}

if (-not (Test-Path $claudeExe)) {
    Write-Host "[5/6] Downloading Claude Code binary directly..." -ForegroundColor Cyan
    
    # Официальный URL для Windows x64 (версия 2.1.109, можно обновить при необходимости)
    $claudeUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/2.1.109/win32-x64/claude.exe"
    
    try {
        Invoke-WebRequest -Uri $claudeUrl -OutFile $claudeExe -TimeoutSec 300
    } catch {
        throw "Failed to download claude.exe: $_"
    }
    
    # Проверка, что скачался именно бинарник, а не HTML-страница
    $size = (Get-Item $claudeExe).Length
    if ($size -lt 50MB) {
        Remove-Item $claudeExe -Force
        throw "Downloaded claude.exe is too small ($size bytes). Likely an error page. Check the URL or your network."
    }
    
    Write-Host "[5/6] claude.exe downloaded successfully ($([math]::Round($size/1MB,1)) MB)" -ForegroundColor Green
}

# 6. claude-web-ui (без изменений)
$claudeWeb = Join-Path $Src "python\Scripts\claude-web.exe"
if (Test-Path $claudeWeb) {
    Write-Host "[6/6] claude-web-ui - already installed, skip" -ForegroundColor DarkGray
} else {
    Write-Host "[6/6] Installing claude-web-ui into src\python" -ForegroundColor Cyan
    & $pyExe -m pip install --upgrade pip
    if ($LASTEXITCODE -ne 0) { throw "pip upgrade failed" }
    
    & $pyExe -m pip install claude-web-ui
    if ($LASTEXITCODE -ne 0) { throw "claude-web-ui installation failed" }
    
    Write-Host "[6/6] claude-web-ui installed successfully" -ForegroundColor Green
}

Write-Host "=== SETUP COMPLETE ===" -ForegroundColor Green