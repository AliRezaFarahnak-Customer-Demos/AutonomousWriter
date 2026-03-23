# Hello Documentation Agent
# A trivial script to demonstrate Copilot Coding Agent as an automatic documenter.
# Make any change here, push to main, and the agent will document it.

function Get-Greeting {
    param([string]$Name = "World")
    return "Hello, $Name! I am the Documentation Agent."
}

Get-Greeting
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
