$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

function Get-BambooVariable {

    [CmdLetBinding()]
    param(

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]        
        [string]
        $variableName
    )

    begin {
        # Intentionally empty.        
    }

    process {
        
        Write-Host "Getting $($variableName)."

        $value = ""

        $fullVariableName = "bamboo.$($variableName)"

        Write-Verbose "Full variable name: $($fullVariableName)"

        if (Get-Variable $fullVariableName -Scope Global -ErrorAction SilentlyContinue)
        {
            Write-Verbose "Found using Get-Variable."

            $rawValue = (Get-Variable $fullVariableName -Scope Global).Value

            $processedValue = Remove-EmptyToken $rawValue

            return $processedValue
        }

        $fullVariableName = "bamboo_$($variableName)"

        Write-Verbose "Full variable name: $($fullVariableName)"

        if (Get-Variable $fullVariableName -Scope Global -ErrorAction SilentlyContinue)
        {
            Write-Verbose "Found using Get-Variable."

            $rawValue = (Get-Variable $fullVariableName -Scope Global).Value

            $processedValue = Remove-EmptyToken $rawValue

            return $processedValue
        }
        
        $fullVariablePath = "env:\bamboo_$($variableName)"    

        Write-Verbose "Full variable path: $($fullVariablePath)"

        if (Test-Path $fullVariablePath) { 

            Write-Verbose "Found using Test-Path."

            $rawValue = (Get-Childitem -Path $fullVariablePath).Value

            $processedValue = Remove-EmptyToken $rawValue

            return $processedValue
        }  

        Write-Verbose "Not found."
    }

    end {
        # Intentionally empty.        
    }
}

function Remove-EmptyToken {

    [CmdLetBinding()]
    param(

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]        
        [string]
        $variableValue
    )

    begin {
        # Intentionally empty.        
    }

    process {
        
        Write-Verbose "Checking for empty token."

        if ($variableValue.Trim() -Eq "[EMPTY]") {

            Write-Verbose "[EMPTY] token found, returning empty string."

            return ""
        
        } else {    
            
            Write-Verbose "[EMPTY] token not found, returning value as passed."    

            return $variableValue
        }
    }

    end {
        # Intentionally empty.        
    }
}

Export-ModuleMember -Function Remove-EmptyToken
Export-ModuleMember -Function Get-BambooVariable