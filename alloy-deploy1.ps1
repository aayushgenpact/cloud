param (
    [string]$METRICS_URL,
    [string]$METRICS_ID,
    [string]$LOGS_URL,
    [string]$LOGS_ID,
    [string]$API_KEY,
    [string]$ENVIRONMENT = "prod"
)
# ===== FUNCTION: SET ENVIRONMENT VARIABLES =====
function Set-AlloyEnvironmentVariables {

    Write-Host "Setting Alloy environment variables..."

    [Environment]::SetEnvironmentVariable(
        "PROMETHEUS_CONNECTOR_URL",
        $METRICS_URL,
        "Machine"
    )

    [Environment]::SetEnvironmentVariable(
        "PROMETHEUS_CONNECTOR_USERNAME",
        $METRICS_ID,
        "Machine"
    )

    [Environment]::SetEnvironmentVariable(
        "PROMETHEUS_CONNECTOR_PASSWORD",
        $API_KEY,
        "Machine"
    )

    [Environment]::SetEnvironmentVariable(
        "LOKI_CONNECTOR_URL",
        $LOGS_URL,
        "Machine"
    )

    [Environment]::SetEnvironmentVariable(
        "LOKI_CONNECTOR_USERNAME",
        $LOGS_ID,
        "Machine"
    )

    [Environment]::SetEnvironmentVariable(
        "LOKI_CONNECTOR_PASSWORD",
        $API_KEY,
        "Machine"
    )

    [Environment]::SetEnvironmentVariable(
        "ENVIRONMENT",
        $ENVIRONMENT,
        "Machine"
    )

    $requiredVars = @(
        "PROMETHEUS_CONNECTOR_URL",
        "PROMETHEUS_CONNECTOR_USERNAME",
        "PROMETHEUS_CONNECTOR_PASSWORD",
        "LOKI_CONNECTOR_URL",
        "LOKI_CONNECTOR_USERNAME",
        "LOKI_CONNECTOR_PASSWORD",
        "ENVIRONMENT"
    )

    foreach ($var in $requiredVars) {

        $value = [Environment]::GetEnvironmentVariable($var, "Machine")

        if ([string]::IsNullOrWhiteSpace($value)) {
            Write-Host "ERROR: Missing environment variable $var"
            exit 1
        }

        Write-Host "FOUND: $var"
    }

    Write-Host "Environment variables configured successfully"
}
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

    Set-AlloyEnvironmentVariables

    $svc = Get-AlloyService

    Restart-Service $svc.Name -Force

    Wait-ForService -name $svc.Name

    Write-Host "Config updated successfully"
}
# ===== MAIN LOGIC =====

$svc = Get-AlloyService

# Alloy not installed
if (-not $svc) {

    Write-Host "Alloy service not found. Installing..."

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

    $svc = Get-AlloyService

    if (-not $svc) {
        Write-Host "ERROR: Alloy service not created after install"
        exit 1
    }

    Wait-ForService -name $svc.Name

    Write-Host "Alloy installed successfully"
}
elseif ($svc.Status -ne "Running") {

    Write-Host "Alloy service exists but is stopped. Starting service..."

    Start-Service $svc.Name

    Wait-ForService -name $svc.Name

    Write-Host "Alloy service started successfully"
}
else {

    Write-Host "Alloy service already running"
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
