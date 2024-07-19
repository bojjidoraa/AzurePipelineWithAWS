$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

Import-Module "$($PSScriptRoot)\DeploymentVariables.psm1" -Force

function Get-ServerDetailsFromBambooVariables {

    [CmdLetBinding()]
    param(

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]        
        [string]        
        $serverIdentifier
    )

    begin {
        # Intentionally empty.        
    }

    process {
        
        Write-Host "Gathering server details."

        Write-Verbose "Server identifier: $($serverIdentifier)"
        
        $ServerVariables = [PSCustomObject]@{
            WebsiteName  = Get-BambooVariable -variableName "SERVER_$($serverIdentifier)_WEBSITE_NAME"
            ApplicationPoolName = Get-BambooVariable -variableName "server_$($serverIdentifier)_APPLICATION_POOL_NAME"
            WorkingDirectoryRoot = Get-BambooVariable -variableName "SERVER_$($serverIdentifier)_WORKING_DIRECTORY_ROOT"
            WebsiteDirectoryRoot = Get-BambooVariable -variableName "SERVER_$($serverIdentifier)_WEBSITE_DIRECTORY_ROOT"
            SerialisationDirectoryRoot = Get-BambooVariable -variableName "SERVER_$($serverIdentifier)_SERIALISATION_DIRECTORY_ROOT"
            VanillaInstallArchivePath = Get-BambooVariable -variableName "SERVER_$($serverIdentifier)_VANILLA_INSTALL_ARCHIVE_PATH"
            WarmupUrls = Get-BambooVariable -variableName "SERVER_$($serverIdentifier)_WARMUP_URLS"
            Domain = Get-BambooVariable -variableName "SERVER_$($serverIdentifier)_DOMAIN"
            Host = Get-BambooVariable -variableName "SERVER_$($serverIdentifier)_HOST"
            Username = Get-BambooVariable -variableName "SERVER_$($serverIdentifier)_USERNAME"
            Password = ConvertTo-SecureString -AsPlainText -Force -String (Get-BambooVariable -variableName "SERVER_$($serverIdentifier)_PASSWORD")
            Secure = [System.Convert]::ToBoolean($(Get-BambooVariable -variableName "SERVER_$($serverIdentifier)_SECURE"))
        }

        Write-Verbose "Server details gathered."

        return $ServerVariables
    }

    end {
        # Intentionally empty.
    }
}

Export-ModuleMember -Function Get-ServerDetailsFromBambooVariables