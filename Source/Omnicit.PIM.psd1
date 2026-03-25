#
# Module manifest for module 'Omnicit.PIM'
#
# Originally created by: Justin Grote @justinwgrote
# Overhauled by: Omnicit
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'Omnicit.PIM.psm1'

# Version number of this module.
ModuleVersion = '1.0.0'

# Supported PSEditions
CompatiblePSEditions = @('Core')

# ID used to uniquely identify this module
GUID = 'a7c4e832-6f19-4d8b-9b3e-d1f50c7e8a2b'

# Author of this module
Author = 'Omnicit (originally by Justin Grote @justinwgrote)'

# Company or vendor of this module
CompanyName = 'Omnicit'

# Copyright statement for this module
Copyright = '(c) 2026 Omnicit. Originally (c) Justin Grote @justinwgrote. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Azure Privileged Identity Management (PIM) Self Activation Commands for Directory Roles, Azure Resources, and Entra ID Groups'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '7.2'

RequiredModules = @(
    @{ ModuleName = 'Az.Resources';                  ModuleVersion = '5.6.0' }
    @{ ModuleName = 'Microsoft.Graph.Authentication'; ModuleVersion = '2.0.0' }
)

TypesToProcess = @(
    'Formats/Omnicit.PIM.DirectoryEligibilitySchedule.Types.ps1xml'
    'Formats/Omnicit.PIM.DirectoryAssignmentScheduleInstance.Types.ps1xml'
    'Formats/Omnicit.PIM.DirectoryAssignmentScheduleRequest.Types.ps1xml'
    'Formats/Omnicit.PIM.GroupEligibilitySchedule.Types.ps1xml'
    'Formats/Omnicit.PIM.GroupAssignmentScheduleInstance.Types.ps1xml'
    'Formats/Omnicit.PIM.GroupAssignmentScheduleRequest.Types.ps1xml'
    'Formats/RoleAssignmentScheduleRequest.Types.ps1xml'
)

# BUG: Disabled until https://github.com/PowerShell/PowerShell/issues/17345 is fixed.
# FormatsToProcess = @(...)

FunctionsToExport = @(
    'Get-OPIMDirectoryRole'
    'Enable-OPIMDirectoryRole'
    'Disable-OPIMDirectoryRole'
    'Wait-OPIMDirectoryRole'
    'Get-OPIMAzureRole'
    'Enable-OPIMAzureRole'
    'Disable-OPIMAzureRole'
    'Get-OPIMEntraIDGroup'
    'Enable-OPIMEntraIDGroup'
    'Disable-OPIMEntraIDGroup'
    'Install-OPIMConfiguration'
)

AliasesToExport = @(
    'Get-PIMADRole'
    'Get-PIMRole'
    'Enable-PIMADRole'
    'Enable-PIMRole'
    'Disable-PIMADRole'
    'Disable-PIMRole'
    'Wait-PIMADRole'
    'Wait-PIMRole'
    'Get-PIMResourceRole'
    'Enable-PIMResourceRole'
    'Disable-PIMResourceRole'
    'Get-PIMGroup'
    'Enable-PIMGroup'
    'Disable-PIMGroup'
)

PrivateData = @{
    PSData = @{
        Tags       = @('PIM', 'Azure', 'EntraID', 'ActiveDirectory', 'Identity', 'Privileged')
        ProjectUri = 'https://github.com/Omnicit/Omnicit.PIM'
    }
}

}
