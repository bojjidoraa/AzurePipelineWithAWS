$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

function Restore-NuGetPackages {
    
    [CmdLetBinding()]
    param(        
        
        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType "Leaf"})]
        [string]
        $solutionFilePath
    )

    begin {
        # Intentionally empty.        
    }

    process {

        Write-Host "Restoring NuGet packages."

        Write-Verbose "Solution located at: $($solutionFilePath)"

        $nugetExecutable = "$($PSScriptRoot)/bin/nuget.exe"

        Invoke-Expression "& `"$($nugetExecutable)`" restore `"$($solutionFilePath)`" -PackagesDirectory `"$($PSScriptRoot)/../../packages`""

        if ($lastExitCode -eq "1")
        {
            throw "NuGet package restore failed."
        }

        Write-Verbose "Completed restoreing NuGet packages."
    }

    end {
        # Intentionally empty.        
    }
}

Export-ModuleMember -Function Restore-NuGetPackages