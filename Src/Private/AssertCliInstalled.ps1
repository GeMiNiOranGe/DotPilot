<#
.SYNOPSIS
Asserts that a specified command is installed and available.

.DESCRIPTION
The `Assert-CliInstalled` function checks if a specified command is installed and available on the system. If the command is not found, it throws a terminating error with a custom error message.

.PARAMETER CommandName
Specifies the name of the command to check for.

.PARAMETER Cmdlet
Specifies the PowerShell cmdlet object that is calling this function.

.PARAMETER ExtraMessage
Specifies an optional extra message to include in the error message.

.EXAMPLE
Assert-CliInstalled -Cmdlet $PSCmdlet -CommandName 'dotnet' -ExtraMessage 'Make sure the .NET Core SDK is installed.'

.NOTES
This function is designed to be used within other PowerShell functions or cmdlets to ensure that required command-line tools are installed and available before proceeding with the operation.
#>
function Assert-CliInstalled {
    [CmdletBinding()]
    param (
        [string]
        $CommandName,

        [System.Management.Automation.PSCmdlet]
        $Cmdlet,

        [string]
        $ExtraMessage
    )
    if (-not (Get-Command -Name $CommandName -ErrorAction SilentlyContinue)) {
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            [CliToolNotInstalledException]::new($CommandName, $ExtraMessage),
            "CommandNotFound",
            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
            $CommandName
        )
        $Cmdlet.ThrowTerminatingError($errorRecord)
    }
}
