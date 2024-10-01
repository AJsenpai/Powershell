# Import the list of servers from a CSV file
$csvPath = "C:\path\to\your\servers.csv"
$servers = Import-Csv -Path $csvPath | Select-Object -ExpandProperty ServerName

# Specify the name of the service to stop, start, and check status
$serviceName = "YourServiceName"

foreach ($server in $servers) {
    try {
        Write-Host "Processing server: $server" -ForegroundColor Cyan

        # Check if the service exists on the remote server
        $service = Get-Service -ComputerName $server -Name $serviceName -ErrorAction Stop

        # Stop the service if it's running
        if ($service.Status -eq 'Running') {
            Write-Host "Stopping service '$serviceName' on $server..." -ForegroundColor Yellow
            Stop-Service -ComputerName $server -Name $serviceName -Force -ErrorAction Stop
        } else {
            Write-Host "Service '$serviceName' is not running on $server." -ForegroundColor Green
        }

        # Start the service
        Write-Host "Starting service '$serviceName' on $server..." -ForegroundColor Yellow
        Start-Service -ComputerName $server -Name $serviceName -ErrorAction Stop

        # Check and display the status of the service after restart
        $serviceStatus = Get-Service -ComputerName $server -Name $serviceName
        Write-Host "Service '$serviceName' on $server is now: $($serviceStatus.Status)" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to manage service '$serviceName' on $server. Error: $_" -ForegroundColor Red
    }
    
    Write-Host "`n-----------------------------------------------`n"
}

Write-Host "Service operation completed on all servers." -ForegroundColor Cyan
