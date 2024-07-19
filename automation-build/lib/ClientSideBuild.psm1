$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

function Publish-ClientSideAssets {
    
    [CmdLetBinding()]
    param(        

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType "Container"})]
        [string]
        $clientSideDirectory
    )

    begin {
        # Intentionally empty.        
    }

    process {

        Write-Host "Running publish tasks for a client-side assets."

        Write-Verbose "Client-side solution located at: $($clientSideDirectory)"        
                
        $launchDirectory = Get-Location

        Set-Location -path $clientSideDirectory

        Invoke-Expression "& npm install"

        Invoke-Expression "& npm run build"

        if ($lastExitCode -eq "1")
        {
            throw "Client-side asset publishing failed."
        }

        Write-Verbose "Completed publishing client-side assets."

        Set-Location -path $launchDirectory
    }

    end {
        # Intentionally empty.        
    }
}

Export-ModuleMember -Function Publish-ClientSideAssets