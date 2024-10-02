# Path to the CSV file containing server names
$csvPath = "C:\Path\To\Your\servers.csv"

# Specify the name of the service to stop, start, and check status
$serviceName = "YourServiceName"

# Import the CSV file and get the list of servers
$servers = Import-Csv -Path $csvPath

# Define the time range for fetching recent error logs (in hours)
$logTimeRangeHours = 24

foreach ($server in $servers) {
    $serverName = $server.ServerName

    try {
        Write-Host "Processing server: $serverName" -ForegroundColor Cyan

        # Invoke-Command to run commands on the remote server
        Invoke-Command -ComputerName $serverName -ScriptBlock {
            param ($serviceName, $logTimeRangeHours)

            # Try to retrieve the service on the remote server
            try {
                $service = Get-Service -Name $serviceName -ErrorAction Stop

                # If the service is running, stop it
                if ($service.Status -eq 'Running') {
                    Write-Host "Stopping service '$serviceName' on $env:COMPUTERNAME..." -ForegroundColor Yellow
                    Stop-Service -Name $serviceName -Force -ErrorAction Stop
                } else {
                    Write-Host "Service '$serviceName' is not running on $env:COMPUTERNAME." -ForegroundColor Green
                }

                # Start the service again
                Write-Host "Starting service '$serviceName' on $env:COMPUTERNAME..." -ForegroundColor Yellow
                Start-Service -Name $serviceName -ErrorAction Stop

                # Check and display the service status
                $serviceStatus = Get-Service -Name $serviceName
                Write-Host "Service '$serviceName' on $env:COMPUTERNAME is now: $($serviceStatus.Status)" -ForegroundColor Green
            }
            catch {
                Write-Host "Error managing service '$serviceName' on $env:COMPUTERNAME. Error: $_" -ForegroundColor Red

                # Query recent error events related to the service from the Event Viewer (System and Application logs)
                Write-Host "Fetching recent error events related to '$serviceName' from Event Viewer..." -ForegroundColor Cyan

                $timeFilter = (Get-Date).AddHours(-$logTimeRangeHours)

                # Get recent error events related to the service from the System log
                $errorEvents = Get-WinEvent -FilterHashtable @{
                    LogName   = 'System';
                    Level     = 2;  # Error level
                    StartTime = $timeFilter
                } | Where-Object { $_.Message -like "*$serviceName*" }

                # Check if there are any error events found
                if ($errorEvents) {
                    Write-Host "Error events related to '$serviceName' found in the Event Viewer:" -ForegroundColor Yellow
                    foreach ($event in $errorEvents) {
                        Write-Host "Time: $($event.TimeCreated), Message: $($event.Message)" -ForegroundColor Red
                    }
                } else {
                    Write-Host "No recent error events found for '$serviceName' in the Event Viewer within the last $logTimeRangeHours hours." -ForegroundColor Green
                }
            }

        } -ArgumentList $serviceName, $logTimeRangeHours
    }
    catch {
        Write-Host "Failed to connect to $serverName. Error: $_" -ForegroundColor Red
    }

    Write-Host "`n-----------------------------------------------`n"
}

Write-Host "Service operation completed on all servers." -ForegroundColor Cyan
