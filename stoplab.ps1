# This is scheduled in Task Scheduler. It will run every 20 minutes
# and check for inactivity. It compares the RX and TX packets
# from 20 minutes ago to detect if they significantly increased.
# If they haven’t, it will force the system to sleep.

$dir = "C:\labasservice\networkusage"
if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir | Out-Null
}

$log = Join-Path $dir "log"

# Get Interface
$networkadapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
$interface = $networkadapter | Get-NetAdapterStatistics

# Extract the RX/TX packages
$rx = $interface.ReceivedBytes
$tx = $interface.SentBytes

# Write Date to log
Get-Date | Out-File $log -Append
"Current Values" | Out-File $log -Append
"rx: $rx" | Out-File $log -Append
"tx: $tx" | Out-File $log -Append

# Check if RX/TX Files Exist
if ( (Test-Path -Path "$dir\rx") -or (Test-Path -Path "$dir\tx") ) {
    $p_rx = Get-Content (Join-Path $dir "rx") # store previous rx value in p_rx
    $p_tx = Get-Content (Join-Path $dir "tx") # store previous tx value in p_tx

    "Previous Values" | Out-File $log -Append
    "p_rx: $p_rx" | Out-File $log -Append
    "p_tx: $p_tx" | Out-File $log -Append

    "$rx" | Out-File (Join-Path $dir "rx") # Write packets to RX file
    "$tx" | Out-File (Join-Path $dir "tx") # Write packets to TX file

    # Calculate threshold limit
    $t_rx = [int]$p_rx + 1000
    $t_tx = [int]$p_tx + 1000

    "Threshold Values" | Out-File $log -Append
    "t_rx: $t_rx" | Out-File $log -Append
    "t_tx: $t_tx" | Out-File $log -Append

    if ($rx -le $t_rx -or $tx -le $t_tx) { # If network packets have not changed that much
        "Shutting down" | Out-File $log -Append
        " " | Out-File $log -Append
        Remove-Item (Join-Path $dir "rx")
        Remove-Item (Join-Path $dir "tx")
        "No Network Activity so stopping the instance" | Out-File $log -Append
        powershell.exe C:\labasservice\stoplab.ps1
    } else {
		"Network Activity is FINE in the instance" | Out-File $log -Append
	}
} else { # Check if RX/TX Files Doesn’t Exist
    "$rx" | Out-File (Join-Path $dir "rx") # Write packets to file
    "$tx" | Out-File (Join-Path $dir "tx")
    "Network Activity available" | Out-File $log -Append
}
