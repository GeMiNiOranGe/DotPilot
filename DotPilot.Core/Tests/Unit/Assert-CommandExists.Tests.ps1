<#
Input space
-----------
$Name  : Any string representing a CLI tool name. Drives the branch:
         command found -> return; not found -> throw.
$Cmdlet: Fixed to $PSCmdlet of the synthetic wrapper in all tests.
         No partitioning needed.
$Reason: Absent | Present

################################################################################

Equivalence Partitioning
------------------------
1. For `$Name`
Partition   Representative          Expected
---------   --------------          --------
Exists      "pwsh"                  No throw
Not found   "__nonexistent_cli__"   Throw CommandNotFoundException

Note: $null or "" are outside the valid input domain (Get-Command would raise
a parameter binding error, not CommandNotFoundException) and are excluded.

2. For `$Reason`
Partition   Representative      Expected
---------   --------------      --------
Absent      (omit)              ErrorDetails is null
Present     "Install via ..."   ErrorDetails.Message contains $Reason

################################################################################

Decision table
--------------
$Name       $Reason   Expected
-----       -------   --------
Exists      Absent    No throw
Exists      Present   No throw
Not found   Absent    Throw; ErrorDetails = null
Not found   Present   Throw; ErrorDetails contains $Reason

Note:
1.  'Exists + Present' is not tested. $Reason is only reached on the throw path;
    the valid path returns early, so no behavior difference exists.

2.  Exception type, message, attribution, and FullyQualifiedErrorId are tested
    only on 'Absent' combinations. They are determined by command existence
    alone; $Reason only affects ErrorDetails ('Not found + Absent').

################################################################################

Test map
--------
ID   Context    Input                    Technique   Assert
--   -------    -----                    ---------   ------
01   E + Abs    "pwsh", no reason        DT          No throw
02   NF + Abs   "__nonexistent_cli__",   DT          Exception type
                no reason
03   NF + Abs   ^                        ^           Message contains $Name
04   NF + Abs   ^                        ^           Attribution = Invoke-Caller
05   NF + Abs   ^                        ^           FullyQualifiedErrorId
06   NF + Pre   "__nonexistent_cli__",   DT          ErrorDetails contains
                "Install via ..."                    $Reason

List of Abbreviations:
'^'  - Same capture as previous assertion(s)
DT   - Decision Table
E    - Exists
NF   - Not Found
Abs  - Absent
Pre  - Present
#>
Describe "Assert-CommandExists" -Tag @(
    "Assert-CommandExists",
    "Assert-*"
    "Unit"
) {
    BeforeAll {
        . "$PSScriptRoot\..\..\Src\Classes\CommandNotFoundException.ps1"
        . "$PSScriptRoot\..\..\Src\Public\Assert-CommandExists.ps1"
        . "$PSScriptRoot\..\Helpers\Assert-GuardThrew.ps1"

        function Invoke-Caller {
            [CmdletBinding()]
            param (
                [string]$Name,
                [string]$Reason
            )
            Assert-CommandExists `
                -Name $Name `
                -Cmdlet $PSCmdlet `
                -Reason $Reason
        }

        $script:notFound = "__nonexistent_cli__"
        $script:notFoundContext = "CommandName='$script:notFound'"
    }

    Context "When command exists and Reason is absent" {
        # 01
        It "Does not throw" {
            { Invoke-Caller -Name "pwsh" } | Should -Not -Throw
        }
    }

    Context "When command is not found and Reason is absent" {
        BeforeAll {
            $script:caughtError = $null

            try {
                Invoke-Caller -Name $script:notFound
            }
            catch {
                $script:caughtError = $_
            }

            Assert-GuardThrew `
                -CaughtError $script:caughtError `
                -Context $script:notFoundContext
        }

        # 02
        It "Throws CommandNotFoundException" {
            $script:caughtError.Exception | Should -BeOfType (
                [CommandNotFoundException]
            )
        }

        # 03
        It "Exception message contains the command name" {
            $script:caughtError.Exception.Message | `
                Should -BeLike "*'$($script:notFound)'*"
        }

        # 04
        It "Error is attributed to the caller" {
            $script:caughtError.InvocationInfo.MyCommand.Name | `
                Should -Be "Invoke-Caller"
        }

        # 05
        It "FullyQualifiedErrorId is 'CommandNotFound,Invoke-Caller'" {
            $script:caughtError.FullyQualifiedErrorId | `
                Should -Be "CommandNotFound,Invoke-Caller"
        }
    }

    Context "When command is not found and Reason is present" {
        BeforeAll {
            $script:reason = "Install via ..."
            $script:caughtError = $null

            try {
                Invoke-Caller -Name $script:notFound -Reason $script:reason
            }
            catch {
                $script:caughtError = $_
            }

            Assert-GuardThrew `
                -CaughtError $script:caughtError `
                -Context "$script:notFoundContext, with Reason"
        }

        # 06
        It "ErrorDetails contains Reason" {
            $script:caughtError.ErrorDetails.Message | `
                Should -BeLike "*$($script:reason)"
        }
    }
}
