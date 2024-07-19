$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

function Update-ReleaseConfigs {
    
    [CmdLetBinding()]
    param(        

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [string]
        $publishedWebsiteDirectory
    )

    begin {
        # Intentionally empty.             
    }

    process {
        
        Write-Host "Updating config files with .release versions, where they exist."

        Write-Verbose "Website directory: $($publishedWebsiteDirectory)"

        $releaseConfigurationFiles = Get-ChildItem -Path $publishedWebsiteDirectory -Filter *.config.release -Recurse -ErrorAction SilentlyContinue -Force
                
        Write-Verbose "Release configuration files found:"

        Write-Verbose ($releaseConfigurationFiles | Out-String)

        Write-Verbose "Processing files:"

        foreach ($file in $releaseConfigurationFiles)
        {
            Write-Verbose "Processing file: $($file.FullName)"

            $matchingFileName = $file.FullName -replace '.config.release','.config'
            
            Remove-Item $matchingFileName -Force -Recurse -ErrorAction SilentlyContinue

            Rename-Item -Path $file.FullName -NewName $matchingFileName            
        }

        Write-Verbose "Completed setting release configs."
    }

    end {
        # Intentionally empty.        
    }
}

function Remove-ExtensionSegment {
    
    [CmdLetBinding()]
    param(        

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]
        $fileDirectory,

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]        
        [string]
        $extensionSegment
    )

    begin {
        # Intentionally empty.             
    }

    process {
        
        Write-Host "Removing extension segment from all matching files in directory."

        Write-Verbose "File directory: $($fileDirectory)"
        Write-Verbose "Extension segment: $($extensionSegment)"

        Get-ChildItem "$($fileDirectory)\*$($extensionSegment)" -Recurse | Rename-Item -NewName { $_.name -Replace "\$($extensionSegment)$", "" }

        Write-Verbose "Completed removing extension segment."
    }

    end {
        # Intentionally empty.        
    }
}

function Copy-PatchFilesToDirectory {
    
    [CmdLetBinding()]
    param(        

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]
        $solutionRootDirectory,

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]
        $targetConfigDirectory,    

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]        
        [string]
        $patchExtension
    )

    begin {
        # Intentionally empty.             
    }

    process {
        
        Write-Host "Copying release patch files."        
        
        Write-Verbose "Locating patch files from: $($solutionRootDirectory)"
        Write-Verbose "Copying matching patch files into: $($targetConfigDirectory)"        
        Write-Verbose "Using the following patch extension: $($patchExtension)"   

        $randomId = [guid]::NewGuid()

        $tempPatchDirectory = "$($PSScriptRoot)\temp\patches\$($randomId)"

        if (Test-Path $tempPatchDirectory)
        { 
            Remove-Item $tempPatchDirectory -Force -Recurse -ErrorAction Stop
        };

        Invoke-Expression "robocopy '$($solutionRootDirectory)' '$($tempPatchDirectory)' /s /ndl /njh /njs *$($patchExtension)"
                        
        $environmentPath = "$($tempPatchDirectory)\Environment\website"

        if (Test-Path $environmentPath) 
        { 
            Invoke-Expression "robocopy '$($environmentPath)' '$($targetConfigDirectory)' /s /ndl /njh /njs *$($patchExtension)"
        }; 

        Copy-PatchFiles -originDirectoryPath "$($tempPatchDirectory)\Foundation\" -targetDirectoryPath $targetConfigDirectory -patchExtension $patchExtension

        Copy-PatchFiles -originDirectoryPath "$($tempPatchDirectory)\Feature\" -targetDirectoryPath $targetConfigDirectory -patchExtension $patchExtension

        Copy-PatchFiles -originDirectoryPath "$($tempPatchDirectory)\Project\" -targetDirectoryPath $targetConfigDirectory -patchExtension $patchExtension
        
        if (Test-Path $tempPatchDirectory)
        { 
            Remove-Item $tempPatchDirectory -Force -Recurse -ErrorAction Stop
        };

        Write-Verbose "Completed copying release patches."
    }

    end {
        # Intentionally empty.        
    }
}

function Copy-PatchFiles
{  
    Param (

        [Parameter(Mandatory = $true)]
        [string]
        $originDirectoryPath,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ -PathType 'Container' })]
        [string]
        $targetDirectoryPath,    

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]        
        [string]
        $patchExtension
    )

    begin {
        # Intentionally empty.
    }

    process 
    {
        if (Test-Path $originDirectoryPath) 
        { 
            $originWebsitesPath = "$($originDirectoryPath)\*\website"

            Get-ChildItem $originWebsitesPath -Directory | ForEach-Object { 
                Invoke-Expression "robocopy '$($_.FullName)' '$($targetDirectoryPath)' /s /ndl /njh /njs *$($patchExtension)"
            } 
        };
    }

    end {
        # Intentionally empty.        
    }
}

Export-ModuleMember -Function Update-ReleaseConfigs
Export-ModuleMember -Function Copy-PatchFilesToDirectory
Export-ModuleMember -Function Remove-ExtensionSegment