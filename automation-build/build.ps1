$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

Import-Module "$($PSScriptRoot)\lib\ClientSideBuild.psm1" -Force
Import-Module "$($PSScriptRoot)\lib\DependencyManagement.psm1" -Force
Import-Module "$($PSScriptRoot)\lib\DotNetTest.psm1" -Force
Import-Module "$($PSScriptRoot)\lib\DotNetBuild.psm1" -Force
Import-Module "$($PSScriptRoot)\lib\SitecoreHelixConfig.psm1" -Force
Import-Module "$($PSScriptRoot)\lib\SitecoreReleaseConfig.psm1" -Force
Import-Module "$($PSScriptRoot)\lib\SitecoreSerialisation.psm1" -Force
Import-Module "$($PSScriptRoot)\lib\SitecorePackaging.psm1" -Force

Write-Host "Clearing existing deployment files."

# Visual Studio build tools paths.

$msbuildExecutableFilePath = "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe"
$visualStudioToolsDirectoryPath = "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Microsoft\VisualStudio\v16.0"

# Clean previous job.

Remove-Item "$($PSScriptRoot)\zip" -Recurse -ErrorAction Ignore
Remove-Item "$($PSScriptRoot)\temp" -Recurse -ErrorAction Ignore

# Build client-side assets.

Publish-ClientSideAssets `
-clientSideDirectory "$($PSScriptRoot)\..\src\Foundation\Client\Website\assets" 

# Restore .NET dependencies.

Restore-NuGetPackages `
-solutionFilePath "$($PSScriptRoot)\..\Circle.sln" `

# Test.

Test-Units `
-msbuildExecutableFilePath $msbuildExecutableFilePath `
-visualStudioToolsDirectoryPath $visualStudioToolsDirectoryPath `
-solutionFilePath "$($PSScriptRoot)\..\Circle.sln" `
-buildConfiguration "Release"

# Publish website.

Publish-Solution `
-msbuildExecutableFilePath $msbuildExecutableFilePath `
-solutionFilePath "$($PSScriptRoot)\..\Circle.sln" `
-environmentProjectFilePath "$($PSScriptRoot)\..\src\Environment\Website\Website.csproj" `
-buildConfiguration "Release" `
-publishProfile "CI"

# Transforms for CM role.

Copy-Item -Path "$($PSScriptRoot)\assets\config\cm" -Destination "$($PSScriptRoot)\temp\transformed-config\cm" -Recurse -Container

Update-ConfigFilesWithTransforms `
-solutionRootDirectory "$($PSScriptRoot)\..\src" `
-configDirectory "$($PSScriptRoot)\temp\transformed-config\cm" `
-transformExtension ".xdt.release"

Update-ConfigFilesWithTransforms `
-solutionRootDirectory "$($PSScriptRoot)\..\src" `
-configDirectory "$($PSScriptRoot)\temp\transformed-config\cm" `
-transformExtension ".xdt.release.cm"

# Transforms for CD role.

Copy-Item -Path "$($PSScriptRoot)\assets\config\cd" -Destination "$($PSScriptRoot)\temp\transformed-config\cd" -Recurse -Container

Update-ConfigFilesWithTransforms `
-solutionRootDirectory "$($PSScriptRoot)\..\src" `
-configDirectory "$($PSScriptRoot)\temp\transformed-config\cd" `
-transformExtension ".xdt.release"

Update-ConfigFilesWithTransforms `
-solutionRootDirectory "$($PSScriptRoot)\..\src" `
-configDirectory "$($PSScriptRoot)\temp\transformed-config\cd" `
-transformExtension ".xdt.release.cd"

# Patch files for CM role.

New-Item -ItemType "directory" -Path  "$($PSScriptRoot)\temp\patch-config\cm"

Copy-PatchFilesToDirectory `
-solutionRootDirectory "$($PSScriptRoot)\..\src" `
-targetConfigDirectory "$($PSScriptRoot)\temp\patch-config\cm" `
-patchExtension ".config.release"

Copy-PatchFilesToDirectory `
-solutionRootDirectory "$($PSScriptRoot)\..\src" `
-targetConfigDirectory "$($PSScriptRoot)\temp\patch-config\cm" `
-patchExtension ".config.release.cm"

Remove-ExtensionSegment `
-fileDirectory "$($PSScriptRoot)\temp\patch-config\cm" `
-extensionSegment ".release"

Remove-ExtensionSegment `
-fileDirectory "$($PSScriptRoot)\temp\patch-config\cm" `
-extensionSegment ".release.cm"

# Patch files for CD role.

New-Item -ItemType "directory" -Path  "$($PSScriptRoot)\temp\patch-config\cd"

Copy-PatchFilesToDirectory `
-solutionRootDirectory "$($PSScriptRoot)\..\src" `
-targetConfigDirectory "$($PSScriptRoot)\temp\patch-config\cd" `
-patchExtension ".config.release"

Copy-PatchFilesToDirectory `
-solutionRootDirectory "$($PSScriptRoot)\..\src" `
-targetConfigDirectory "$($PSScriptRoot)\temp\patch-config\cd" `
-patchExtension ".config.release.cd"

Remove-ExtensionSegment `
-fileDirectory "$($PSScriptRoot)\temp\patch-config\cd" `
-extensionSegment ".release"

Remove-ExtensionSegment `
-fileDirectory "$($PSScriptRoot)\temp\patch-config\cd" `
-extensionSegment ".release.cd"

# Serialisation.

Copy-Serialisation `
-solutionRootDirectory "$($PSScriptRoot)\..\src" `
-outputDirectory "$($PSScriptRoot)\temp\serial"

Remove-DevelopmentSerialisation `
-serialisationDirectory "$($PSScriptRoot)\temp\serial"

# Generate build artefacts.

Get-SitecoreBuildArtefacts `
-inputDirectory $PSScriptRoot  `
-outputDirectory "$($PSScriptRoot)/../automation-deploy" `
-artefactName "build-output"