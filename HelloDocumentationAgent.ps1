<#
.SYNOPSIS
    Hello Documentation Agent - A trivial PowerShell script used to demonstrate
    Copilot Coding Agent as an automatic documentation writer.

.DESCRIPTION
    Every time a developer commits changes, the GitHub Actions workflow stamps
    this script with the current build number and then triggers the Copilot
    Coding Agent to document the changes in docs/CHANGELOG.md.

.NOTES
    Version is automatically updated by CI. Do not edit the $Version line manually.
#>

$Version = "1.0.0.9"

function Get-Greeting {
    param(
        [string]$Name = "World"
    )
    return "Hello, $Name! I am the Documentation Agent v$Version"
}

function Get-CurrentTimestamp {
    return (Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
}

# --- Main ---
$greeting = Get-Greeting
$timestamp = Get-CurrentTimestamp

Write-Host $greeting
Write-Host "Timestamp : $timestamp"
Write-Host "Build Ver : $Version"
