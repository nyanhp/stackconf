New-LabDefinition -Name SimpleYetEffective -DefaultVirtualizationEngine HyperV
Add-LabMachineDefinition -Name SRV01 -OperatingSystem 'Windows Server 2019 Datacenter (Desktop Experience)' -Memory 4GB
Install-Lab

break

# Mo' credentials, mo' problems
Invoke-LabCommand -ComputerName SRV01 -ScriptBlock {
    Get-WebSite
} -PassThru
Install-LabWindowsFeature -ComputerName SRV01 -FeatureName Web-Server -IncludeManagementTools
Invoke-LabCommand -ComputerName SRV01 -ScriptBlock {
    Get-WebSite
} -PassThru

$cims = New-LabCimSession -ComputerName (Get-LabVm)
Get-Disk -CimSession $cims
Get-DscLocalConfigurationManager -CimSession $cims

# Super simple interactions
Restart-LabVm -ComputerName SRV01 -Wait
Checkpoint-LabVm -SnapshotName BeforeMessingUp -All
Save-Labvm -Name SRV01
Start-LabVm -ComputerName SRV01 -Wait
$nppUri = 'https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v7.8.6/npp.7.8.6.Installer.x64.exe'
$installer = Get-LabInternetFile -Uri $nppUri -Path $labsources/tools -NoDisplay -Force -PassThru
# Works of course with deb and rpm as well
Install-LabSoftwarePackage -Path $installer.FullName -ComputerName (Get-LabVm) -CommandLine '/S' -ExpectedReturnCodes 0,3010
Connect-LabVM -ComputerName SRV01

# Remove when done - reference disks remain
Remove-Lab