# HelloWorld.ps1
# A simple hello world script to trigger the Copilot documentation agent.

function Say-Hello {
    param([string]$Greeting = "Hello, World!")
    Write-Host $Greeting
}

Say-Hello
Write-Host "Script executed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
