function Get-PCFAppStats {
    param (
        [string]$AppName
    )

    # Ensure cf CLI is installed and user is logged in
    if (-not (Get-Command "cf" -ErrorAction SilentlyContinue)) {
        Write-Error "cf CLI is not installed or not found in PATH."
        return
    }

    # Fetch app stats using cf CLI
    $appStats = cf app $AppName --guid | ForEach-Object { cf curl "/v3/apps/$_/processes/web/stats" }
    if ($appStats -eq $null) {
        Write-Error "Failed to retrieve app stats. Ensure the app name is correct and you are logged in to the correct org/space."
        return
    }

    # Parse JSON output
    $appData = $appStats | ConvertFrom-Json

    # Collect required data
    $appSummary = [pscustomobject]@{
        "AppName"       = $AppName
        "State"         = $appData[0].state
        "RunningSince"  = $appData[0].uptime
        "CPU%"          = [math]::Round($appData[0].usage.cpu * 100, 2)
        "MemoryMB"      = [math]::Round($appData[0].usage.mem / 1MB, 2)
        "DiskMB"        = [math]::Round($appData[0].usage.disk / 1MB, 2)
    }

    # Output app summary
    return $appSummary
}

# Example usage
$AppName = "your-app-name"
$appInfo = Get-PCFAppStats -AppName $AppName
$appInfo | Format-Table -AutoSize
