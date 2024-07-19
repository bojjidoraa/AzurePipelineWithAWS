$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

function Copy-Serialisation {

    [CmdLetBinding()]
    param(   

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]
        $solutionRootDirectory,

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [string]
        $outputDirectory
    )

    begin {
        # Intentionally empty.        
    }

    process {
        
        Write-Host "Copying all serialised data from the solution."

        Write-Verbose "Solution path: $($solutionRootDirectory)"        

        if (Test-Path $outputDirectory)
        { 
            Remove-Item $outputDirectory -Force -Recurse -ErrorAction Stop
        };

        Invoke-Expression "robocopy '$($solutionRootDirectory)' '$($outputDirectory)' /s /ndl /njh /njs *.yml"

        Write-Verbose "Completed copying serialisation."
    }

    end {
        # Intentionally empty.        
    }
}
function Remove-DevelopmentSerialisation {    

    [CmdLetBinding()]
    param(     

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]
        $serialisationDirectory
    )

    begin {
        # Intentionally empty.        
    }

    process {
                
        Write-Information "Removing development specific serialisation from the copied serialisation artefacts."        

        Remove-Item "$($serialisationDirectory)\Project\Circle\serialization\content" -Force -Recurse -ErrorAction Stop

        Remove-Item "$($serialisationDirectory)\Project\Circle\serialization\media" -Force -Recurse -ErrorAction Stop

        Remove-Item "$($serialisationDirectory)\Foundation\SitecoreForms\serialization\content" -Force -Recurse -ErrorAction Stop        

        Write-Verbose "Completed removing development serialisation."
    }

    end {
        # Intentionally empty.
    }
}

Export-ModuleMember -Function Copy-Serialisation
Export-ModuleMember -Function Remove-DevelopmentSerialisation