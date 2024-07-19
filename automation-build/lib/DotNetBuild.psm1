$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

function Publish-Solution {
    
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
        [ValidateScript({Test-Path $_ -PathType "Leaf"})]
        [string]
        $environmentProjectFilePath,

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [string]
        $buildConfiguration,

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [string]
        $publishProfile
    )

    begin {
        # Intentionally empty.        
    }

    process {

        # https://slai.github.io/posts/powershell-and-external-commands-done-right/

        Write-Host "Publishing the .NET solution."

        Write-Verbose "MSBuild executable located at: $($msbuildExecutableFilePath)"
        Write-Verbose "Solution located at: $($solutionFilePath)"
        Write-Verbose "Environment project located at: $($environmentProjectFilePath)"    
        Write-Verbose "Build configuration: $($buildConfiguration)"
        Write-Verbose "Publish profile: $($publishProfile)"

        Invoke-Expression "& `"$($msbuildExecutableFilePath)`" `"$($environmentProjectFilePath)`" /p:Configuration=$($buildConfiguration) /p:DeployOnBuild=True /p:PublishProfile=$($publishProfile) -maxcpucount:2"

        if ($lastExitCode -eq "1")
        {
            throw "MSBuild publishing failed."
        }

        Write-Verbose "Completed publishing the .NET solution."
    }

    end {
        # Intentionally empty.        
    }
}

Export-ModuleMember -Function Publish-Solution