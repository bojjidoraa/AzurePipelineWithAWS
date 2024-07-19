$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

Import-Module "$($PSScriptRoot)\DeploymentVariables.psm1" -Force

# https://confluence.atlassian.com/bamboo/bamboo-variables-289277087.html#Bamboovariables-Deploymentvariables

function Get-DeployReleaseBambooVariable {

    [CmdLetBinding()]
    param()

    begin {
        # Intentionally empty.
    }

    process {
        
        Write-Host "Getting deploy release value."

        $deployReleaseVariableName = "deployRelease"

        if (Get-Variable -Name $deployReleaseVariableName -Scope Global -ErrorAction SilentlyContinue)
        {
            $existingValue = Get-Variable -Name $deployReleaseVariableName -Scope Global -ValueOnly

            Write-Verbose "Existing value found: $($existingValue)"

            return $existingValue
        }

        $dateTimeStamp = Get-Date -Format "yyddMMHHmm"

        $deployRelease = Get-BambooVariable -variableName "deploy_release"     

        Set-Variable -Name $deployReleaseVariableName -Scope Global -Value "$($deployRelease)-$($dateTimeStamp)"    

        $newValue = Get-Variable -Name $deployReleaseVariableName -Scope Global -ValueOnly

        Write-Verbose "New value Created: $($newValue)"

        return $newValue
    }

    end {
        # Intentionally empty.
    }
}

Export-ModuleMember -Function Get-DeployReleaseBambooVariable