# Development Notes — Omnicit.PIM

## Module structure

```
Source/
  Omnicit.PIM.psd1          # Module manifest
  Omnicit.PIM.psm1          # Loader: Classes -> Private -> Public
  Classes/                  # Argument completers (loaded first)
  Private/                  # Internal helper functions
  Public/                   # Exported cmdlets (file name == function name)
  Formats/                  # .Types.ps1xml and .Format.ps1xml files
```

## API Terminology

### Directory Roles (Microsoft Graph)

The Graph API terminology is confusing. Here is the translation to PIM concepts:

| Graph resource | PIM meaning |
|---|---|
| `roleEligibilitySchedules` | Roles you are eligible to activate (not yet active) |
| `roleAssignmentScheduleInstances` | Currently active role assignments (eligible-activated + persistent) |
| `roleAssignmentScheduleRequest` | The activation/deactivation operation. POST with `SelfActivate` or `SelfDeactivate` |

Both activation and deactivation go through `roleAssignmentScheduleRequests`. For `SelfDeactivate` you must supply the `roleAssignmentScheduleInstance` ID (not the schedule ID).

The request reaches `Provisioned` status before the role instance actually appears in the directory. `Wait-OPIMDirectoryRole` polls both stages.

References:
- https://docs.microsoft.com/en-us/azure/active-directory/privileged-identity-management/pim-apis
- https://docs.microsoft.com/en-us/graph/api/resources/privilegedidentitymanagement-root

### Azure Resource Roles (Az.Resources)

| Az cmdlet | PIM meaning |
|---|---|
| `Get-AzRoleEligibilitySchedule` | Eligible (inactive) RBAC roles |
| `Get-AzRoleAssignmentScheduleInstance` | Active RBAC role assignments |
| `New-AzRoleAssignmentScheduleRequest` | Activate or deactivate a role |

### PIM for Groups (Microsoft Graph)

All group PIM operations go through the `identityGovernance/privilegedAccess/group` endpoint family:

| Graph resource | PIM meaning |
|---|---|
| `eligibilitySchedules` | Eligible (inactive) group memberships/ownerships |
| `assignmentScheduleInstances` | Currently active group assignments |
| `assignmentScheduleRequests` | POST with `selfActivate` or `selfDeactivate` |

`accessId` is either `member` or `owner` and identifies whether the assignment is a group membership or ownership.

Required Graph scope: `PrivilegedEligibilitySchedule.ReadWrite.AzureADGroup`

## Activated vs Active

- **Eligible** — the user has a time-bound eligible assignment but it is not currently active
- **Activated** — an eligible assignment the user has explicitly activated for a window
- **Active (persistent)** — a direct (non-PIM) role assignment that is always on; outside scope of this module

## Known issues / hacks

- **Format load order** — `Update-FormatData -PrependPath` is called manually in the psm1 because of a PowerShell bug where formats load before types: https://github.com/PowerShell/PowerShell/issues/17345
- **directoryScopeId expand** — The v1.0 Graph API cannot `$expand` `directoryScope` in the same query, so `Get-OPIMDirectoryRole` makes an extra request per non-root scope to rehydrate the display name.

## Adding a new function

1. Create `Source/Public/Verb-OPIMNoun.ps1` with a matching `function Verb-OPIMNoun` inside.
2. Add the function name to `FunctionsToExport` in `Omnicit.PIM.psd1`.
3. If the function needs tab completion, create a completer class in `Source/Classes/`.
4. Add matching `.Types.ps1xml` and `.Format.ps1xml` files in `Source/Formats/` and register them in `TypesToProcess` in the manifest.
5. Add any short aliases to the alias map in `Omnicit.PIM.psm1` and to `AliasesToExport` in the manifest.

