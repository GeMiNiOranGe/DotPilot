<#
Input space
-----------
$Name        : Any string representing a CLI tool name. Drives the branch:
               command found -> return; not found -> throw.
$Cmdlet      : Fixed to $PSCmdlet of the synthetic wrapper in all tests.
               No partitioning needed.
$ExtraMessage: Absent | Present

################################################################################

Equivalence Partitioning
------------------------
1. For `$Name`
Partition   Representative          Expected
---------   --------------          --------
Exists      "pwsh"                  No throw
Not found   "__nonexistent_cli__"   Throw CommandNotFoundException

Note: $null or "" are outside the valid input domain (Get-Command would
raise a parameter binding error, not CommandNotFoundException) and are
excluded.

2. For `$ExtraMessage`
Partition   Representative      Expected
---------   --------------      --------
Absent      (omit)              ErrorDetails is null
Present     "Install via ..."   ErrorDetails.Message contains extra message

################################################################################

Decision table
--------------
$Name (exists?)   $ExtraMessage   Expected
---------------   -------------   --------
Exists            Absent          No throw
Exists            Present         No throw
Not found         Absent          Throw; ErrorDetails = null
Not found         Present         Throw; ErrorDetails has extra message

Note:
1.  'Exists + Present' is not tested. $ExtraMessage is only evaluated on the
    throw path; on the valid path the function returns early before
    $ExtraMessage is ever reached, so the combination produces no observable
    behavior difference.

2.  Exception type, message, attribution, and FullyQualifiedErrorId are tested
    only against 'Absent' combinations ('Not found + Absent'). These properties
    are determined by command existence alone; $ExtraMessage only affects
    ErrorDetails.

################################################################################

Test map
--------
ID   Context    Input                    Technique   Assert
--   -------    -----                    ---------   ------
01   E + Abs    "pwsh", no extra         DT          No throw
02   NF + Abs   "__nonexistent_cli__",   DT          Exception type
                no extra
03   NF + Abs   ^                        ^           Message contains $Name
04   NF + Abs   ^                        ^           Attribution = Invoke-Caller
05   NF + Abs   ^                        ^           FullyQualifiedErrorId
06   NF + Pre   "__nonexistent_cli__",   DT          ErrorDetails contains
                "Install via ..."                    extra message

List of Abbreviations:
'^'  - Same capture as previous assertion(s)
DT   - Decision Table
EP   - Equivalence Partitioning
NF   - Not Found (command does not exist on the system)
E    - Exists
Abs  - Absent
Pre  - Present
#>
Describe "Assert-CommandExists" -Tag @(
    "Assert-CommandExists",
    "Assert-*"
    "Unit"
) {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Classes\CommandNotFoundException.ps1"
        . "$PSScriptRoot\..\Src\Public\Assert-CommandExists.ps1"

        function Invoke-Caller {
            [CmdletBinding()]
            param (
                [string]$Name,
                [string]$ExtraMessage
            )
            Assert-CommandExists `
                -Name $Name `
                -Cmdlet $PSCmdlet `
                -ExtraMessage $ExtraMessage
        }

        function Assert-GuardThrew {
            param (
                [object]$CaughtError,
                [string]$CommandName,
                [switch]$HasExtraMessage
            )

            if ($null -ne $CaughtError) {
                return
            }

            $extraPart = $HasExtraMessage ? ', with ExtraMessage' : ''

            throw @(
                "Guard: Invoke-Caller did not throw for "
                "CommandName='$CommandName'$extraPart - all assertions in "
                "this Context are invalid."
            ) -join ''
        }
    }

    Context "When command exists and ExtraMessage is absent" {
        # 01
        It "Does not throw" {
            { Invoke-Caller -Name "pwsh" } | Should -Not -Throw
        }
    }

    Context "When command is not found and ExtraMessage is absent" {
        BeforeAll {
            $script:notFound = "__nonexistent_cli__"
            $script:caughtError = $null
            try {
                Invoke-Caller -Name $script:notFound
            }
            catch {
                $script:caughtError = $_
            }

            Assert-GuardThrew `
                -CaughtError $script:caughtError `
                -CommandName $script:notFound
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

    Context "When command is not found and ExtraMessage is present" {
        BeforeAll {
            $script:extraMessage = "Install via ..."
            $script:caughtError = $null
            try {
                Invoke-Caller `
                    -Name "__nonexistent_cli__" `
                    -ExtraMessage $script:extraMessage
            }
            catch {
                $script:caughtError = $_
            }

            Assert-GuardThrew `
                -CaughtError $script:caughtError `
                -CommandName "__nonexistent_cli__" `
                -HasExtraMessage
        }

        # 06
        It "ErrorDetails contains the extra message" {
            $script:caughtError.ErrorDetails.Message | `
                Should -BeLike "*$($script:extraMessage)"
        }
    }
}
