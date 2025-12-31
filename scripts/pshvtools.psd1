#
# Module manifest for module 'PSHVTools'
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'pshvtools.psm1'

# Version number of this module.
ModuleVersion = '1.0.1'

# ID used to uniquely identify this module
GUID = 'a3c5e8f1-9d4b-4a2c-b6e7-8f3d9c1a5b2e'

# Author of this module
Author = 'Vitalie Vrabie'

# Company or vendor of this module
CompanyName = 'PSHVTools'

# Copyright statement for this module
Copyright = '(c) 2025 Vitalie Vrabie. All rights reserved.'

# Description of the functionality provided by this module
Description = 'PSHVTools - PowerShell tools for backing up Hyper-V VMs using checkpoints and 7-Zip compression'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '5.1'

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @('Hyper-V')

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @('Invoke-VMBackup', 'Repair-VhdAcl')

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @('hvbak', 'hv-bak', 'fix-vhd-acl')

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('Hyper-V', 'Backup', 'VM', 'Checkpoint', '7-Zip', 'PSHVTools')

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/vitalie-vrabie/pshvtools'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = 'PSHVTools v1.0.1'

    } # End of PSData hashtable

} # End of PrivateData hashtable

}
