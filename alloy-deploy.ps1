$path = "C:\Program Files\GrafanaLabs\Alloy\config.alloy"

# Create backup
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$backup = "$path.bak_$timestamp"

Copy-Item -LiteralPath $path -Destination $backup -Force
Write-Host "✅ Backup created: $backup"

Write-Host "===== BEFORE ====="
Get-Content $path | Select-String "enabled_collectors"

$content = Get-Content -LiteralPath $path -Raw

# Remove "process" from enabled_collectors
$content = $content -replace ',\s*"process"', ''
$content = $content -replace '"process",\s*', ''
Set-Content -LiteralPath $path $updated

Write-Host "===== AFTER ====="
Get-Content $path | Select-String "enabled_collectors"

Restart-Service alloy -Force

Start-Sleep 5

Get-Service alloy
