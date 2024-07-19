$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

function Set-EnvironmentVariables {
    
    [CmdLetBinding()]
    param(        

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType "Leaf"})]
        [string]
        $environmentalVariableFile,
        
        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]        
        [bool]
        $setMachineVariable,

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]        
        [string]
        $environmentVariableRegexFilter
    )

    <#
        .SYNOPSIS
        Loads key value pairs from a .env file into environment variables.

        .DESCRIPTION
        Loads a specific .env file.
        Extracts the key value pairs.
        Adds the pairs to the PowerShell session's environment variables.
        Optionally persists the pairs to the computer's environment variable store.

        .PARAMETER environmentalVariableFile
        Specifies the .env file path.

        .PARAMETER setMachineVariable
        Instructs the script to persist environment variables to the computer store.

        .PARAMETER environmentVariableRegexFilter
        Specifies a filter to selectively import key value pairs from the .env file.
    #>

    begin {
        # Intentionally empty.        
    }

    process {

        #Requires -RunAsAdministrator        

        Write-Host "Setting environment variables."

        Write-Verbose "Environment variables stored in: $($environmentalVariableFile)"                    
        Write-Verbose "Persist environment variables to machine, as well as setting within process: $($setMachineVariable)"    
        Write-Verbose "Only process variables which match the filter: $($environmentVariableRegexFilter)"    

        Get-Content $environmentalVariableFile | Where-Object { $_ -match $environmentVariableRegexFilter } | Where-Object { $_ -match ".+=.*" } | ForEach-Object {        

            $keyAndValue = $_ -split '='

            $variableName = $keyAndValue[0]
            $variableValue = $keyAndValue[1]

            Write-Verbose "Variable found: $($variableName)"
            
            if ($null -eq $variableValue)
            {
                Write-Verbose "Variable value is null, skipping."

                continue
            }

            if ($setMachineVariable) {      
                
                # PowerShell works with a process copy of the machine variables.
                # Updating the machine variable will not reflect in the process version without restarting the process.
                # If setting the variable at the machine level also set it within the process.
                # This ensures that code yet to execute in this process has access to the same new value.

                # https://community.spiceworks.com/topic/2065327-refresh-environment-variables

                [Environment]::SetEnvironmentVariable($variableName, $variableValue,"Machine")
            }                        

            [Environment]::SetEnvironmentVariable($variableName, $variableValue,"Process")
        }                

        Get-ChildItem env: | Format-Table -Property Name

        Write-Verbose "Completed setting environment variables."
    }    

    end {
        # Intentionally empty.        
    }
}

Export-ModuleMember -Function Set-EnvironmentVariables