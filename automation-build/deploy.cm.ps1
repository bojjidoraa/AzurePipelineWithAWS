$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

Import-Module "$($PSScriptRoot)\lib\DeploymentVariablesBamboo.psm1" -Force
Import-Module "$($PSScriptRoot)\lib\DeploymentVariablesServer.psm1" -Force
Import-Module "$($PSScriptRoot)\lib\SitecorePackaging.psm1" -Force
Import-Module "$($PSScriptRoot)\lib\WebsiteDeployment.psm1" -Force

function Start-DeployCM {
    
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

        Get-SitecoreContentManagementPackage `
        -preparedWebsiteDirectory "$($PSScriptRoot)\temp\deploy\website\" `
        -transformedConfigDirectory "$($PSScriptRoot)\temp\transformed-config\cm\" `
        -patchConfigDirectory "$($PSScriptRoot)\temp\patch-config\cm\" `
        -serialisationDirectory "$($PSScriptRoot)\temp\serial\" `
        -outputDirectory "$($PSScriptRoot)\ready\cm\"

        New-DeploymentTask `
        -deploymentPackage "$($PSScriptRoot)\ready\cm\cm.zip" `
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

            New-SerialisationDirectory

            Move-SerialisationToDirectory
            
            Set-SerialisationDirectoryPermissions

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