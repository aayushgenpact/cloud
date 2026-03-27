#$path = "C:\Program Files\GrafanaLabs\Alloy\config.alloy"

# Create backup
#$timestamp = Get-Date -Format "yyyyMMddHHmmss"
#$backup = "$path.bak_$timestamp"

#Copy-Item -LiteralPath $path -Destination $backup -Force
#Write-Host "Backup created: $backup"

#Write-Host "===== BEFORE ====="
#Get-Content $path | Select-String "enabled_collectors"

#$content = Get-Content -LiteralPath $path -Raw

# Remove "process" from enabled_collectors
#$content = $content -replace ',\s*"process"', ''
#$content = $content -replace '"process",\s*', ''

# ✅ FIXED LINE
#Set-Content -LiteralPath $path -Value $content

#Write-Host "===== AFTER ====="
#Get-Content $path | Select-String "enabled_collectors"

#Restart-Service alloy -Force

#Start-Sleep 5

#Get-Service alloy
####################################################################################################################

$path = "C:\Program Files\GrafanaLabs\Alloy\config.alloy"
$backup = "$path" + "_bak"

# GitHub raw URL (update this)
$url = "https://raw.githubusercontent.com/aayushgenpact/cloud/refs/heads/main/config.alloy"

# ===== 1. BACKUP =====
Copy-Item -LiteralPath $path -Destination $backup -Force
Write-Host "Backup created: $backup"

# ===== 2. DOWNLOAD =====
$tempFile = "$env:TEMP\config.alloy"
Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing
Write-Host "Config downloaded"

# ===== 3. REPLACE =====
Copy-Item -LiteralPath $tempFile -Destination $path -Force
Write-Host "Config updated"

# ===== 4. RESTART SERVICE =====
Restart-Service alloy -Force
Write-Host "Alloy restarted"

# ===== 5. VERIFY =====
Start-Sleep 3
Get-Service alloy
