$path = "C:\Program Files\GrafanaLabs\Alloy\config.alloy"

# Create backup
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$backup = "$path.bak_$timestamp"

Copy-Item -LiteralPath $path -Destination $backup -Force
Write-Host "✅ Backup created: $backup"

Write-Host "===== BEFORE ====="
Get-Content $path | Select-String "regex"

$content = Get-Content -LiteralPath $path -Raw

# Remove ONLY the windows_process_* block
$updated = $content -replace 'windows_process_io_operations_total\|windows_process_io_bytes_total\|windows_process_working_set_private_bytes\|windows_process_working_set_peak_bytes\|windows_process_working_set_bytes\|windows_process_cpu_time_total\|windows_process_private_bytes\|',''

Set-Content -LiteralPath $path $updated

Write-Host "===== AFTER ====="
Get-Content $path | Select-String "regex"

Restart-Service alloy -Force

Start-Sleep 5

Get-Service alloy
