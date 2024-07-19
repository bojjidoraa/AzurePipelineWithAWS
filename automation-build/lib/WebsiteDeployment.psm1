$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

$DeploymentTask = [PSCustomObject]@{
    Domain = $null
    Host = $null
    Username = $null
    Password = $null
    Secure = $null
    Session = $null
    WorkingDirectoryRoot = $null
    WorkingDirectoryName = $null    
    WorkingDirectory = $null    
    WebsiteDirectoryRoot = $null
    WebsiteDirectoryName = $null
    WebsiteDirectory = $null
    SerialisationDirectoryRoot = $null
    SerialisationDirectoryName = $null
    SerialisationDirectory = $null
    ApplicationPoolName = $null
    ServerIdentifier = $null
    WebsiteName = $null
    DeploymentPackage = $null
    VanillaInstallArchive = $null
    DeployRelease = $null
    WarmupUrls = $null
}

New-Variable -Name DeploymentTask -Value $DeploymentTask -Scope Script -Force

function New-DeploymentTask {

    [CmdLetBinding()]
    param(

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType "Leaf"})]
        [string]
        $deploymentPackage,

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]        
        [string]
        $deployRelease,

        [Parameter(Mandatory=$true)]        
        $serverVariables
    )

    begin {
        # Intentionally empty.        
    }

    process {
                        
        Write-Host "Creating a new deployment task."

        # General settings, no processing required.
        $DeploymentTask.ServerIdentifier = $serverIdentifier
        $DeploymentTask.DeploymentPackage = $deploymentPackage    
        $DeploymentTask.WebsiteName = $serverVariables.WebsiteName
        $DeploymentTask.VanillaInstallArchive = $serverVariables.VanillaInstallArchivePath
        $DeploymentTask.ApplicationPoolName = $serverVariables.ApplicationPoolName
        $DeploymentTask.Domain = $serverVariables.Domain
        $DeploymentTask.Host = $serverVariables.Host
        $DeploymentTask.Username = $serverVariables.Username
        $DeploymentTask.Password = $serverVariables.Password
        $DeploymentTask.Secure = $serverVariables.Secure
        $DeploymentTask.WarmupUrls = $serverVariables.WarmupUrls
        $DeploymentTask.DeployRelease = $deployRelease
        
        # Working directory values.
        $DeploymentTask.WorkingDirectoryRoot = $serverVariables.WorkingDirectoryRoot
        $DeploymentTask.WorkingDirectoryName = $DeploymentTask.DeployRelease                  
        $DeploymentTask.WorkingDirectory = [IO.Path]::Combine($DeploymentTask.WorkingDirectoryRoot, $DeploymentTask.WorkingDirectoryName)
        
        # Website directory values.
        $DeploymentTask.WebsiteDirectoryRoot = $serverVariables.WebsiteDirectoryRoot
        $DeploymentTask.WebsiteDirectoryName = "$($DeploymentTask.WebsiteName)-$($DeploymentTask.DeployRelease)"  
        $DeploymentTask.WebsiteDirectory = [IO.Path]::Combine($DeploymentTask.WebsiteDirectoryRoot, $DeploymentTask.WebsiteDirectoryName)      
        
        # Serialisation directory values.
        $DeploymentTask.SerialisationDirectoryRoot = $serverVariables.SerialisationDirectoryRoot
        $DeploymentTask.SerialisationDirectoryName = "serialisation-$($DeploymentTask.DeployRelease)"
        $DeploymentTask.SerialisationDirectory = [IO.Path]::Combine($DeploymentTask.SerialisationDirectoryRoot, $DeploymentTask.SerialisationDirectoryName)      

        Write-Verbose "Deployment task created."        
    }

    end {
        # Intentionally empty.        
    }
}

function New-DeploymentSession {

    [CmdLetBinding()]
    param()

    begin {
        # Intentionally empty.        
    }

    process {

        Write-Host "Create a new remote PowerShell session."

        Write-Verbose "Domain: $($DeploymentTask.Domain)"
        Write-Verbose "Host: $($DeploymentTask.Host)"
        Write-Verbose "Username: $($DeploymentTask.Username)"
        Write-Verbose "Secure: $($DeploymentTask.Secure)"

        if ($DeploymentTask.Domain)
        {
            $fullUsername = $DeploymentTask.Domain + '\' + $DeploymentTask.Username

        }else {

            $fullUsername = $DeploymentTask.Username
        }

        Write-Verbose "Full username: $($fullUsername)"
        
        $credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $fullUsername, $DeploymentTask.Password        
        
        if ($true -eq $DeploymentTask.Secure)
        {
            Write-Host "Opening a secure connection to the remote server."

            $DeploymentTask.Session = New-PSSession -ComputerName $DeploymentTask.Host -Credential $credentials -UseSSL
        }
        else 
        {
            Write-Host "Opening an insecure connection to the remote server."

            $DeploymentTask.Session = New-PSSession -ComputerName $DeploymentTask.Host -Credential $credentials
        }        

        Write-Verbose "Completed creating new remote PowerShell session."        
    }

    end {
        # Intentionally empty.        
    }
}

function Add-WorkingDirectory {

    [CmdLetBinding()]
    param()

    begin {
        # Intentionally empty.        
    }

    process {

        Write-Host "Create working directory on remote computer."

        Write-Verbose "Working directory: $($DeploymentTask.WorkingDirectoryName)"      
        
        Invoke-Command -Session $DeploymentTask.Session -ScriptBlock {

            param($root, $name)
            
            New-Item -Path $root -Name $name -ItemType "directory"
        
        } -ArgumentList $DeploymentTask.WorkingDirectoryRoot, $DeploymentTask.WorkingDirectoryName

        Write-Verbose "Completed creating working directory on remote computer."        
    }

    end {
        # Intentionally empty.        
    }
}

function Send-DeploymentPackage {

    [CmdLetBinding()]
    param()

    begin {
        # Intentionally empty.        
    }

    process {

        Write-Host "Sending deployment package to remote computer."

        Write-Verbose "Deployment package: $($DeploymentTask.DeploymentPackage)"
        Write-Verbose "Working directory: $($DeploymentTask.WorkingDirectory)"
        
        Copy-Item -Path $DeploymentTask.DeploymentPackage -Destination $DeploymentTask.WorkingDirectory -ToSession $DeploymentTask.Session

        Write-Verbose "Completed sending package to remote computer."        
    }

    end {
        # Intentionally empty.        
    }    
}

function New-WebsiteDirectory {
    
    [CmdLetBinding()]
    param()

    begin {
        # Intentionally empty.        
    }

    process {

        Write-Host "Create new website directory on remote computer."

        Write-Verbose "Website directory: $($DeploymentTask.WebsiteDirectoryName)"      
        
        Invoke-Command -Session $DeploymentTask.Session -ScriptBlock {

            param($root, $name)
            
            New-Item -Path $root -Name $name -ItemType "directory"
        
        } -ArgumentList $DeploymentTask.WebsiteDirectoryRoot, $DeploymentTask.WebsiteDirectoryName

        Write-Verbose "Completed creating new website directory on remote computer."        
    }

    end {
        # Intentionally empty.        
    }
}

function Expand-VanillaInstallation {
        
    [CmdLetBinding()]
    param()

    begin {
        # Intentionally empty.        
    }

    process {

        Write-Host "Expanding vanilla installation into working directory."

        Write-Verbose "Vanilla installation archive: $($DeploymentTask.VanillaInstallArchive)"
        
        $destination = [IO.Path]::Combine($DeploymentTask.WorkingDirectory, "vanilla")

        Invoke-Command -Session $DeploymentTask.Session -ScriptBlock {

            param($archive, $destination)
            
            Expand-Archive -Path $archive -DestinationPath $destination
        
        } -ArgumentList $DeploymentTask.VanillaInstallArchive, $destination

        Write-Verbose "Completed expanding vanilla installation into working directory."        
    }

    end {
        # Intentionally empty.        
    }
} 

function Expand-DeploymentPackage {
            
    [CmdLetBinding()]
    param()

    begin {
        # Intentionally empty.        
    }

    process {

        Write-Host "Expanding deployment package into working directory."

        $packageFilename = Split-Path $DeploymentTask.DeploymentPackage -leaf

        $remotePackagePath = [IO.Path]::Combine($DeploymentTask.WorkingDirectory, $packageFilename)

        Write-Verbose "Deployment package: $($remotePackagePath)"

        Invoke-Command -Session $DeploymentTask.Session -ScriptBlock {

            param($archive, $destination)
            
            Expand-Archive -Path $archive -DestinationPath $destination
        
        } -ArgumentList $remotePackagePath, $DeploymentTask.WorkingDirectory

        Write-Verbose "Completed expanding deployment package into working directory."        
    }

    end {
        # Intentionally empty.        
    }
}

function Move-VanillaInstallToDirectory {

    [CmdLetBinding()]
    param()

    begin {
        # Intentionally empty.        
    }

    process {

        Write-Host "Moving vanilla install into webroot."

        $vanillaArtefactsPath = [IO.Path]::Combine($DeploymentTask.WorkingDirectory, "vanilla")

        Write-Verbose "Vanilla install artefacts path: $($vanillaArtefactsPath)"
        Write-Verbose "Website directory path: $($DeploymentTask.WebsiteDirectory)"

        Invoke-Command -Session $DeploymentTask.Session -ScriptBlock {

            param($from, $to)
            
            Invoke-Expression "robocopy '$($from)' '$($to)' /s /ndl /njh /njs /nfl /nc /ns /is /it /move"
        
        } -ArgumentList $vanillaArtefactsPath, $DeploymentTask.WebsiteDirectory

        Write-Verbose "Completed moving vanilla install into webroot."        
    }

    end {
        # Intentionally empty.        
    }
}

function Move-WebsiteDeploymentToDirectory {

    [CmdLetBinding()]
    param()

    begin {
        # Intentionally empty.        
    }

    process {

        Write-Host "Moving website into webroot."

        $websiteArtefactsPath = [IO.Path]::Combine($DeploymentTask.WorkingDirectory, "website")

        Write-Verbose "Website artefacts path: $($websiteArtefactsPath)"
        Write-Verbose "Website directory path: $($DeploymentTask.WebsiteDirectory)"

        Invoke-Command -Session $DeploymentTask.Session -ScriptBlock {

            param($from, $to)
                        
            Invoke-Expression "robocopy '$($from)' '$($to)' /s /ndl /njh /njs /nfl /nc /ns /is /it /move"
        
        } -ArgumentList $websiteArtefactsPath, $DeploymentTask.WebsiteDirectory

        Write-Verbose "Completed moving website into webroot."        
    }

    end {
        # Intentionally empty.        
    }
}

function Stop-Website {

    [CmdLetBinding()]
    param()

    begin {
        # Intentionally empty.        
    }

    process {

        Write-Host "Stopping website."

        Write-Verbose "Website name: $($DeploymentTask.WebsiteName)"        

        Write-Verbose "Executing stop command."

        Invoke-Command -Session $DeploymentTask.Session -ScriptBlock {

            param($name)
            
            Stop-IISSite -Name $name -Confirm:$false

        } -ArgumentList $DeploymentTask.WebsiteName

        $startDate = Get-Date
            
        $website

        do {
        
            Write-Verbose "Checking website state."

            $website = Invoke-Command -Session $DeploymentTask.Session -ScriptBlock {

                param($name)
                
                Get-IISSite -Name $name
    
            } -ArgumentList $DeploymentTask.WebsiteName

            Write-Verbose "Website state: $($website.State)"

            if ($website.State -match "Stopped")
            {
                Write-Verbose "Website stopped, carry on."

                break
            }

        } while ($startDate.AddMinutes(5) -gt (Get-Date))

        if ($website.State -match "Started")
        {
            throw "Website did not stop within the given timeframe, the website may stop in the future."
        }

        Write-Verbose "Completed stopping website."
    }

    end {
        # Intentionally empty.        
    }
}

function Wait-ForHealthCheck {
        
    [CmdLetBinding()]
    param() 

    begin {
        # Intentionally empty.        
    }

    process {
        
        Write-Host "Waiting for load balancer health check to complete."

        Start-Sleep -Seconds 15

        Write-Verbose "Waited, continuing with process."        
    }

    end {
        # Intentionally empty.        
    }
}

function Set-WebsiteDirectoryPermissions {

    [CmdLetBinding()]
    param()

    begin {
        # Intentionally empty.        
    }

    process {

        Write-Host "Setting website directory permissions."

        Write-Verbose "Website directory path: $($DeploymentTask.WebsiteDirectory)"

        Invoke-Command -Session $DeploymentTask.Session -ScriptBlock {

            param($websiteDirectory, $applicationPoolName)
            
            $accessControlList = Get-Acl $websiteDirectory

            $applicationPoolAccess = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS AppPool\$($applicationPoolName)","Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
            $accessControlList.SetAccessRule($applicationPoolAccess)
            
            $iisIusersAccess = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS", "Read", "ContainerInherit,ObjectInherit", "None", "Allow")
            $accessControlList.SetAccessRule($iisIusersAccess)

            Set-Acl $websiteDirectory $accessControlList
        
        } -ArgumentList $DeploymentTask.WebsiteDirectory, $DeploymentTask.ApplicationPoolName

        Write-Verbose "Completed setting website directory permissions."        
    }

    end {
        # Intentionally empty.        
    }
}

function New-SerialisationDirectory {
    
    [CmdLetBinding()]
    param()

    begin {
        # Intentionally empty.        
    }

    process {

        Write-Host "Create new serialisation directory on remote computer."

        Write-Verbose "Serialisation directory: $($DeploymentTask.SerialisationDirectoryName)"      
        
        Invoke-Command -Session $DeploymentTask.Session -ScriptBlock {

            param($root, $name)
            
            New-Item -Path $root -Name $name -ItemType "directory"
        
        } -ArgumentList $DeploymentTask.SerialisationDirectoryRoot, $DeploymentTask.SerialisationDirectoryName

        Write-Verbose "Completed creating new serialisation directory on remote computer."        
    }

    end {
        # Intentionally empty.        
    }
}

function Move-SerialisationToDirectory {
    
    [CmdLetBinding()]
    param()

    begin {
        # Intentionally empty.        
    }

    process {

        Write-Host "Moving serialisation into operational directory."

        $serialisationArtefactsPath = [IO.Path]::Combine($DeploymentTask.WorkingDirectory, "serialisation")

        Write-Verbose "Serialisation artefacts path: $($serialisationArtefactsPath)"
        Write-Verbose "Serialisation operational directory path: $($DeploymentTask.SerialisationDirectory)"

        Invoke-Command -Session $DeploymentTask.Session -ScriptBlock {

            param($from, $to)
                        
            Invoke-Expression "robocopy '$($from)' '$($to)' /s /ndl /njh /njs /nfl /nc /ns /is /it /move"
        
        } -ArgumentList $serialisationArtefactsPath, $DeploymentTask.SerialisationDirectory

        Write-Verbose "Completed moving serialisation into operational directory."        
    }

    end {
        # Intentionally empty.        
    }
}

function Set-SerialisationDirectoryPermissions {

    [CmdLetBinding()]
    param()

    begin {
        # Intentionally empty.        
    }

    process {

        Write-Host "Setting serialisation directory permissions."

        Write-Verbose "Serialisation directory path: $($DeploymentTask.SerialisationDirectory)"

        Invoke-Command -Session $DeploymentTask.Session -ScriptBlock {

            param($serialisationDirectory, $applicationPoolName)
            
            $accessControlList = Get-Acl $serialisationDirectory

            $applicationPoolAccess = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS AppPool\$($applicationPoolName)","Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
            $accessControlList.SetAccessRule($applicationPoolAccess)
            
            $iisIusersAccess = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS", "Read", "ContainerInherit,ObjectInherit", "None", "Allow")
            $accessControlList.SetAccessRule($iisIusersAccess)

            Set-Acl $serialisationDirectory $accessControlList
        
        } -ArgumentList $DeploymentTask.SerialisationDirectory, $DeploymentTask.ApplicationPoolName

        Write-Verbose "Completed setting serialisation directory permissions."        
    }

    end {
        # Intentionally empty.        
    }
}
function Set-WebsiteDirectory {
        
    [CmdLetBinding()]
    param()

    begin {
        # Intentionally empty.        
    }

    process {

        # https://octopus.com/blog/iis-powershell#change-physical-path-of-a-site-or-application

        Write-Host "Setting the website directory."

        Write-Verbose "Website name: $($DeploymentTask.WebsiteName)"   
        Write-Verbose "Website directory: $($DeploymentTask.WebsiteDirectory)"        

        Invoke-Command -Session $DeploymentTask.Session -ScriptBlock {

            param($name, $directory)
            
            $manager = Get-IISServerManager

            $manager.Sites[$name].Applications["/"].VirtualDirectories["/"].PhysicalPath = $directory

            $manager.CommitChanges()

        } -ArgumentList $DeploymentTask.WebsiteName, $DeploymentTask.WebsiteDirectory

        Write-Verbose "Completed setting the website directory."
    }

    end {
        # Intentionally empty.        
    }
}

function Start-Website {

    [CmdLetBinding()]
    param()

    begin {
        # Intentionally empty.        
    }

    process {

        Write-Host "Starting website."

        Write-Verbose "Website name: $($DeploymentTask.WebsiteName)"        

        Write-Verbose "Executing start command."

        Invoke-Command -Session $DeploymentTask.Session -ScriptBlock {

            param($name)
            
            Start-IISSite -Name $name

        } -ArgumentList $DeploymentTask.WebsiteName

        $startDate = Get-Date
            
        $website

        do {
        
            Write-Verbose "Checking website state."

            $website = Invoke-Command -Session $DeploymentTask.Session -ScriptBlock {

                param($name)
                
                Get-IISSite -Name $name
    
            } -ArgumentList $DeploymentTask.WebsiteName

            Write-Verbose "Website state: $($website.State)"

            if ($website.State -match "Started")
            {
                Write-Verbose "Website started, carry on."

                break
            }

        } while ($startDate.AddMinutes(5) -gt (Get-Date))

        if ($website.State -match "Stopped")
        {
            throw "Website did not start within the given timeframe, the website may start in the future."
        }

        Write-Verbose "Completed starting website."
    }

    end {
        # Intentionally empty.        
    }
}

function Request-WarmupUrls    {
        
    [CmdLetBinding()]
    param() 

    begin {
        # Intentionally empty.        
    }

    process {
        
        Write-Host "Requesting warmup URLs."

        Write-Verbose "Warmup URLs: $($DeploymentTask.WarmupUrls)"

        $warmupUrls = $DeploymentTask.WarmupUrls -Split "\|"        
        
        foreach ($warmupUrl in $warmupUrls)
        {
            Write-Verbose "Requesting: $($warmupUrl)"

            $statusCode = Invoke-Command -Session $DeploymentTask.Session -ScriptBlock {

                param($warmupUrl)
                
                try
                {
                    $response = Invoke-WebRequest -Uri $warmupUrl -TimeoutSec 600 -UseBasicParsing

                    $response.StatusCode
                }
                catch
                {
                    $_.Exception.Response.StatusCode.value__
                }

            } -ArgumentList $warmupUrl

            if (200 -ne $statusCode)
            {
                Throw "Warmup URL responded with a status code other than 200 OK. Code returned: $($statusCode)."
            }
            else 
            {
                Write-Verbose "Warmup URL request successful. Code returned: $($statusCode)."
            }        
        }     
    }

    end {
        # Intentionally empty.        
    }
}

function Remove-DeploymentSession {
        
    [CmdLetBinding()]
    param() 

    begin {
        # Intentionally empty.        
    }

    process {
        
        Write-Host "Removing remote session, if one exists."

        if ($DeploymentTask.Session)
        {
            Remove-PSSession $DeploymentTask.Session

            Write-Verbose "Remote session removed."
        }
        else
        {
            Write-Verbose "No remote session to remove."
        }        
    }

    end {
        # Intentionally empty.        
    }
}

Export-ModuleMember -Function Get-SoftwareVersion
Export-ModuleMember -Function New-DeploymentTask
Export-ModuleMember -Function New-DeploymentSession
Export-ModuleMember -Function Add-WorkingDirectory
Export-ModuleMember -Function Send-DeploymentPackage
Export-ModuleMember -Function New-WebsiteDirectory   
Export-ModuleMember -Function Expand-VanillaInstallation   
Export-ModuleMember -Function Expand-DeploymentPackage   
Export-ModuleMember -Function Move-WebsiteDeploymentToDirectory
Export-ModuleMember -Function Move-VanillaInstallToDirectory
Export-ModuleMember -Function Stop-Website
Export-ModuleMember -Function Wait-ForHealthCheck
Export-ModuleMember -Function Set-WebsiteDirectoryPermissions
Export-ModuleMember -Function New-SerialisationDirectory   
Export-ModuleMember -Function Move-SerialisationToDirectory
Export-ModuleMember -Function Set-SerialisationDirectoryPermissions
Export-ModuleMember -Function Set-WebsiteDirectory
Export-ModuleMember -Function Start-Website
Export-ModuleMember -Function Request-WarmupUrls
Export-ModuleMember -Function Remove-DeploymentSession