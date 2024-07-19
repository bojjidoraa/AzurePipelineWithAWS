$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

function Test-Units {
    
    [CmdLetBinding()]
    param(       
        
        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType "Leaf"})]
        [string]
        $msbuildExecutableFilePath,

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType "Leaf"})]
        [string]
        $solutionFilePath,

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [string]
        $buildConfiguration,

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType "Container"})]
        [string]
        $visualStudioToolsDirectoryPath
    )

    begin {
        # Intentionally empty.        
    }

    process {

        Write-Host "Running unit tests."

        Write-Verbose "MSBuild executable located at: $($msbuildExecutableFilePath)"
        Write-Verbose "Visual Studio Build tools directory: $($visualStudioToolsDirectoryPath)"
        Write-Verbose "Solution located at: $($solutionFilePath)"    
        Write-Verbose "Build configuration: $($buildConfiguration)"

        Invoke-Expression "& `"$($msbuildExecutableFilePath)`" `"$($solutionFilePath)`" /p:Configuration=$($buildConfiguration) -maxcpucount:2"

        if ($lastExitCode -eq "1")
        {
            throw "MSBuild failed."
        }

        [Environment]::SetEnvironmentVariable("VSToolsPath", $visualStudioToolsDirectoryPath, "Process")

        Invoke-Expression "& dotnet test --filter Category!=Manual `"$($solutionFilePath)`" --no-restore --no-build --nologo --logger trx --configuration $($buildConfiguration) -- xunit.parallelizeAssembly=true"

        if ($lastExitCode -eq "1")
        {
            throw "Unit tests failed."
        }

        Write-Verbose "Completed testing units."
    }

    end {
        # Intentionally empty.        
    }
}

Export-ModuleMember -Function Test-Units