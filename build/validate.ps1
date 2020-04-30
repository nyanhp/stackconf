[CmdletBinding()]
param 
(
    [Parameter()]
    [string]
    $LabName = $env:LabName
)

Import-Lab -Name $LabName -NoValidation -NoDisplay

Invoke-Pester -Script $PSScriptRoot/../tests/unit -OutputFile $PSScriptRoot/../unit-test-results.xml -OutputFormat NUnitXml
Invoke-Pester -Script $PSScriptRoot/../tests/integration -OutputFile $PSScriptRoot/../integration-test-results.xml -OutputFormat NUnitXml
exit 0