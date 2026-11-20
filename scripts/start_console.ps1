# start_console.ps1 - Launch Claude Code CLI directly
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

# Окружение
$env:Path = "$Src\python;$Src\python\Scripts;$Src\node;$Src\ollama;$Src\claude-code;$env:Path"
$env:OLLAMA_MODELS         = Join-Path $Data "models"
$env:OLLAMA_HOST           = $Config.ollama_host
$env:OLLAMA_KEEP_ALIVE     = $Config.keep_alive
$env:OLLAMA_CONTEXT_LENGTH = "$($Config.context_length)"
if ($Config.flash_attention) { $env:OLLAMA_FLASH_ATTENTION = "1" }
if ($Config.kv_cache_type)   { $env:OLLAMA_KV_CACHE_TYPE   = $Config.kv_cache_type }

$env:ANTHROPIC_AUTH_TOKEN = "ollama"
$env:ANTHROPIC_API_KEY    = ""
$env:ANTHROPIC_MODEL      = "$($Config.model)"
$env:ANTHROPIC_BASE_URL   = "http://$($Config.ollama_host)"
$env:CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS = "1"

# Запуск Ollama (если нужно)
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

# Запуск CLI
Write-Host "Launching Claude Code CLI (model: $($Config.model))..." -ForegroundColor Green
& "$Src\claude-code\claude.exe"