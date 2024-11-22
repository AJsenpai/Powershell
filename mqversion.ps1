# Define the list of Windows servers
$servers = @("Server1", "Server2", "Server3") # Replace with your server names

# Output file to save the results
$outputFile = "C:\Temp\MQ_Version_Report.csv"

# Initialize the output array
$results = @()

# Iterate through each server
foreach ($server in $servers) {
    try {
        # Test connectivity to the server
        if (Test-Connection -ComputerName $server -Count 1 -Quiet) {
            Write-Host "Connecting to $server..."

            # Get the OS version
            $osVersion = Invoke-Command -ComputerName $server -ScriptBlock {
                (Get-CimInstance Win32_OperatingSystem).Caption
            } -ErrorAction Stop

            # Get the MQ version using dspmqver
            $mqVersion = Invoke-Command -ComputerName $server -ScriptBlock {
                dspmqver | Select-String -Pattern "Version"
            } -ErrorAction Stop

            # Parse the MQ version from dspmqver output
            $mqVersion = $mqVersion -replace ".*Version:\s*", ""

            # Append results to the array
            $results += [PSCustomObject]@{
                ServerName = $server
                OSVersion  = $osVersion
                MQVersion  = $mqVersion
            }
        } else {
            Write-Host "Unable to reach $server." -ForegroundColor Yellow
            $results += [PSCustomObject]@{
                ServerName = $server
                OSVersion  = "N/A"
                MQVersion  = "N/A"
            }
        }
    } catch {
        Write-Host "Error connecting to $server: $_" -ForegroundColor Red
        $results += [PSCustomObject]@{
            ServerName = $server
            OSVersion  = "Error"
            MQVersion  = "Error"
        }
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8

Write-Host "Report saved to $outputFile"
