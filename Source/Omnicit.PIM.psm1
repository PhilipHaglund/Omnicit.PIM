# Load order: Classes (completers/types) -> Private (helpers) -> Public (exported functions)
$PublicFunctions = [System.Collections.Generic.List[string]]::new()
foreach ($ScriptPathItem in 'Classes', 'Private', 'Public') {
    $ScriptSearchFilter = [io.path]::Combine($PSScriptRoot, $ScriptPathItem, '*.ps1')
    Get-ChildItem -Recurse -Path $ScriptSearchFilter -Exclude '*.Tests.ps1' -ErrorAction SilentlyContinue |
        ForEach-Object {
            . $PSItem
            if ($ScriptPathItem -eq 'Public') {
                $PublicFunctions.Add($PSItem.BaseName)
            }
        }
}

# Register short PIM-prefixed aliases pointing to the canonical OPIM-prefixed function names.
$AliasMap = [ordered]@{
    'Get-PIMADRole'           = 'Get-OPIMDirectoryRole'
    'Get-PIMRole'             = 'Get-OPIMDirectoryRole'
    'Enable-PIMADRole'        = 'Enable-OPIMDirectoryRole'
    'Enable-PIMRole'          = 'Enable-OPIMDirectoryRole'
    'Disable-PIMADRole'       = 'Disable-OPIMDirectoryRole'
    'Disable-PIMRole'         = 'Disable-OPIMDirectoryRole'
    'Wait-PIMADRole'          = 'Wait-OPIMDirectoryRole'
    'Wait-PIMRole'            = 'Wait-OPIMDirectoryRole'
    'Get-PIMResourceRole'     = 'Get-OPIMAzureRole'
    'Enable-PIMResourceRole'  = 'Enable-OPIMAzureRole'
    'Disable-PIMResourceRole' = 'Disable-OPIMAzureRole'
    'Get-PIMGroup'            = 'Get-OPIMEntraIDGroup'
    'Enable-PIMGroup'         = 'Enable-OPIMEntraIDGroup'
    'Disable-PIMGroup'        = 'Disable-OPIMEntraIDGroup'
}
foreach ($alias in $AliasMap.GetEnumerator()) {
    New-Alias -Name $alias.Key -Value $alias.Value -Force
}

Export-ModuleMember -Function $PublicFunctions -Alias $AliasMap.Keys

#HACK: There appears to be a bug where formats load before types, so we must do this to get the formats to load right.
#https://github.com/PowerShell/PowerShell/issues/17345
Get-ChildItem "$PSScriptRoot\Formats\*.Format.PS1XML" | ForEach-Object {
    Update-FormatData -PrependPath $PSItem
}
