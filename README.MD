# Omnicit.PIM — Privileged Identity Management Module

A PowerShell module for self-service activation and deactivation of PIM roles and group memberships across three surfaces:

| Surface | Noun | Cmdlet prefix |
|---|---|---|
| Azure AD / Entra ID directory roles | `DirectoryRole` | `OPIM` |
| Azure resource (RBAC) roles | `AzureRole` | `OPIM` |
| Entra ID PIM groups | `EntraIDGroup` | `OPIM` |

> Originally created by [Justin Grote @justinwgrote](https://github.com/justinwgrote). Overhauled and maintained by [Omnicit](https://github.com/Omnicit).

---

## Installation

```powershell
Install-Module Omnicit.PIM
Import-Module Omnicit.PIM
```

---

## Quick Start

### Azure AD / Entra ID Directory Roles

```powershell
# Connect (request only what you need)
Connect-MgGraph -Scopes 'RoleEligibilitySchedule.ReadWrite.Directory',
                         'RoleAssignmentSchedule.ReadWrite.Directory',
                         'AdministrativeUnit.Read.All'

# List eligible roles
Get-OPIMDirectoryRole

# Activate — tab-complete the role name
Enable-OPIMDirectoryRole <tab>

# Activate all eligible roles for 4 hours with a justification
Get-OPIMDirectoryRole | Enable-OPIMDirectoryRole -Hours 4 -Justification 'Incident response'

# Deactivate
Get-OPIMDirectoryRole -Activated | Disable-OPIMDirectoryRole

# Activate and wait for provisioning before continuing
Get-OPIMDirectoryRole | Enable-OPIMDirectoryRole -Wait
```

### Azure Resource (RBAC) Roles

```powershell
# Connect
Connect-AzAccount

# List eligible roles
Get-OPIMAzureRole

# Activate — tab-complete the role name
Enable-OPIMAzureRole <tab>

# Deactivate all active roles
Get-OPIMAzureRole -Activated | Disable-OPIMAzureRole
```

### Entra ID PIM Groups

```powershell
# Connect (additional scope required)
Connect-MgGraph -Scopes 'RoleEligibilitySchedule.ReadWrite.Directory',
                         'PrivilegedEligibilitySchedule.ReadWrite.AzureADGroup'

# List eligible group memberships/ownerships
Get-OPIMEntraIDGroup

# Filter by access type
Get-OPIMEntraIDGroup -AccessType member

# Activate — tab-complete the group name
Enable-OPIMEntraIDGroup <tab>

# Activate all eligible group assignments
Get-OPIMEntraIDGroup | Enable-OPIMEntraIDGroup -Hours 2 -Justification 'Project work'

# Deactivate
Get-OPIMEntraIDGroup -Activated | Disable-OPIMEntraIDGroup
```

---

## Install-OPIMConfiguration

A convenience function to set up quality-of-life shortcuts in your PowerShell profile.

```powershell
# Add the Activate-MyPIM function and 'pim' alias to your profile
Install-OPIMConfiguration -ProfileAlias

# Preview what -ProfileAlias would do without making changes
Install-OPIMConfiguration -ProfileAlias -WhatIf

# Register a tenant alias (maps short name -> tenant ID)
Install-OPIMConfiguration -TenantMap -TenantAlias contoso -TenantId '00000000-0000-0000-0000-000000000000'

# Set a default activation duration of 4 hours in your profile
Install-OPIMConfiguration -DefaultParameters -Duration 4
```

After running `-ProfileAlias`, a new `pim` shortcut becomes available in your sessions:

```powershell
# Activate all eligible directory roles and PIM groups
pim

# Activate against a named tenant
pim -TenantAlias contoso -Duration 8
```

---

## Short Aliases

For backwards compatibility and convenience, short `PIM`-prefixed aliases are available:

| Canonical cmdlet | Aliases |
|---|---|
| `Get-OPIMDirectoryRole` | `Get-PIMADRole`, `Get-PIMRole` |
| `Enable-OPIMDirectoryRole` | `Enable-PIMADRole`, `Enable-PIMRole` |
| `Disable-OPIMDirectoryRole` | `Disable-PIMADRole`, `Disable-PIMRole` |
| `Wait-OPIMDirectoryRole` | `Wait-PIMADRole`, `Wait-PIMRole` |
| `Get-OPIMAzureRole` | `Get-PIMResourceRole` |
| `Enable-OPIMAzureRole` | `Enable-PIMResourceRole` |
| `Disable-OPIMAzureRole` | `Disable-PIMResourceRole` |
| `Get-OPIMEntraIDGroup` | `Get-PIMGroup` |
| `Enable-OPIMEntraIDGroup` | `Enable-PIMGroup` |
| `Disable-OPIMEntraIDGroup` | `Disable-PIMGroup` |

---

## Default Activation Duration

The default activation period is 1 hour. Override per-call with `-Hours`, or make it persistent:

```powershell
$PSDefaultParameterValues['Enable-OPIM*:Hours'] = 4
```

Or use `Install-OPIMConfiguration -DefaultParameters -Duration 4` to write this to your profile automatically.

---

## WhatIf / Confirm Support

All activation and deactivation commands support `-WhatIf` and `-Confirm`:

```powershell
Get-OPIMDirectoryRole | Enable-OPIMDirectoryRole -WhatIf
```

---

## Activated vs Active

This module distinguishes:

- **Eligible** — a role assignment you can activate but haven't yet
- **Activated** — an eligible role you have explicitly turned on for a time window
- **Active (persistent)** — a role that is always on (outside scope of this module)

Use `-Activated` on the `Get-OPIM*` cmdlets to see currently active assignments.

---

## Dependencies

| Dependency | Purpose |
|---|---|
| `Microsoft.Graph.Authentication` 2.0+ | Directory roles and Entra ID group PIM (raw `Invoke-MgGraphRequest`) |
| `Az.Resources` 5.6+ | Azure resource (RBAC) roles |

---

## Attribution

This module is a fork/overhaul of [JAz.PIM](https://github.com/JustinGrote/JAz.PIM) by [Justin Grote @justinwgrote](https://github.com/justinwgrote), released under the [MIT License](LICENSE).

