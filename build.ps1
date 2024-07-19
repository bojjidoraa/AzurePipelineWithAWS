###########################################################################
# Author: Matthew Kelly (@Badgerati)
# Date: May 14 2015
# 
# MSBuildPath:  Path to where your MSBuild.exe file resides
# Options:      Array of typical MSBuild options such as /p:Configuration or /t:, etc
# Projects:     Array of Project/Solution files
# CleanDebug:	Switch to clean build in debug mode
# CleanRelease:	Switch to clean build int release mode
#
# Example:
# > .\MultiMSBuild.ps1 -MSBuildPath path\to\msbuild.exe 
#                      -Options /m:2, /p:Configuration=Debug, /t:Rebuild 
#                      -Projects Example1.sln, Example2.sln 
#                      -CleanDebug 
#                      -CleanRelease
###########################################################################
param (
    [Parameter(Mandatory=$true)]
    [string] $MSBuildPath
  
)





#Check MSBuild path
if (!(Test-Path $MSBuildPath)) {
    Write-Error "Cannot find MSBuild at '$MSBuildPath'"
}

function getJsonConfig{
	
	$jsonConfig = "D:\Work\Projects\Demo\PipelineDemo\build-and-deploy-configuration.json"
	
	if ((Test-Path $jsonConfig) -eq $true){$jsonObject = Get-Content $jsonConfig | ConvertFrom-Json}
	else{throw [System.ArgumentException] "$jsonConfig does not exist."}
	
	return $jsonObject
}

$jsonObject = getJsonConfig

	
[String]$path = $jsonObject.config.solutionPath
[String]$siteUrl = $jsonObject.config.siteUrl

	#Get the paths to the site, based on site inputname

	[String]$publishTarget = $siteUrl.Applications["/"].VirtualDirectories["/"].PhysicalPath

#Build project/solutions
 Write-Host "Building $($path)" -foregroundcolor green
        & "$($MSBuildPath)" "$($path)" /t:Build /m


