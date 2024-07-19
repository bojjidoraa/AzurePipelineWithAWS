$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

function Get-SitecoreBuildArtefacts {
    
    [CmdLetBinding()]
    param(        

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]
        $inputDirectory,
        
        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [string]
        $outputDirectory,
        
        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [string]
        $artefactName
    )

    begin {
        # Intentionally empty.
    }

    process {

        Write-Host "Building the Sitecore build output artefacts."

        $buildArtefactTempDirectory = "$($PSScriptRoot)/../zip"

        if (Test-Path $buildArtefactTempDirectory)
        { 
            Remove-Item $buildArtefactTempDirectory -Force -Recurse -ErrorAction Stop
        }
        
        New-Item -ItemType "directory" -Path $buildArtefactTempDirectory        

        if (-Not (Test-Path $outputDirectory))
        { 
            New-Item -ItemType "directory" -Path $outputDirectory
        }

        $artefactFilePath = "$($outputDirectory)/$($artefactName).zip"

        if (Test-Path $artefactFilePath)
        { 
            Remove-Item $artefactFilePath -Force -ErrorAction Stop
        }

        Copy-Item -Path "$($inputDirectory)/lib" -Destination $buildArtefactTempDirectory -Recurse -Container:$true

        Copy-Item -Path "$($inputDirectory)/assets" -Destination $buildArtefactTempDirectory -Recurse -Container:$true

        Copy-Item -Path "$($inputDirectory)/temp" -Destination $buildArtefactTempDirectory -Recurse -Container:$true        

        Copy-Item -Path "$($inputDirectory)/deploy.prepare.ps1" -Destination $buildArtefactTempDirectory 

        Copy-Item -Path "$($inputDirectory)/deploy.cm.ps1" -Destination $buildArtefactTempDirectory 

        Copy-Item -Path "$($inputDirectory)/deploy.cd.ps1" -Destination $buildArtefactTempDirectory 

        Compress-Archive -Path "$($buildArtefactTempDirectory)/*" -DestinationPath $artefactFilePath        

        Copy-Item -Path "$($inputDirectory)/unpack.ps1" -Destination $outputDirectory 

        Write-Verbose "Completed building the output artefacts."
    }

    end {        
        # Intentionally empty.
    }
}
function Get-SitecoreContentManagementPackage {
    
    [CmdLetBinding()]
    param(        

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]
        $preparedWebsiteDirectory,
        
        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]
        $transformedConfigDirectory,

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]
        $patchConfigDirectory,
        
        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]
        $serialisationDirectory,
        
        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [string]
        $outputDirectory
    )

    begin {
        # Intentionally empty.
    }

    process {
        
        Write-Host "Building a Content Management deployment package from prepared artefacts."

        if (Test-Path $outputDirectory)
        { 
            Remove-Item $outputDirectory -Force -Recurse -ErrorAction Stop
        };

        Invoke-Expression "robocopy '$($preparedWebsiteDirectory)' '$($outputDirectory)/raw/website' /e /ndl /njh /njs"

        Invoke-Expression "robocopy '$($transformedConfigDirectory)' '$($outputDirectory)/raw/website' /e /ndl /njh /njs"

        Invoke-Expression "robocopy '$($patchConfigDirectory)' '$($outputDirectory)/raw/website' /e /ndl /njh /njs"

        Copy-Item -Path $serialisationDirectory -Destination "$($outputDirectory)/raw/serialisation" -Recurse -Force

        $archiveFullName = "$($outputDirectory)/cm.zip"

        Remove-Item $archiveFullName -Force -ErrorAction Ignore

        Compress-Archive -Path "$($outputDirectory)/raw/*" -DestinationPath $archiveFullName

        Write-Verbose "Completed building Content Management deployment package."
    }

    end {        
        # Intentionally empty.
    }
}
function Get-SitecoreContentDeliveryPackage {
    
    [CmdLetBinding()]
    param(        

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]
        $preparedWebsiteDirectory,
        
        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]
        $transformedConfigDirectory,

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]
        $patchConfigDirectory,
        
        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [string]
        $outputDirectory
    )

    begin {
        # Intentionally empty.        
    }

    process {

        Write-Information "Building a Content Delivery deployment package from prepared artefacts."

        if (Test-Path $outputDirectory)
        { 
            Remove-Item $outputDirectory -Force -Recurse -ErrorAction Stop
        };

        Invoke-Expression "robocopy '$($preparedWebsiteDirectory)' '$($outputDirectory)/raw/website' /e /ndl /njh /njs"

        Invoke-Expression "robocopy '$($transformedConfigDirectory)' '$($outputDirectory)/raw/website' /e /ndl /njh /njs"

        Invoke-Expression "robocopy '$($patchConfigDirectory)' '$($outputDirectory)/raw/website' /e /ndl /njh /njs"

        $archiveFullName = "$($outputDirectory)/cd.zip"

        Remove-Item $archiveFullName -Force -ErrorAction Ignore

        Compress-Archive -Path "$($outputDirectory)/raw/*" -DestinationPath $archiveFullName

        Write-Verbose "Completed building Content Delivery deployment package."
    }

    end {
        # Intentionally empty.        
    }
}

Export-ModuleMember -Function Get-SitecoreContentManagementPackage
Export-ModuleMember -Function Get-SitecoreContentDeliveryPackage
Export-ModuleMember -Function Get-SitecoreBuildArtefacts