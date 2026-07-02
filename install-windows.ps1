# Script to install Alloy for Windows
param (
	$GCLOUD_HOSTED_METRICS_URL,
	$GCLOUD_HOSTED_METRICS_ID,
	$GCLOUD_SCRAPE_INTERVAL,
	$GCLOUD_HOSTED_LOGS_URL,
	$GCLOUD_HOSTED_LOGS_ID,
	$GCLOUD_FM_URL,
	$GCLOUD_FM_POLL_FREQUENCY,
	$GCLOUD_FM_HOSTED_ID,
	$GCLOUD_RW_API_KEY,
	$GCLOUD_FM_LOCAL_ATTRIBUTES
)

# Sets the default TLS version to 1.2 even if TLS 1.3 is available to avoid issues downloading the Alloy installer in some networks
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Setting up Alloy"

if ( -Not [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544") ) {
	Write-Host "ERROR: The script needs to be run with Administrator privileges"
	exit 1
}

$FM_ENABLED = "false"

# Check if required parameters are present
if ($GCLOUD_FM_URL -eq $null -or $GCLOUD_FM_URL -eq "") {
	if ($GCLOUD_SCRAPE_INTERVAL -eq $null -or $GCLOUD_SCRAPE_INTERVAL -eq "") {
		Write-Host "ERROR: Required argument GCLOUD_SCRAPE_INTERVAL missing"
		exit 1
	}
} else {
	$FM_ENABLED = "true"
	if ($GCLOUD_FM_POLL_FREQUENCY -eq $null -or $GCLOUD_FM_POLL_FREQUENCY -eq "") {
		Write-Host "ERROR: Required argument GCLOUD_FM_POLL_FREQUENCY missing when GCLOUD_FM_URL is set"
		exit 1
	}

	if ($GCLOUD_FM_HOSTED_ID -eq $null -or $GCLOUD_FM_HOSTED_ID -eq "") {
		Write-Host "ERROR: Required argument GCLOUD_FM_HOSTED_ID missing when GCLOUD_FM_URL is set"
		exit 1
	}	
}

if ($GCLOUD_RW_API_KEY -eq $null -or $GCLOUD_RW_API_KEY -eq "") {
	Write-Host "ERROR: Required argument GCLOUD_RW_API_KEY missing"
	exit 1
}

if ($GCLOUD_HOSTED_METRICS_URL -eq $null -or $GCLOUD_HOSTED_METRICS_URL -eq "") {
	Write-Host "ERROR: Required argument GCLOUD_HOSTED_METRICS_URL missing"
	exit 1
}

if ($GCLOUD_HOSTED_METRICS_ID -eq $null -or $GCLOUD_HOSTED_METRICS_ID -eq "") {
	Write-Host "ERROR: Required argument GCLOUD_HOSTED_METRICS_ID missing"
	exit 1
}

if ($GCLOUD_HOSTED_LOGS_URL -eq $null -or $GCLOUD_HOSTED_LOGS_URL -eq "") {
	Write-Host "ERROR: Required argument GCLOUD_HOSTED_LOGS_URL missing"
	exit 1
}

if ($GCLOUD_HOSTED_LOGS_ID -eq $null -or $GCLOUD_HOSTED_LOGS_ID -eq "") {
	Write-Host "ERROR: Required argument GCLOUD_HOSTED_LOGS_ID missing"
	exit 1
}

try {
	Write-Host "GCLOUD_HOSTED_METRICS_URL:" $GCLOUD_HOSTED_METRICS_URL
	Write-Host "GCLOUD_HOSTED_METRICS_ID:" $GCLOUD_HOSTED_METRICS_ID
	Write-Host "GCLOUD_SCRAPE_INTERVAL:" $GCLOUD_SCRAPE_INTERVAL
	Write-Host "GCLOUD_HOSTED_LOGS_URL:" $GCLOUD_HOSTED_LOGS_URL
	Write-Host "GCLOUD_HOSTED_LOGS_ID:" $GCLOUD_HOSTED_LOGS_ID
	Write-Host "GCLOUD_FM_URL:" $GCLOUD_FM_URL
	Write-Host "GCLOUD_FM_POLL_FREQUENCY:" $GCLOUD_FM_POLL_FREQUENCY
	Write-Host "GCLOUD_FM_HOSTED_ID:" $GCLOUD_FM_HOSTED_ID
	Write-Host "GCLOUD_RW_API_KEY:" $GCLOUD_RW_API_KEY

	Write-Host "Downloading Alloy Windows Installer"
	$DOWNLOAD_URL = "https://github.com/grafana/alloy/releases/latest/download/alloy-installer-windows-amd64.exe.zip"
	$OUTPUT_ZIP_FILE = ".\alloy-installer-windows-amd64.exe.zip"
	$OUTPUT_FILE = ".\alloy-installer-windows-amd64.exe"
	$WORKING_DIR = Get-Location
	Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $OUTPUT_ZIP_FILE -ErrorAction Stop
	Expand-Archive -LiteralPath $OUTPUT_ZIP_FILE -DestinationPath $WORKING_DIR.path -force -ErrorAction Stop
}
catch {
	Write-Host "ERROR: Failed to extract Alloy installer for Windows"
	Write-Error $_.Exception
	exit 1
}

# Install Alloy in silent mode
Write-Host "Installing Alloy for Windows"
$INSTALL_STDOUT_PATH = ".\install-stdout.txt"
$INSTALL_STDERR_PATH = ".\install-stderr.txt"
$INSTALL_PROC = Start-Process ".\alloy-installer-windows-amd64.exe" -ArgumentList "/S" -Wait -PassThru -RedirectStandardOutput $INSTALL_STDOUT_PATH -RedirectStandardError $INSTALL_STDERR_PATH
if ($INSTALL_PROC.ExitCode -ne 0) {
    Write-Host "ERROR: Failed to install Alloy"
    Write-Host "Alloy Install STDOUT: $(Get-Content $INSTALL_STDOUT_PATH)"
    Write-Host "Alloy Install STDERR: $(Get-Content $INSTALL_STDERR_PATH)"
    exit $INSTALL_PROC.ExitCode
}

try {
	$CONFIG_FILE = ".\config.alloy"

	if ($FM_ENABLED -eq "true") {
		Write-Host "--- Retrieving Alloy Fleet Management config"
		$CONFIG_URI = "https://storage.googleapis.com/cloud-onboarding/alloy/config/config-fm.alloy"
		
		Invoke-WebRequest -Uri $CONFIG_URI -Outfile $CONFIG_FILE -ErrorAction Stop
		$content = Get-Content $CONFIG_FILE

		$hostname = $(hostname)

		Write-Host "--- Replacing Alloy config params with arg values"
		$content = $content.Replace("{GCLOUD_FM_URL}", $GCLOUD_FM_URL)
		$content = $content.Replace("{GCLOUD_FM_COLLECTOR_ID}", $hostname)
		$content = $content.Replace("{GCLOUD_FM_POLL_FREQUENCY}", $GCLOUD_FM_POLL_FREQUENCY)
		$content = $content.Replace("{GCLOUD_FM_HOSTED_ID}", $GCLOUD_FM_HOSTED_ID)
		$content = $content.Replace("{GCLOUD_HOSTED_METRICS_URL}", $GCLOUD_HOSTED_METRICS_URL)
		$content = $content.Replace("{GCLOUD_HOSTED_METRICS_ID}", $GCLOUD_HOSTED_METRICS_ID)
		$content = $content.Replace("{GCLOUD_HOSTED_LOGS_URL}", $GCLOUD_HOSTED_LOGS_URL)
		$content = $content.Replace("{GCLOUD_HOSTED_LOGS_ID}", $GCLOUD_HOSTED_LOGS_ID)
		$content = $content.Replace("{GCLOUD_FM_LOCAL_ATTRIBUTES}", $GCLOUD_FM_LOCAL_ATTRIBUTES)
		$content | Set-Content $CONFIG_FILE

		Write-Host "Creating Alloy Fleet Management system environment variables"
		# Older versions of the self monitoring pipelines still depend on GCLOUD_FM_COLLECTOR_ID.
		# Newer versions use the virtual attribute collector ID from the config file.
		[Environment]::SetEnvironmentVariable("GCLOUD_FM_COLLECTOR_ID", $hostname, "Machine")
		[Environment]::SetEnvironmentVariable("GCLOUD_RW_API_KEY", $GCLOUD_RW_API_KEY, "Machine")
	} else {
		Write-Host "--- Retrieving Alloy config"
		$CONFIG_URI = "https://storage.googleapis.com/cloud-onboarding/alloy/config/config.alloy"
		
		Invoke-WebRequest -Uri $CONFIG_URI -Outfile $CONFIG_FILE -ErrorAction Stop
		$content = Get-Content $CONFIG_FILE

		Write-Host "--- Replacing Alloy config params with arg values"
		$content = $content.Replace("{GCLOUD_HOSTED_METRICS_URL}", $GCLOUD_HOSTED_METRICS_URL)
		$content = $content.Replace("{GCLOUD_HOSTED_METRICS_ID}", $GCLOUD_HOSTED_METRICS_ID)
		$content = $content.Replace("{GCLOUD_SCRAPE_INTERVAL}", $GCLOUD_SCRAPE_INTERVAL)
		$content = $content.Replace("{GCLOUD_HOSTED_LOGS_URL}", $GCLOUD_HOSTED_LOGS_URL)
		$content = $content.Replace("{GCLOUD_HOSTED_LOGS_ID}", $GCLOUD_HOSTED_LOGS_ID)
		$content | Set-Content $CONFIG_FILE

		Write-Host "Creating Alloy system environment variable"
		[Environment]::SetEnvironmentVariable("GCLOUD_RW_API_KEY", $GCLOUD_RW_API_KEY, "Machine")
	}

	$DEST_DIR = "C:\Program Files\GrafanaLabs\Alloy"
	Write-Host "--- Moving finalized Alloy config to $DEST_DIR\config.alloy"
	Move-Item $CONFIG_FILE "$DEST_DIR\config.alloy" -force -ErrorAction Stop
} catch {
	Write-Host "ERROR: Failed to retrieve Alloy config file"
	Write-Error $_.Exception
	exit 1
}

Write-Host "Alloy config file retrieved, configured, and installed successfully"

# Wait for service to initialize after first install
Write-Host "Wait for Alloy service to initialize"
Start-Sleep -s 5 -ErrorAction SilentlyContinue

# Restart Alloy to load new configuration
Write-Host "Restarting Alloy service"
Stop-Service "Alloy" -ErrorAction SilentlyContinue
Start-Service "Alloy" -ErrorAction SilentlyContinue

# Wait for service to startup after restart
Write-Host "Wait for Alloy service to initialize after restart"
Start-Sleep -s 10 -ErrorAction SilentlyContinue

# Show Alloy service status
Get-Service "Alloy"
