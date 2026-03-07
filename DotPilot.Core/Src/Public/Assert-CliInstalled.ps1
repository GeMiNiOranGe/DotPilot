<#
.SYNOPSIS
Asserts that a specified command is installed and available.

.DESCRIPTION
The `Assert-CliInstalled` function checks if a specified command is installed and available on the system. If the command is not found, it throws a terminating error with a custom error message.

.PARAMETER Name
Specifies the name of the command to check for.

.PARAMETER Cmdlet
Specifies the PowerShell cmdlet object that is calling this function.

.PARAMETER ExtraMessage
Specifies an optional extra message to include in the error message.

.EXAMPLE
Assert-CliInstalled -Cmdlet $PSCmdlet -Name 'dotnet' -ExtraMessage 'Make sure the .NET Core SDK is installed.'

No output is produced if 'dotnet' is installed. If the tool is not found, a terminating `CliToolNotInstalledException` is thrown via `$Cmdlet`.

.INPUTS
None. You can't pipe objects to `Assert-CliInstalled`.

.OUTPUTS
None. This function does not return any output, but it throws a terminating error if the CLI tool is not installed.

.NOTES
This function is designed to be used within other PowerShell functions or cmdlets to ensure that required command-line tools are installed and available before proceeding with the operation.

.LINK
https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Assert-CliInstalled.md
#>
function Assert-CliInstalled {
    [CmdletBinding()]
    param (
        [string]
        $Name,

        [System.Management.Automation.PSCmdlet]
        $Cmdlet,

        [string]
        $ExtraMessage
    )
    if (-not (Get-Command -Name $Name -ErrorAction SilentlyContinue)) {
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            [CliToolNotInstalledException]::new($Name, $ExtraMessage),
            "CliToolNotInstalled",
            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
            $Name
        )
        $Cmdlet.ThrowTerminatingError($errorRecord)
    }
}
