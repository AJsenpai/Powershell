# Ensure CF CLI is installed and logged in
if (-not (Get-Command "cf" -ErrorAction SilentlyContinue)) {
    Write-Host "CF CLI not installed. Please install it first."
    exit
}

# Define the log file path
$logFilePath = "C:/tmp/pcf-restage-log.txt"

# Function to log events to the log file with timestamp
function Log-Event {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    
    # Append to the log file
    Add-Content -Path $logFilePath -Value $logMessage
}

# Function to get the latest version of an app based on the highest numeric suffix
function Get-LatestAppVersion {
    param (
        [string[]]$appList
    )
    
    # Regex to match app names ending with a number (e.g., AppName__12)
    $regex = "^(.*)__([0-9]+)$"
    
    # Filter the apps that match the pattern and extract the numeric suffix
    $appsWithVersion = @()

    foreach ($app in $appList) {
        if ($app -match $regex) {
            $baseName = $matches[1]
            $version = [int]$matches[2]
            $appsWithVersion += [PSCustomObject]@{
                AppName  = $app
                BaseName = $baseName
                Version  = $version
            }
        }
    }

    if ($appsWithVersion.Count -eq 0) {
        Write-Host "No apps found with numeric suffix."
        Log-Event "No apps found with numeric suffix in space."
        return $null
    }

    # Group by base name and select the app with the highest version number
    $latestApps = $appsWithVersion | Group-Object -Property BaseName | ForEach-Object {
        $_.Group | Sort-Object -Property Version -Descending | Select-Object -First 1
    }

    return $latestApps
}

# List to store apps that have already been restaged
$restagedApps = @()

# Define the space name pattern to filter (any space starting with "qa-")
$targetSpacePattern = "qa-*"

# Get the list of all orgs
$orgs = cf orgs | Select-Object -Skip 3 # Skip the first 3 lines (headers and extra text)

foreach ($org in $orgs) {
    Write-Host "Switching to Org: $org"
    Log-Event "Switching to Org: $org"
    cf target -o $org

    # Get the list of spaces in the org
    $spaces = cf spaces | Select-Object -Skip 3

    foreach ($space in $spaces) {
        # Check if the space name starts with "qa-"
        if ($space -notlike $targetSpacePattern) {
            continue # Skip spaces that don't match the pattern
        }

        Write-Host "Switching to Space: $space"
        Log-Event "Switching to Space: $space"
        cf target -s $space

        # Get the list of apps in the space
        $apps = cf apps | Select-Object -Skip 4 # Skip the first 4 lines (headers and extra text)

        # Restage any app that is already running
        foreach ($app in $apps) {
            # Check the app state
            $appDetails = cf app $app
            if ($appDetails -match "state:\s+RUNNING") {
                if ($restagedApps -notcontains $app) {
                    Write-Host "Restaging running app: $app"
                    Log-Event "Restaging running app: $app"
                    cf restage $app
                    $restagedApps += $app # Add to the list of restaged apps
                }
            }
        }

        # Find the latest version for each app group
        $latestApps = Get-LatestAppVersion -appList $apps

        if ($latestApps) {
            foreach ($app in $latestApps) {
                # Skip restaging if the app was already restaged in the "running app" check
                if ($restagedApps -notcontains $app.AppName) {
                    Write-Host "Restaging latest app version: $($app.AppName)"
                    Log-Event "Restaging latest app version: $($app.AppName)"
                    cf restage $app.AppName
                } else {
                    Write-Host "App $($app.AppName) was already restaged as running. Skipping restage."
                    Log-Event "App $($app.AppName) was already restaged as running. Skipping restage."
                }
            }
        }
    }
}

Write-Host "Script execution completed. Logs saved to $logFilePath"
Log-Event "Script execution completed."
