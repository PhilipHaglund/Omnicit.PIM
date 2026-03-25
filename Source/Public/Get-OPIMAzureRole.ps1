#requires -module Az.Resources
function Get-OPIMAzureRole {
    <#
    .SYNOPSIS
    Get eligible or activated Azure PIM resource roles for the current user.
    .DESCRIPTION
    Retrieves eligible or active Azure RBAC role assignment schedules using Az.Resources cmdlets.
    .EXAMPLE
    Get-OPIMAzureRole
    List all eligible (inactive) Azure roles for yourself.
    .EXAMPLE
    Get-OPIMAzureRole -Activated
    List all currently activated Azure roles for yourself.
    .EXAMPLE
    Get-OPIMAzureRole -Scope '/subscriptions/00000000-...'
    List eligible Azure roles at a specific subscription scope.
    #>
    [CmdletBinding()]
    param(
        #The scope to query (subscription, resource group, or resource). Defaults to root '/'.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)][Alias('Id')][String]$Scope = '/',
        #Fetch roles for all principals. Usually requires Owner/UserAccessAdministrator at the scope.
        [Switch]$All,
        #Only return currently activated role assignment instances.
        [Parameter(ParameterSetName = 'Activated')][Switch]$Activated
    )
    process {
        $filter = if (-not $All) { 'asTarget()' }
        try {
            if ($Activated) {
                Get-AzRoleAssignmentScheduleInstance -Scope $Scope -Filter $filter -ErrorAction Stop |
                    Where-Object AssignmentType -EQ 'Activated'
            } else {
                Get-AzRoleEligibilitySchedule -Scope $Scope -Filter $filter -ErrorAction Stop
            }
        } catch {
            if (-not ($PSItem.FullyQualifiedErrorId.Split(',')[0] -eq 'InsufficientPermissions')) {
                $PSCmdlet.WriteError($PSItem)
                return
            }
            $PSItem.ErrorDetails = "You specified -All but do not have sufficient rights to view all roles at scope ($Scope). This typically requires Owner or UserAccessAdministrator rights."
            $PSCmdlet.WriteError($PSItem)
            return
        }
    }
}
