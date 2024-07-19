$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

Import-Module "$($PSScriptRoot)\lib\ClientSideBuild.psm1" -Force

# Build client-side assets.

Publish-ClientSideAssets `
-clientSideDirectory "$($PSScriptRoot)\..\src\Foundation\Client\Website\assets" 