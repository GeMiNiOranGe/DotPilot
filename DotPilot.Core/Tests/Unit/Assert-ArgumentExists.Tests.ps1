<#
Input space
-----------
Param `$Name`:
    Any string (e.g. "Environment", "   ", "") Appears only in error messages;
    does not affect control flow. No partitioning needed.

Param `$Value`:
    Valid ("staging") | Whitespace ("   ") | Empty ("")

Param `$Cmdlet`:
    Fixed to $PSCmdlet of the synthetic wrapper in all tests. No partitioning
    needed.

Param `$Reason`:
    Absent | Present

################################################################################

Equivalence Partitioning
------------------------
1. For `$Value`
Partition    Representative   Expected
---------    --------------   --------
Valid        "staging"        No throw
Whitespace   "   "            Throw
Empty        ""               Throw
Null         $null            Coerced to "" by PowerShell's [string] binding;
                              same partition as Empty, skip

2. For `$Reason`
Partition   Representative   Expected
---------   --------------   --------
Absent      (omit)           ErrorDetails is null
Present     "Specify..."     ErrorDetails.Message contains $Reason

################################################################################

Decision table
--------------
$Value       $Reason   Expected
------       -------   --------
Valid        Absent    No throw
Valid        Present   No throw
Empty        Absent    Throw; ErrorDetails = null
Empty        Present   Throw; ErrorDetails contains $Reason
Whitespace   Absent    Throw; ErrorDetails = null
Whitespace   Present   Throw; ErrorDetails contains $Reason

Note:
1.  'Valid + Present' is not tested. $Reason is only reached on the throw path;
    the valid path returns early, so no behavior difference exists.

2.  Exception type, message, attribution, and FullyQualifiedErrorId are tested
    only on 'Absent' combinations. They are determined entirely by $Value;
    $Reason only affects ErrorDetails ('Empty + Absent' and
    'Whitespace + Absent').

################################################################################

Test map
--------
ID   Context    Input                  Technique   Assert
--   -------    -----                  ---------   ------
01   V + Abs    "staging", no reason   DT          No throw
02   E + Abs    "", no reason          DT          Exception type
03   E + Abs    ^                      ^           Message contains $Name
04   E + Abs    ^                      ^           Attribution = Invoke-Caller
05   E + Abs    ^                      ^           FullyQualifiedErrorId
06   E + Pre    "", "Specify"          DT          ErrorDetails contains $Reason
07   WS + Abs   "   ", no reason       DT          Exception type
08   WS + Abs   ^                      ^           Message contains $Name
09   WS + Abs   ^                      ^           Attribution = Invoke-Caller
10   WS + Abs   ^                      ^           FullyQualifiedErrorId
11   WS + Pre   "   ", "Specify"       DT          ErrorDetails contains $Reason

List of Abbreviations:
'^' - Same capture as previous assertion(s)
DT  - Decision Table
V   - Valid
E   - Empty
WS  - Whitespace
Abs - Absent
Pre - Present
#>
Describe "Assert-ArgumentExists" -Tag @(
    "Assert-ArgumentExists"
    "Assert-*"
    "Unit"
) {
    BeforeAll {
        . "$PSScriptRoot\..\..\Src\Classes\ArgumentBlankException.ps1"
        . "$PSScriptRoot\..\..\Src\Public\Assert-ArgumentExists.ps1"
        . "$PSScriptRoot\..\Helpers\Assert-GuardThrew.ps1"

        function Invoke-Caller {
            [CmdletBinding()]
            param (
                [string]$Name,
                [AllowEmptyString()]
                [string]$Value,
                [string]$Reason
            )
            Assert-ArgumentExists `
                -Name $Name `
                -Value $Value `
                -Cmdlet $PSCmdlet `
                -Reason $Reason
        }

        $script:emptyContext = "Value='<empty>'"
        $script:whiteSpaceContext = "Value='<whitespace: '   '>'"
    }

    Context "When value is valid and Reason is absent" {
        # 01
        It "Does not throw" {
            { Invoke-Caller -Name "Environment" -Value "staging" } | `
                Should -Not -Throw
        }
    }

    Context "When value is empty and Reason is absent" {
        BeforeAll {
            $script:caughtError = $null

            try {
                Invoke-Caller -Name "Environment" -Value ""
            }
            catch {
                $script:caughtError = $_
            }

            Assert-GuardThrew `
                -CaughtError $script:caughtError `
                -Context $script:emptyContext
        }

        # 02
        It "Throws ArgumentBlankException" {
            $script:caughtError.Exception | Should -BeOfType (
                [ArgumentBlankException]
            )
        }

        # 03
        It "Exception message contains the parameter name" {
            $script:caughtError.Exception.Message | `
                Should -BeLike "*'-Environment'*"
        }

        # 04
        It "Error is attributed to the caller" {
            $script:caughtError.InvocationInfo.MyCommand.Name | `
                Should -Be "Invoke-Caller"
        }

        # 05
        It "FullyQualifiedErrorId is 'ArgumentBlank,Invoke-Caller'" {
            $script:caughtError.FullyQualifiedErrorId | `
                Should -Be "ArgumentBlank,Invoke-Caller"
        }
    }

    Context "When value is empty and Reason is present" {
        BeforeAll {
            $script:reason = @(
                "Specify a target environment such as 'development', 'testing',"
                " 'staging' or 'production'."
            ) -join ''
            $script:caughtError = $null

            try {
                Invoke-Caller `
                    -Name "Environment" `
                    -Value "" `
                    -Reason $script:reason
            }
            catch {
                $script:caughtError = $_
            }

            Assert-GuardThrew `
                -CaughtError $script:caughtError `
                -Context "$script:emptyContext, with Reason" `
        }

        # 06
        It "ErrorDetails contains Reason" {
            $script:caughtError.ErrorDetails.Message | `
                Should -BeLike "*$($script:reason)"
        }
    }

    Context "When value is whitespace-only and Reason is absent" {
        BeforeAll {
            $script:caughtError = $null

            try {
                Invoke-Caller -Name "Environment" -Value "   "
            }
            catch {
                $script:caughtError = $_
            }

            Assert-GuardThrew `
                -CaughtError $script:caughtError `
                -Context $script:whiteSpaceContext
        }

        # 07
        It "Throws ArgumentBlankException" {
            $script:caughtError.Exception | Should -BeOfType (
                [ArgumentBlankException]
            )
        }

        # 08
        It "Exception message contains the parameter name" {
            $script:caughtError.Exception.Message | `
                Should -BeLike "*'-Environment'*"
        }

        # 09
        It "Error is attributed to the caller" {
            $script:caughtError.InvocationInfo.MyCommand.Name | `
                Should -Be "Invoke-Caller"
        }

        # 10
        It "FullyQualifiedErrorId is 'ArgumentBlank,Invoke-Caller'" {
            $script:caughtError.FullyQualifiedErrorId | `
                Should -Be "ArgumentBlank,Invoke-Caller"
        }
    }

    Context "When value is whitespace-only and Reason is present" {
        BeforeAll {
            $script:reason = @(
                "Specify a target environment such as 'development', 'testing',"
                " 'staging' or 'production'."
            ) -join ''
            $script:caughtError = $null

            try {
                Invoke-Caller `
                    -Name "Environment" `
                    -Value "   " `
                    -Reason $script:reason
            }
            catch {
                $script:caughtError = $_
            }

            Assert-GuardThrew `
                -CaughtError $script:caughtError `
                -Context "$script:whiteSpaceContext, with Reason"
        }

        # 11
        It "ErrorDetails contains Reason" {
            $script:caughtError.ErrorDetails.Message | `
                Should -BeLike "*$($script:reason)"
        }
    }
}
