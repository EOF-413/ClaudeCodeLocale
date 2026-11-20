# start_web_ui.ps1 - Launch claude-web-ui
$ErrorActionPreference = "Stop"

$Root       = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Src        = Join-Path $Root "src"
$Data       = Join-Path $Root "data"
$ConfigPath = Join-Path $Root "config\config.jsonc"

if (-not (Test-Path $ConfigPath)) { throw "config.jsonc not found at $ConfigPath" }

# Читаем JSONC
$rawConfig = Get-Content $ConfigPath -Raw -Encoding UTF8
$rawConfig = [regex]::Replace($rawConfig, '(?m)^\s*//.*$', '')
$rawConfig = [regex]::Replace($rawConfig, '(?<!:)//.*$', '')
$Config    = $rawConfig | ConvertFrom-Json

# Настраиваем окружение
$env:Path = "$Src\python;$Src\python\Scripts;$Src\node;$Src\ollama;$Src\claude-code;$env:Path"
$env:OLLAMA_MODELS         = Join-Path $Data "models"
$env:OLLAMA_HOST           = $Config.ollama_host
$env:OLLAMA_KEEP_ALIVE     = $Config.keep_alive
$env:OLLAMA_CONTEXT_LENGTH = "$($Config.context_length)"
if ($Config.flash_attention) { $env:OLLAMA_FLASH_ATTENTION = "1" }
if ($Config.kv_cache_type)   { $env:OLLAMA_KV_CACHE_TYPE   = $Config.kv_cache_type }

# Указываем Claude Code смотреть на Ollama
$env:ANTHROPIC_AUTH_TOKEN = "ollama"
$env:ANTHROPIC_API_KEY    = ""
$env:ANTHROPIC_MODEL      = "$($Config.model)"
$env:ANTHROPIC_BASE_URL   = "http://$($Config.ollama_host)"
$env:CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS = "1"

New-Item -ItemType Directory -Force -Path $env:OLLAMA_MODELS | Out-Null

# Запускаем Ollama если не запущен
$ollamaRunning = $false
try {
    $resp = Invoke-WebRequest -Uri "http://$($Config.ollama_host)/api/tags" -TimeoutSec 2 -UseBasicParsing
    if ($resp.StatusCode -eq 200) { $ollamaRunning = $true }
} catch {}

if (-not $ollamaRunning) {
    Write-Host "Starting Ollama serve..." -ForegroundColor Green
    Start-Process -FilePath "$Src\ollama\ollama.exe" -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 5
}

# Запускаем Web UI (путь изменен на src\python\Scripts)
$claudeWeb = Join-Path $Src "python\Scripts\claude-web.exe"
if (-not (Test-Path $claudeWeb)) {
    throw "claude-web.exe not found. Please run Setup (option 1) first."
}

Write-Host "Launching claude-web-ui..." -ForegroundColor Green
& $claudeWeb --open