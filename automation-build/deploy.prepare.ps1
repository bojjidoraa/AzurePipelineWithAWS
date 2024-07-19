$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

Import-Module "$($PSScriptRoot)\lib\SitecoreSettings.psm1" -Force
Import-Module "$($PSScriptRoot)\lib\WebsiteDeployment.psm1" -Force
Import-Module "$($PSScriptRoot)\lib\DeploymentVariablesBamboo.psm1" -Force
Import-Module "$($PSScriptRoot)\lib\DeploymentVariablesServer.psm1" -Force

function Start-DeployPrepare {
    
    process {

        $contentManagementServerIdentifier = "CM"

        $contentManagementServerVariables = Get-ServerDetailsFromBambooVariables `
        -serverIdentifier $contentManagementServerIdentifier

        $deployRelease = Get-DeployReleaseBambooVariable

        $tokenAndValueOverrides = @{ 
            UNICORN_ITEM_SYNC_LOCATION = [IO.Path]::Combine($contentManagementServerVariables.SerialisationDirectoryRoot, "serialisation-$($deployRelease)");   
        }

        Update-EnvironmentVariableTokensWithBambooValues `
        -configDirectory "$($PSScriptRoot)\temp\deploy\website\" `
        -tokenAndValueOverrides $tokenAndValueOverrides

        Update-EnvironmentVariableTokensWithBambooValues `
        -configDirectory "$($PSScriptRoot)\temp\transformed-config\" `
        -tokenAndValueOverrides $tokenAndValueOverrides
		
		Update-EnvironmentVariableTokensWithBambooValues `
        -configDirectory "$($PSScriptRoot)\temp\patch-config\" `
        -tokenAndValueOverrides $tokenAndValueOverrides
    }
}