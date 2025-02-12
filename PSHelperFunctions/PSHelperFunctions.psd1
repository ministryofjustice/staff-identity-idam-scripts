@{
    RootModule        = 'PSHelperFunctions.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '1c2e155b-01d9-4213-82c3-251912a3b04b'
    Author            = 'Jason Gillett'
    CompanyName       = 'MoJ'
    Copyright         = '(c) 2025 MoJ. All rights reserved.'
    Description       = 'Module for PowerShell Helper Functions to be consumed on the MoJ IdAM Platform'
    PowerShellVersion = '7.0.0'
    FunctionsToExport = '*'
    CmdletsToExport   = '*'
    VariablesToExport = '*'
    AliasesToExport   = '*'
    PrivateData       = @{
        PSData = @{
            Tags       = @('PSModule', 'GitHub', 'Azure')
            ProjectUri = 'https://github.com/ministryofjustice/staff-identity-idam-scripts'
        }
    }
}
