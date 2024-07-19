$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

Write-Host "Clearing existing deployment files."

# Folders may not exist, do not stop on error.
Remove-Item "$($PSScriptRoot)\assets" -Recurse -ErrorAction Ignore
Remove-Item "$($PSScriptRoot)\lib" -Recurse -ErrorAction Ignore
Remove-Item "$($PSScriptRoot)\ready" -Recurse -ErrorAction Ignore
Remove-Item "$($PSScriptRoot)\temp" -Recurse -ErrorAction Ignore
Remove-Item "$($PSScriptRoot)\deploy.prepare.ps1" -Recurse -ErrorAction Ignore
Remove-Item "$($PSScriptRoot)\deploy.cm.ps1" -Recurse -ErrorAction Ignore
Remove-Item "$($PSScriptRoot)\deploy.cd.ps1" -Recurse -ErrorAction Ignore

Write-Host "Unpacking build output."

$expandArchiveArguments = "$($PSScriptRoot)\build-output.zip", "$($PSScriptRoot)"

Start-Job -ScriptBlock { 

    Expand-Archive -Path $args[0] -DestinationPath $args[1] 
    
} -ArgumentList $expandArchiveArguments | Wait-Job -Timeout 320

Write-Host "Build output unpacked."