$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

function Update-ConfigFilesWithTransforms {
    
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
        $configDirectory,    

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]        
        [string]
        $transformExtension
    )

    begin {
        # Intentionally empty.
    }

    process {
        
        Write-Host "Applying transforms to config files."
        
        Write-Verbose "Locating XDT files from: $($solutionRootDirectory)"
        Write-Verbose "Applying XDT to config files located in: $($configDirectory)"        
        Write-Verbose "Using the following transform extension: $($transformExtension)"    

        $randomId = [guid]::NewGuid()

        $tempTransformDirectory = "$($PSScriptRoot)\temp\transforms\$($randomId)"

        if (Test-Path $tempTransformDirectory)
        { 
            Remove-Item $tempTransformDirectory -Force -Recurse -ErrorAction Stop
        };

        Invoke-Expression "robocopy '$($solutionRootDirectory)' '$($tempTransformDirectory)' /s /ndl /njh /njs *$($transformExtension)"

        $environmentPath = "$($tempTransformDirectory)\Environment\website"

        if (Test-Path $environmentPath) 
        { 
            Invoke-XdtTransform -InputPath $configDirectory -XdtPath $environmentPath -transformExtension $transformExtension
        }; 
        
        $foundationPath = "$($tempTransformDirectory)\Foundation\"

        if (Test-Path $foundationPath) 
        { 
            Get-ChildItem "$($foundationPath)*\website" | ForEach-Object { 
                Invoke-XdtTransform -InputPath $configDirectory -XdtPath $_.FullName -transformExtension $transformExtension
            } 
        };

        $featurePath = "$($tempTransformDirectory)\Feature\"

        if (Test-Path $featurePath) 
        { 
            Get-ChildItem "$($featurePath)*\website" | ForEach-Object { 
                Invoke-XdtTransform -InputPath $configDirectory -XdtPath $_.FullName -transformExtension $transformExtension
            } 
        };

        $projectPath = "$($tempTransformDirectory)\Project\"

        if (Test-Path $projectPath) 
        { 
            Get-ChildItem "$($projectPath)*\website" | ForEach-Object { 
                Invoke-XdtTransform -InputPath $configDirectory -XdtPath $_.FullName -transformExtension $transformExtension
            } 
        };

        if (Test-Path $tempTransformDirectory)
        { 
            Remove-Item $tempTransformDirectory -Force -Recurse -ErrorAction Stop
        };

        Write-Verbose "Completed transforming config files."
    }

    end {
        # Intentionally empty.        
    }
}

function Invoke-XdtTransform 
{  
    Param (

        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ })]
        [string]
        $InputPath,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ })]
        [string]
        $XdtPath,

        [Parameter(Mandatory = $false)]
        [ValidateScript( { Test-Path $_ -PathType 'Leaf' })]
        [string]
        $XdtDllPath = (Join-Path $PSScriptRoot "bin\Microsoft.Web.XmlTransform.dll"),

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]        
        [string]
        $transformExtension
    )

    begin {
        # Intentionally empty.
    }

    process 
    {

        if (((Test-Path $InputPath -PathType Container) -and (Test-Path $XdtPath -PathType Leaf)) -or
            ((Test-Path $InputPath -PathType Leaf) -and (Test-Path $XdtPath -PathType Container))) {

            throw "'Path' and 'XdtPath' parameter types must match (both files or both folders)"
        }

        Add-Type -Path $XdtDllPath

        if (Test-Path $InputPath -PathType Leaf) {

            # File transform
            ApplyTransform $InputPath $XdtPath
        } 
        else 
        {
            # Folder transform
            $transformations = @(Get-ChildItem $XdtPath -File -Include "*$($transformExtension)" -Recurse)

            if ($transformations.Length -eq 0) {

                Write-Verbose "No transformations in '$XdtPath'"

                return
            }

            $transformations | ForEach-Object {

                # Assume folder structures match
                $targetFullPath = (Resolve-Path $InputPath).Path

                $xdtFullPath = (Resolve-Path $XdtPath).Path

                $targetFilePath = $_.FullName.Replace($xdtFullPath, $targetFullPath).Replace($transformExtension, "")

                if (-not(Test-Path $targetFilePath -PathType Leaf)) {

                    Write-Verbose "No matching file '$targetFilePath' for transformation '$($_.FullName)'. Skipping."

                    return
                }

                ApplyTransform $targetFilePath $_.FullName
            }
        }
    }

    end {
        # Intentionally empty.        
    }
}

function ApplyTransform
{  
    Param (

        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ -PathType 'Leaf' })]
        [string]
        $filePath,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ -PathType 'Leaf' })]
        [string]
        $xdtFilePath
    )

    begin {
        # Intentionally empty.
    }

    process 
    {
        Write-Verbose "Applying XDT transformation '$xdtFilePath' on '$filePath'."
    
        $target = New-Object Microsoft.Web.XmlTransform.XmlTransformableDocument;
    
        $target.PreserveWhitespace = $true
        
        $target.Load($filePath);
        
        $transformation = New-Object Microsoft.Web.XmlTransform.XmlTransformation($xdtFilePath);
        
        if ($transformation.Apply($target) -eq $false)
        {
            throw "XDT transformation failed."
        }
        
        $target.Save($filePath);
    }

    end {
        # Intentionally empty.        
    }
}

Export-ModuleMember -Function Update-ConfigFilesWithTransforms