# Hello Documentation Agent
# A trivial script to demonstrate Copilot Coding Agent as an automatic documenter.
# Make any change here, push to main, and the agent will document it.

function Get-Greeting {
    param([string]$Name = "World")
    return "Hello, $Name! I am the Documentation Agent."
}

function Get-Uptime {
    $uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    return "System uptime: {0} days, {1} hours, {2} minutes" -f $uptime.Days, $uptime.Hours, $uptime.Minutes
}

Get-Greeting
Write-Host (Get-Uptime)
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
