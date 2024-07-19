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
    [string] $MSBuildPath,
    [Parameter(Mandatory=$true)]
    [object[]] $Options,
    [Parameter(Mandatory=$true)]
    [string[]] $Projects,
    [switch] $CleanDebug,
    [switch] $CleanRelease
)


function DoBuild($project, $config) {
    $command = "$MSBuildPath $config $project"

    Write-Host "Executing: $command"
    cmd /c "$command"
    
    if (! $?) {
        throw "MSBuild of '$project' failed."
    }
}


#Check MSBuild path
if (!(Test-Path $MSBuildPath)) {
    Write-Error "Cannot find MSBuild at '$MSBuildPath'"
}

#Check project/solution paths
foreach ($project in $Projects) {
    if (!(Test-Path $project)) {
        Write-Error "Cannot find project/solution at '$project'"
    }
}

#Clean project/solutions
Write-Host "Cleaning Projects/Solutions:"
foreach ($project in $Projects) {
    Write-Host " - $project"
}

foreach ($project in $Projects) {
    if ($CleanDebug.IsPresent) {
        DoBuild $project '/p:Configuration=Debug /t:Clean'
    }

    if ($CleanRelease.IsPresent) {
        DoBuild $project '/p:Configuration=Release /t:Clean'
    }
}

#Build project/solutions
Write-Host "Building Projects/Solutions:"
foreach ($project in $Projects) {
    Write-Host " - $project"
}

$opts = $Options -join " "

foreach ($project in $Projects) {
    DoBuild $project $opts
}