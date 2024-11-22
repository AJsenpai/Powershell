# Define the list of servers
$servers = @("Server1", "Server2", "Server3") # Replace with your server names or IPs

# Define a script block to run on each server
$scriptBlock = {
    # Run the dspmqver command and capture its output
    $dspmqverOutput = dspmqver

    # Define a hashtable to store the extracted information
    $info = @{
        Version = ""
        OS = ""
    }

    # Parse each line of the output
    foreach ($line in $dspmqverOutput) {
        if ($line -match "^Version\s+:\s+(.*)") {
            $info.Version = $matches[1].Trim()
        }
        elseif ($line -match "^O/S\s+:\s+(.*)") {
            $info.OS = $matches[1].Trim()
        }
    }

    # Return the extracted information
    [PSCustomObject]@{
        ServerName = $env:COMPUTERNAME # Capture the server name
        Version    = $info.Version
        OS         = $info.OS
    }
}

# Run the script block on each server
$results = @()
foreach ($server in $servers) {
    try {
        $output = Invoke-Command -ComputerName $server -ScriptBlock $scriptBlock -ErrorAction Stop
        $results += $output
    }
    catch {
        Write-Warning "Failed to connect to $server: $_"
        $results += [PSCustomObject]@{
            ServerName = $server
            Version    = "Error"
            OS         = "Error"
        }
    }
}

# Output the results
$results | Format-Table -AutoSize
