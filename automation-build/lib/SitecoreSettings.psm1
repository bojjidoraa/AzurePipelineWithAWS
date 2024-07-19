$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

Import-Module "$($PSScriptRoot)\DeploymentVariables.psm1" -Force

function Update-SitecoreSettingValuesWithBambooVariables {

    [CmdLetBinding()]
    param(    

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType "Container"})]
        [string]
        $configDirectory
    )

    begin {
        # Intentionally empty.        
    }

    process {
        
        Write-Host "Updating config files, setting values with those specified in Bamboo variables."

        Write-Verbose "Config directory: $($configDirectory)"

        $configurationFiles = Get-ChildItem -Path $configDirectory -Filter *.config -Recurse -ErrorAction SilentlyContinue -Force

        $filteredEnvironmentVariables = Get-Childitem -Path env: | Where-Object Key -Match "bamboo_*"

        $variableHashTable = @{}

        $filteredEnvironmentVariables | ForEach-Object { $variableHashTable.Add($_.Key, $_.Value) }
                
        Write-Verbose "Variables found:"

        Write-Verbose ($variableHashTable.PSBase.Keys | Out-String)

        Write-Verbose "Configuration files found:"

        Write-Verbose ($configurationFiles | Out-String)

        Write-Verbose "Processing files:"

        foreach ($file in $configurationFiles)
        {
            $xml=New-Object XML

            $xml.Load($file.FullName)
    
            Write-Verbose "Processing file: $file"
            
            foreach ($variable in $variableHashTable.GetEnumerator())
            {                
                $processedVariableName = $variable.Name -replace "bamboo_", ""

                $processedVariableName = $processedVariableName -replace "_", "."

                $nodes = $xml.SelectNodes("/configuration/sitecore/settings/setting[@name='$($processedVariableName)']");
        
                Write-Verbose "Processing setting: $($processedVariableName)"

                $processedVariableValue = Remove-EmptyToken $variable.Value

                foreach($node in $nodes) 
                {                    
                    $node.SetAttribute("value", $processedVariableValue);
                }
            }

            $xml.Save($file.FullName)
        }

        Write-Verbose "Completed updating patch files."
    }

    end {
        # Intentionally empty.        
    }
}
function Update-EnvironmentVariableTokensWithBambooValues {
    
    [CmdLetBinding()]
    param(    

        [Parameter(Mandatory=$true)]        
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType "Container"})]
        [string]
        $configDirectory,

        [Parameter(Mandatory=$true)]                
        [hashtable] 
        $tokenAndValueOverrides
    )

    begin {
        # Intentionally empty.        
    }

    process {
        
        Write-Host "Updating config files, swapping environmental variable tokens with values specified in Bamboo variables."

        Write-Verbose "Config directory: $($configDirectory)"

        $configurationFiles = Get-ChildItem -Path $configDirectory -Filter *.config -Recurse -ErrorAction SilentlyContinue -Force

        $filteredEnvironmentVariables = Get-Childitem -Path env: | Where-Object Key -Match "bamboo_*"
        
        $variableHashTable = @{}

        $filteredEnvironmentVariables | ForEach-Object { $variableHashTable.Add($_.Key, $_.Value) }
                
        Write-Verbose "Variables found:"

        Write-Verbose ($variableHashTable.keys | Out-String)

        Write-Verbose "Configuration files found:"

        Write-Verbose ($configurationFiles | Out-String)

        Write-Verbose "Processing files:"

        foreach ($file in $configurationFiles)
        {    
            Write-Verbose "Processing file: $file"
            
            $fileContent = Get-Content $file.FullName -Raw

            $updatesApplied = $false

            foreach ($variable in $tokenAndValueOverrides.GetEnumerator())
            {                
                if ($fileContent -Like "*`$(env:$($variable.Key))*")
                {                    
                    Write-Verbose "Setting found in file: $($variable.Key)"

                    $processedVariableValue = Remove-EmptyToken $variable.Value

                    $fileContent = $fileContent -replace "\`$\(env:$($variable.Key)\)", $processedVariableValue

                    $updatesApplied = $true                    
                }                
            }

            foreach ($variable in $variableHashTable.GetEnumerator())
            {                
                $processedVariableName = $variable.Name -replace "bamboo_", ""                                

                if ($fileContent -Like "*`$(env:$($processedVariableName))*")
                {                    
                    Write-Verbose "Setting found in file: $($processedVariableName)"

                    $processedVariableValue = Remove-EmptyToken $variable.Value

                    $fileContent = $fileContent -replace "\`$\(env:$($processedVariableName)\)", $processedVariableValue

                    $updatesApplied = $true                    
                }                
            }

            if ($updatesApplied)
            {                
                $fileContent | Add-Content -Path "$($file.FullName).tmp" -Force

                Write-Verbose "File content updated, temporary version of file saved."
            
                Remove-Item -Path $file.FullName

                Move-Item -Path "$($file.FullName).tmp" -Destination $file.FullName

                Write-Verbose "Temporary file swapped."
            }
        }

        Write-Verbose "Completed updating config files."
    }

    end {
        # Intentionally empty.        
    }
}

Export-ModuleMember -Function Update-SitecoreSettingValuesWithBambooVariables
Export-ModuleMember -Function Update-EnvironmentVariableTokensWithBambooValues