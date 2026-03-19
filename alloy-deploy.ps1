param(
    [string]$GCLOUD_RW_API_KEY
)

Write-Host '----- Alloy Deployment Started -----'

$service = Get-Service alloy -ErrorAction SilentlyContinue

if (-not $service) {

    Write-Host 'Alloy not installed. Installing...'

    cd ([System.IO.Path]::GetTempPath())

    Invoke-WebRequest 'https://storage.googleapis.com/cloud-onboarding/alloy/scripts/install-windows.ps1' -OutFile 'install-windows.ps1'

    .\install-windows.ps1 `
        -GCLOUD_HOSTED_METRICS_URL 'https://prometheus-us-central2.grafana.net/api/prom/push' `
        -GCLOUD_HOSTED_METRICS_ID '1653345' `
        -GCLOUD_SCRAPE_INTERVAL '60s' `
        -GCLOUD_HOSTED_LOGS_URL 'https://logs-prod-us-central2.grafana.net/loki/api/v1/push' `
        -GCLOUD_HOSTED_LOGS_ID '926596' `
        -GCLOUD_RW_API_KEY $GCLOUD_RW_API_KEY

    Write-Host 'Alloy installation completed.'
}
else {
    Write-Host 'Alloy already installed.'
}

\$configPath='C:\Program Files\GrafanaLabs\Alloy\config.alloy'
\$backupPath='C:\Program Files\GrafanaLabs\Alloy\config.alloy.bak'
\$alloyExe='C:\Program Files\GrafanaLabs\Alloy\alloy.exe'

Write-Host 'Backing up config...'

if(Test-Path \$configPath){
    Copy-Item \$configPath \$backupPath -Force
}

Write-Host 'Downloading config...'

Invoke-WebRequest 'https://raw.githubusercontent.com/aayushgenpact/cloud/main/config.alloy' -OutFile \$configPath

Write-Host 'Validating config...'

& \$alloyExe validate \$configPath

if(\$LASTEXITCODE -ne 0){
    Write-Host 'Validation failed. Restoring backup...'
    Copy-Item \$backupPath \$configPath -Force
    exit 1
}

Write-Host 'Restarting Alloy...'

Restart-Service alloy -Force

Write-Host 'Alloy deployment completed successfully.'

Write-Host '----- Alloy Deployment Finished -----'
