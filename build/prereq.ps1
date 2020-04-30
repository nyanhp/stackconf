[CmdletBinding()]
param (
    [Parameter()]
    [string[]]
    $Modules = @('Az', 'Pester', 'PSFramework', 'newtonsoft.json', 'AutomatedLab.Common', 'Ships', 'AutomatedLab')
)

Write-Host 'Downloading modules'
#region Bootstrapping the module and configure basic settings
[Environment]::SetEnvironmentVariable('AUTOMATEDLAB_TELEMETRY_OPTIN', 'yes', 'Machine')
$env:AUTOMATEDLAB_TELEMETRY_OPTIN = 'yes' # or no, we are very open about what we collect.

$moduleTarget = if ($IsLinux)
{
    ($env:PSModulePath -split ':')[0]
}
else
{
    ($env:PSModulePath -split ';')[0]
}

if (-not $moduleTarget)
{
    $moduleTarget = (New-Item -Path $pwd.path -Name moduletemp -ItemType Directory).Fullname
}

if (-not (Test-Path $moduleTarget))
{
    $null = New-Item -Force -Path $moduleTarget -ItemType Directory
}

Save-Module -Path $moduleTarget -Name $Modules -Force -Repository PSGallery

Write-Host 'Creating files and folders'
# If necessary, configure a different lab sources folder, otherwise we use / (i.e. C:\LabSources on Windows and /LabSources on Linux)
$ls = New-Item -ItemType Directory -Path $pwd.Path -Name automatedlabsources -ErrorAction SilentlyContinue -Force
Set-PSFConfig -Module AutomatedLab -Name LabSourcesLocation -Value $ls.FullName

if ($IsLinux)
{
    $null = sudo apt install gss-ntlmssp nuget -y
    $null = New-Item -ItemType File -Path "$((Join-Path ([System.Environment]::GetFolderPath('CommonApplicationData')) -ChildPath "AutomatedLab"))/telemetry.enabled" -Force
}

Write-Host "Downloading labsources"
Import-Module AutomatedLab -Verbose -Force
$null = New-LabSourcesFolder -Force -Confirm:$false -Verbose # Download additional scripts and samples if necessary
if (-not $IsLinux)
{
    Write-Host "Enabling remoting"
    Enable-LabHostRemoting -Force # Required - otherwise there will be manual interaction during the deployment
}

if ($null -ne $env:AzureServicePrincipal)
{
    Write-Host "Connection Azure Account"
    $prince = $env:AzureServicePrincipal | ConvertFrom-Json
    $ilPrincipe = [pscredential]::new($prince.ClientId, ($prince.ClientSecret | ConvertTo-SecureString -AsPlainText -Force) )
    $null = Connect-AzAccount -ServicePrincipal -Credential $ilPrincipe -Tenant $prince.TenantId -Confirm:$false -Force
}
#endregion

exit 0