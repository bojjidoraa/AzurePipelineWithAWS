$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

Import-Module "$($PSScriptRoot)\lib\DeploymentVariablesBamboo.psm1" -Force
Import-Module "$($PSScriptRoot)\lib\DeploymentVariablesServer.psm1" -Force
Import-Module "$($PSScriptRoot)\lib\SitecorePackaging.psm1" -Force
Import-Module "$($PSScriptRoot)\lib\WebsiteDeployment.psm1" -Force

function Start-DeployCD {
    
    param (
    
        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]        
        [string]
        $serverIdentifier
    )

    process {

        $serverVariables = Get-ServerDetailsFromBambooVariables `
        -serverIdentifier $serverIdentifier

        $deployRelease = Get-DeployReleaseBambooVariable

        Get-SitecoreContentDeliveryPackage `
        -preparedWebsiteDirectory "$($PSScriptRoot)\temp\deploy\website\" `
        -transformedConfigDirectory "$($PSScriptRoot)\temp\transformed-config\cd\" `
        -patchConfigDirectory "$($PSScriptRoot)\temp\patch-config\cd\" `
        -outputDirectory "$($PSScriptRoot)\ready\cd\"

        New-DeploymentTask `
        -deploymentPackage "$($PSScriptRoot)\ready\cd\cd.zip" `
        -serverVariables $serverVariables `
        -deployRelease $deployRelease

        try
        {
            New-DeploymentSession

            Add-WorkingDirectory

            Send-DeploymentPackage
            
            New-WebsiteDirectory

            Expand-VanillaInstallation

            Move-VanillaInstallToDirectory

            Expand-DeploymentPackage

            Move-WebsiteDeploymentToDirectory
            
            Set-WebsiteDirectoryPermissions

            Stop-Website

            Wait-ForHealthCheck

            Set-WebsiteDirectory
            
            Start-Website

            Request-WarmupUrls

            Wait-ForHealthCheck
        }
        catch
        {
            Write-Host "Error during deployment task."

            throw $_
        }
        finally
        {
            Remove-DeploymentSession
        }
    }
}