function Install-OPIMConfiguration {
    <#
    .SYNOPSIS
    Configure Omnicit.PIM shortcuts and settings in the current user's PowerShell environment.
    .DESCRIPTION
    Installs optional quality-of-life improvements into the user's PowerShell profile and configuration:

    - ProfileAlias  : Adds an 'Activate-MyPIM' convenience function and 'pim' alias to $PROFILE.CurrentUserAllHosts
    - TenantMap     : Creates or updates a TenantMap.psd1 file mapping tenant aliases to tenant IDs
    - DefaultParameters : Adds $PSDefaultParameterValues entries to the profile for default settings

    All file operations support -WhatIf and -Confirm.
    .EXAMPLE
    Install-OPIMConfiguration -ProfileAlias
    Add the Activate-MyPIM function and pim alias to the user's profile.
    .EXAMPLE
    Install-OPIMConfiguration -ProfileAlias -WhatIf
    Preview what the ProfileAlias installation would do without making changes.
    .EXAMPLE
    Install-OPIMConfiguration -TenantMap -TenantAlias contoso -TenantId '00000000-0000-0000-0000-000000000000'
    Add or update a tenant alias mapping in TenantMap.psd1.
    .EXAMPLE
    Install-OPIMConfiguration -DefaultParameters -Duration 4
    Add a $PSDefaultParameterValues entry to set the default activation duration to 4 hours.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        #Add the Activate-MyPIM function and 'pim' alias to $PROFILE.CurrentUserAllHosts.
        [Switch]$ProfileAlias,

        #Create or update a TenantMap.psd1 with a tenant alias-to-ID mapping.
        [Switch]$TenantMap,
        #The short alias for the tenant (e.g. 'contoso'). Required with -TenantMap.
        [string]$TenantAlias,
        #The Azure Tenant ID (GUID) for the alias. Required with -TenantMap.
        [string]$TenantId,
        #Path to the TenantMap.psd1 file. Defaults to $env:USERPROFILE\.config\Omnicit.PIM\TenantMap.psd1.
        [string]$TenantMapPath = "$env:USERPROFILE\.config\Omnicit.PIM\TenantMap.psd1",

        #Add $PSDefaultParameterValues entries for common Omnicit.PIM parameters to the profile.
        [Switch]$DefaultParameters,
        #Default activation duration in hours for -DefaultParameters.
        [ValidateRange(1, 24)][int]$Duration = 1,

        #Overwrite existing configuration blocks without prompting.
        [Switch]$Force
    )

    # ── ProfileAlias ──────────────────────────────────────────────────────────
    if ($ProfileAlias) {
        $profilePath = $PROFILE.CurrentUserAllHosts
        $profileDir  = Split-Path $profilePath -Parent

        if (-not (Test-Path $profileDir)) {
            if ($PSCmdlet.ShouldProcess($profileDir, 'Create profile directory')) {
                New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
            }
        }
        if (-not (Test-Path $profilePath)) {
            if ($PSCmdlet.ShouldProcess($profilePath, 'Create profile file')) {
                New-Item -ItemType File -Path $profilePath -Force | Out-Null
            }
        }

        $existingContent = if (Test-Path $profilePath) { Get-Content $profilePath -Raw } else { '' }
        $marker          = '# Omnicit.PIM - ProfileAlias'

        if ($existingContent -match [regex]::Escape($marker)) {
            if (-not $Force) {
                Write-Warning "ProfileAlias block already exists in $profilePath. Use -Force to overwrite."
            } else {
                # Replace the existing block
                $existingContent = $existingContent -replace "(?s)$([regex]::Escape($marker)).*?# End Omnicit.PIM - ProfileAlias", ''
            }
        }

        $profileBlock = @"

$marker
function Activate-MyPIM {
    <#
    .SYNOPSIS
    Convenience wrapper: activate all eligible PIM roles for the current user.
    .PARAMETER TenantAlias
    Optional tenant alias from TenantMap.psd1. If omitted, uses the current MgGraph context.
    .PARAMETER Duration
    Activation duration in hours. Defaults to 1.
    #>
    param(
        [string]`$TenantAlias,
        [int]`$Duration = 1,
        [string]`$TenantMapPath = '$TenantMapPath'
    )
    if (`$TenantAlias -and (Test-Path `$TenantMapPath)) {
        `$map      = Import-PowerShellDataFile `$TenantMapPath
        `$tenantId = `$map[`$TenantAlias]
        if (-not `$tenantId) { throw "Tenant alias '`$TenantAlias' not found in `$TenantMapPath" }
        Connect-MgGraph -TenantId `$tenantId -Scopes 'RoleEligibilitySchedule.ReadWrite.Directory','PrivilegedEligibilitySchedule.ReadWrite.AzureADGroup' -NoWelcome
    }
    Get-OPIMDirectoryRole | Enable-OPIMDirectoryRole -Hours `$Duration -Wait
    Get-OPIMEntraIDGroup  | Enable-OPIMEntraIDGroup  -Hours `$Duration
}
Set-Alias -Name pim -Value Activate-MyPIM
# End Omnicit.PIM - ProfileAlias
"@

        if ($PSCmdlet.ShouldProcess($profilePath, 'Append ProfileAlias block')) {
            Add-Content -Path $profilePath -Value $profileBlock
            Write-Host "ProfileAlias block written to $profilePath" -ForegroundColor Green
        }
    }

    # ── TenantMap ─────────────────────────────────────────────────────────────
    if ($TenantMap) {
        if (-not $TenantAlias) { throw '-TenantAlias is required when using -TenantMap.' }
        if (-not $TenantId)    { throw '-TenantId is required when using -TenantMap.' }
        if ($TenantId -notmatch '^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$') {
            throw "-TenantId '$TenantId' does not look like a valid GUID."
        }

        $tenantMapDir = Split-Path $TenantMapPath -Parent
        if (-not (Test-Path $tenantMapDir)) {
            if ($PSCmdlet.ShouldProcess($tenantMapDir, 'Create TenantMap directory')) {
                New-Item -ItemType Directory -Path $tenantMapDir -Force | Out-Null
            }
        }

        $tenantMap = if (Test-Path $TenantMapPath) {
            Import-PowerShellDataFile $TenantMapPath
        } else {
            @{}
        }

        if ($tenantMap.ContainsKey($TenantAlias) -and -not $Force) {
            Write-Warning "Tenant alias '$TenantAlias' already exists in $TenantMapPath. Use -Force to overwrite."
        } else {
            $tenantMap[$TenantAlias] = $TenantId
            $lines = '@{' + [System.Environment]::NewLine
            foreach ($kv in $tenantMap.GetEnumerator() | Sort-Object Key) {
                $lines += "    '$($kv.Key)' = '$($kv.Value)'" + [System.Environment]::NewLine
            }
            $lines += '}'

            if ($PSCmdlet.ShouldProcess($TenantMapPath, "Write tenant alias '$TenantAlias' = '$TenantId'")) {
                $lines | Set-Content -Path $TenantMapPath -Encoding UTF8
                Write-Host "TenantMap updated at $TenantMapPath" -ForegroundColor Green
            }
        }
    }

    # ── DefaultParameters ─────────────────────────────────────────────────────
    if ($DefaultParameters) {
        $profilePath = $PROFILE.CurrentUserAllHosts
        if (-not (Test-Path $profilePath)) {
            if ($PSCmdlet.ShouldProcess($profilePath, 'Create profile file')) {
                New-Item -ItemType File -Path $profilePath -Force | Out-Null
            }
        }

        $existingContent = if (Test-Path $profilePath) { Get-Content $profilePath -Raw } else { '' }
        $marker          = '# Omnicit.PIM - DefaultParameters'

        if ($existingContent -match [regex]::Escape($marker)) {
            if (-not $Force) {
                Write-Warning "DefaultParameters block already exists in $profilePath. Use -Force to overwrite."
            } else {
                $existingContent = $existingContent -replace "(?s)$([regex]::Escape($marker)).*?# End Omnicit.PIM - DefaultParameters", ''
                Set-Content -Path $profilePath -Value $existingContent -Encoding UTF8
            }
        }

        $dpBlock = @"

$marker
`$PSDefaultParameterValues['Enable-OPIM*:Hours'] = $Duration
# End Omnicit.PIM - DefaultParameters
"@

        if ($PSCmdlet.ShouldProcess($profilePath, "Append DefaultParameters block (Duration=$Duration)")) {
            Add-Content -Path $profilePath -Value $dpBlock
            Write-Host "DefaultParameters block written to $profilePath" -ForegroundColor Green
        }
    }
}
