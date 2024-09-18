[CmdletBinding()]
param (
    $OrganizationUrl,
    $PAT,
    $OrganizationName
)

$orgUrl = $OrganizationUrl
$pat = $PAT

# Create header with PAT
$token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($pat)"))
$header = @{authorization = "Basic $token"}


# Get the list of all projects in the organization
$projectsUrl = "$OrganizationUrl/_apis/projects?api-version=5.1"
$projects = Invoke-RestMethod -Uri $projectsUrl -Method Get -ContentType "application/json" -Headers $header
$projects.value | ForEach-Object {
   Write-Host $_.id $_.name
   $user =[pscustomobject]@{
        'id' = $_.id
        'name' = $_.name
    }
    $user | Export-CSV -Path allprojnameid.csv -Append -NoTypeInformation -Force
}
