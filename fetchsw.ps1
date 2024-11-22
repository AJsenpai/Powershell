# Define variables
$ServerList = @("Server1", "Server2", "Server3") # Replace with your server names
$Credential = Get-Credential # Prompt for credentials to access remote servers
$OutputFile = "C:\Temp\ServerDetails.xlsx" # Path for the output Excel file

# Initialize an array to store the output
$Results = @()

# Loop through each server
foreach ($Server in $ServerList) {
    try {
        Write-Host "Processing server: $Server" -ForegroundColor Cyan

        # Fetch OS details
        $OSDetails = Invoke-Command -ComputerName $Server -Credential $Credential -ScriptBlock {
            Get-WmiObject -Class Win32_OperatingSystem | Select-Object Caption, Version, OSArchitecture
        }

        # Fetch IBM MQ Version (if installed)
        $MQVersion = Invoke-Command -ComputerName $Server -Credential $Credential -ScriptBlock {
            try {
                # Registry path for IBM MQ
                $RegistryPath = "HKLM:\SOFTWARE\IBM\WebSphere MQ"
                if (Test-Path $RegistryPath) {
                    Get-ItemProperty -Path $RegistryPath | Select-Object -ExpandProperty Version
                } else {
                    "Not Installed"
                }
            } catch {
                "Error Fetching MQ Version"
            }
        }

        # Prepare result object
        $Result = [PSCustomObject]@{
            ServerName = $Server
            OSName     = $OSDetails.Caption
            OSVersion  = $OSDetails.Version
            OSArch     = $OSDetails.OSArchitecture
            MQVersion  = $MQVersion
        }

        # Add result to the results array
        $Results += $Result
    } catch {
        Write-Host "Failed to process $Server: $_" -ForegroundColor Red
        # Log failed server
        $Results += [PSCustomObject]@{
            ServerName = $Server
            OSName     = "Error"
            OSVersion  = "Error"
            OSArch     = "Error"
            MQVersion  = "Error"
        }
    }
}

# Export results to Excel
Write-Host "Exporting results to Excel: $OutputFile" -ForegroundColor Green
$Results | Export-Excel -Path $OutputFile -AutoSize -Title "Server OS and IBM MQ Details"

Write-Host "Script execution completed. Results saved to $OutputFile" -ForegroundColor Green
