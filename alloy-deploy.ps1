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

Write-Host "===== Alloy Deployment Started ====="

# ===== FUNCTION: DETECT SERVICE =====
function Get-AlloyService {
    return Get-Service | Where-Object {
        $_.Name -like "*alloy*" -or $_.DisplayName -like "*alloy*"
    } | Select-Object -First 1
}

# ===== FUNCTION: WAIT FOR SERVICE =====
function Wait-ForService {
    param ([string]$name)

    $retry = 0
    $maxRetry = 30

    while ($retry -lt $maxRetry) {

        $svc = Get-Service -Name $name -ErrorAction SilentlyContinue

        if ($svc -and $svc.Status -eq "Running") {
            Write-Host "Service '$name' is running"
            return
        }

        if ($svc) {
            Write-Host "Starting service '$name'..."
            Start-Service $name -ErrorAction SilentlyContinue
        }

        Start-Sleep -Seconds 10
        $retry++
    }

    Write-Host "ERROR: Service '$name' not running after wait"
    exit 1
}

# ===== FUNCTION: UPDATE CONFIG =====
function Update-AlloyConfig {

    Write-Host "Updating Alloy config..."

    if (Test-Path $configPath) {
        Copy-Item $configPath $backup -Force
        Write-Host "Backup created"
    }

    $url = "https://raw.githubusercontent.com/aayushgenpact/cloud/main/config.alloy"
    $tempFile = "$env:TEMP\config.alloy"

    Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing

    if (!(Test-Path $tempFile)) {
        Write-Host "ERROR: Config download failed"
        exit 1
    }

    Copy-Item $tempFile $configPath -Force

    Write-Host "Config replaced"

    $svc = Get-AlloyService

    Restart-Service $svc.Name -Force

    Wait-ForService -name $svc.Name

    Write-Host "Config updated successfully"
}

# ===== MAIN LOGIC =====

$svc = Get-AlloyService

if (-not $svc -or $svc.Status -ne "Running") {

    Write-Host "Alloy service not running. Installing/Reinstalling..."

    cd ([System.IO.Path]::GetTempPath())

    Invoke-WebRequest "https://storage.googleapis.com/cloud-onboarding/alloy/scripts/install-windows.ps1" -OutFile "install-windows.ps1"

    if (!(Test-Path "install-windows.ps1")) {
        Write-Host "ERROR: Installer download failed"
        exit 1
    }

    .\install-windows.ps1 `
        -GCLOUD_HOSTED_METRICS_URL $METRICS_URL `
        -GCLOUD_HOSTED_METRICS_ID $METRICS_ID `
        -GCLOUD_SCRAPE_INTERVAL "60s" `
        -GCLOUD_HOSTED_LOGS_URL $LOGS_URL `
        -GCLOUD_HOSTED_LOGS_ID $LOGS_ID `
        -GCLOUD_RW_API_KEY $API_KEY

    Write-Host "Install command executed"

    # Re-detect service after install
    $svc = Get-AlloyService

    if (-not $svc) {
        Write-Host "ERROR: Alloy service not created after install"
        exit 1
    }

    Wait-ForService -name $svc.Name

    Write-Host "Alloy installed successfully"
}

# ===== ALWAYS UPDATE CONFIG =====
Update-AlloyConfig

# ===== FINAL VALIDATION =====
$svc = Get-AlloyService

if (-not $svc -or $svc.Status -ne "Running") {
    Write-Host "ERROR: Final validation failed"
    exit 1
}

Write-Host "DEPLOYMENT_SUCCESS"
exit 0
