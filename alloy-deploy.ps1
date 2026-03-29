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

#$path = "C:\Program Files\GrafanaLabs\Alloy\config.alloy"
#$backup = "$path" + "_bak"

# GitHub raw URL (update this)
#$url = "https://raw.githubusercontent.com/aayushgenpact/cloud/refs/heads/main/config.alloy"

# ===== 1. BACKUP =====
#Copy-Item -LiteralPath $path -Destination $backup -Force
#Write-Host "Backup created: $backup"

# ===== 2. DOWNLOAD =====
#$tempFile = "$env:TEMP\config.alloy"
#Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing
#Write-Host "Config downloaded"

# ===== 3. REPLACE =====
#Copy-Item -LiteralPath $tempFile -Destination $path -Force
#Write-Host "Config updated"

# ===== 4. RESTART SERVICE =====
#Restart-Service alloy -Force
#Write-Host "Alloy restarted"

# ===== 5. VERIFY =====
#Start-Sleep 3
#Get-Service alloy
################################################################################33

# ===== VARIABLES FROM PIPELINE =====
#param (
#    [string]$METRICS_URL,
#    [string]$METRICS_ID,
#    [string]$LOGS_URL,
#    [string]$LOGS_ID,
#    [string]$API_KEY
#)

#$alloyPath = "C:\Program Files\GrafanaLabs\Alloy"
#$configPath = "$alloyPath\config.alloy"
#$backup = "$configPath" + "_bak"

#Write-Host "===== Alloy Deployment Started ====="

# ===== CHECK IF ALLOY EXISTS =====
#if (!(Test-Path $alloyPath)) {

#    Write-Host "Alloy not found. Installing..."

#    cd ([System.IO.Path]::GetTempPath())

#    Invoke-WebRequest "https://storage.googleapis.com/cloud-onboarding/alloy/scripts/install-windows.ps1" -OutFile "install-windows.ps1"

 #   .\install-windows.ps1 `
#        -GCLOUD_HOSTED_METRICS_URL $METRICS_URL `
#        -GCLOUD_HOSTED_METRICS_ID $METRICS_ID `
#        -GCLOUD_SCRAPE_INTERVAL "60s" `
#        -GCLOUD_HOSTED_LOGS_URL $LOGS_URL `
#        -GCLOUD_HOSTED_LOGS_ID $LOGS_ID `
#        -GCLOUD_RW_API_KEY $API_KEY

 #   Write-Host "Alloy installed successfully"

#} else {

 #   Write-Host "Alloy already installed. Updating config..."

    # ===== BACKUP =====
  #  if (Test-Path $configPath) {
   #     Copy-Item $configPath $backup -Force
    #    Write-Host "Backup created"
  #  }

    # ===== DOWNLOAD CONFIG =====
#    $url = "https://raw.githubusercontent.com/aayushgenpact/cloud/main/config.alloy"
#    $tempFile = "$env:TEMP\config.alloy"

#    Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing

    # ===== REPLACE =====
 #   Copy-Item $tempFile $configPath -Force

    # ===== RESTART =====
#    Restart-Service alloy -Force

#    Write-Host "Alloy updated and restarted"
#}

# ===== VERIFY =====
#Start-Sleep 3
#Get-Service alloy

#Write-Host "===== Completed ====="

############################################################################################################

param (
    [string]$METRICS_URL,
    [string]$METRICS_ID,
    [string]$LOGS_URL,
    [string]$LOGS_ID,
    [string]$API_KEY
)

$alloyPath = "C:\Program Files\GrafanaLabs\Alloy"
$configPath = "$alloyPath\config.alloy"
$backup = "$configPath" + "_bak"
$serviceName = "alloy"

Write-Host "===== Alloy Deployment Started ====="

# ===== FUNCTION: WAIT FOR SERVICE =====
function Wait-ForService {
    param (
        [string]$name,
        [int]$maxRetry = 30
    )

    $retry = 0

    Write-Host "Waiting for service '$name'..."

    while ($retry -lt $maxRetry) {

        $svc = Get-Service -Name $name -ErrorAction SilentlyContinue

        if ($svc -and $svc.Status -eq "Running") {
            Write-Host "Service '$name' is running"
            return
        }

        if ($svc) {
            Write-Host "Service found but not running. Attempting start..."
            Start-Service $name -ErrorAction SilentlyContinue
        }

        Start-Sleep -Seconds 10
        $retry++
    }

    Write-Host "ERROR: Service '$name' not running after waiting"
    exit 1
}

# ===== FUNCTION: UPDATE CONFIG =====
function Update-AlloyConfig {

    Write-Host "Updating Alloy config..."

    # Backup
    if (Test-Path $configPath) {
        Copy-Item $configPath $backup -Force
        Write-Host "Backup created"
    }

    # Download config
    $url = "https://raw.githubusercontent.com/aayushgenpact/cloud/main/config.alloy"
    $tempFile = "$env:TEMP\config.alloy"

    Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing

    if (!(Test-Path $tempFile)) {
        Write-Host "ERROR: Failed to download config"
        exit 1
    }

    # Replace config
    Copy-Item $tempFile $configPath -Force

    Write-Host "Config replaced"

    # Restart service
    Restart-Service $serviceName -Force

    # Wait again after restart
    Wait-ForService -name $serviceName

    Write-Host "Config updated and service restarted"
}

# ===== MAIN LOGIC =====

if (Test-Path $alloyPath) {

    Write-Host "Alloy is already installed"

    # Ensure service is running before config update
    Wait-ForService -name $serviceName

    Update-AlloyConfig

} else {

    Write-Host "Alloy not found. Installing..."

    cd ([System.IO.Path]::GetTempPath())

    Invoke-WebRequest "https://storage.googleapis.com/cloud-onboarding/alloy/scripts/install-windows.ps1" -OutFile "install-windows.ps1"

    if (!(Test-Path "install-windows.ps1")) {
        Write-Host "ERROR: Failed to download installer"
        exit 1
    }

    # Install Alloy
    .\install-windows.ps1 `
        -GCLOUD_HOSTED_METRICS_URL $METRICS_URL `
        -GCLOUD_HOSTED_METRICS_ID $METRICS_ID `
        -GCLOUD_SCRAPE_INTERVAL "60s" `
        -GCLOUD_HOSTED_LOGS_URL $LOGS_URL `
        -GCLOUD_HOSTED_LOGS_ID $LOGS_ID `
        -GCLOUD_RW_API_KEY $API_KEY

    Write-Host "Install command executed"

    # Wait until service is fully ready
    Wait-ForService -name $serviceName

    Write-Host "Alloy installation completed"

    # Now apply config (same logic)
    Update-AlloyConfig
}

# ===== FINAL VALIDATION =====
$svc = Get-Service $serviceName -ErrorAction SilentlyContinue

if (-not $svc -or $svc.Status -ne "Running") {
    Write-Host "ERROR: Final validation failed"
    exit 1
}

Write-Host "===== Deployment Completed Successfully ====="
