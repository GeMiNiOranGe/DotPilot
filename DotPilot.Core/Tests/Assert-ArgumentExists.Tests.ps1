<#
Input space
-----------
$Name        : Any string (e.g. "Environment", "   ", "")
               Appears only in error messages; does not affect control flow.
               No partitioning needed.
$Value       : Valid ("staging") | Whitespace ("   ") | Empty ("")
$Cmdlet      : Fixed to $PSCmdlet of the synthetic wrapper in all tests.
               No partitioning needed.
$ExtraMessage: Absent | Present

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

2. For `$ExtraMessage`
Partition   Representative   Expected
---------   --------------   --------
Absent      (omit)           ErrorDetails is null
Present     "Specify..."     ErrorDetails.Message contains extra message

################################################################################

Decision table
--------------
$Value       $ExtraMessage   Expected
------       -------------   --------
Valid        Absent          No throw
Valid        Present         No throw
Empty        Absent          Throw; ErrorDetails = null
Empty        Present         Throw; ErrorDetails contains extra message
Whitespace   Absent          Throw; ErrorDetails = null
Whitespace   Present         Throw; ErrorDetails contains extra message

Note:
1.  'Valid + Present' is not tested. $ExtraMessage is only reached on the
    throw path; the valid path returns early, so no behavior difference exists.

2.  Exception type, message, attribution, and FullyQualifiedErrorId are tested
    only on 'Absent' combinations. They are determined entirely by $Value;
    $ExtraMessage only affects ErrorDetails ('Empty + Absent' and
    'Whitespace + Absent').

################################################################################

Test map
--------
ID   Context    Input                 Technique   Assert
--   -------    -----                 ---------   ------
01   V + Abs    "staging", no extra   DT          No throw
02   E + Abs    "", no extra          DT          Exception type
03   E + Abs    ^                     ^           Message contains $Name
04   E + Abs    ^                     ^           Attribution = Invoke-Caller
05   E + Abs    ^                     ^           FullyQualifiedErrorId
06   E + Pre    "", "Specify"         DT          ErrorDetails has $ExtraMessage
07   WS + Abs   "   ", no extra       DT          Exception type
08   WS + Abs   ^                     ^           Message contains $Name
09   WS + Abs   ^                     ^           Attribution = Invoke-Caller
10   WS + Abs   ^                     ^           FullyQualifiedErrorId
11   WS + Pre   "   ", "Specify"      DT          ErrorDetails has $ExtraMessage

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
        . "$PSScriptRoot\..\Src\Classes\ArgumentBlankException.ps1"
        . "$PSScriptRoot\..\Src\Public\Assert-ArgumentExists.ps1"

        function Invoke-Caller {
            [CmdletBinding()]
            param (
                [string]$Name,
                [AllowEmptyString()]
                [string]$Value,
                [string]$ExtraMessage
            )
            Assert-ArgumentExists `
                -Name $Name `
                -Value $Value `
                -Cmdlet $PSCmdlet `
                -ExtraMessage $ExtraMessage
        }

        function Assert-GuardThrew {
            param (
                [object]$CaughtError,
                [string]$Value,
                [switch]$HasExtraMessage
            )

            if ($null -ne $CaughtError) {
                return
            }

            $valueDisplay = switch ($Value) {
                $null {
                    '<null>'
                    break
                }
                '' {
                    '<empty>'
                    break
                }
                ({ $_.Trim() -eq '' }) {
                    "<whitespace: '$_'>"
                    break
                }
                default {
                    "'$_'"
                    break
                }
            }
            $extraPart = $HasExtraMessage ? ', with ExtraMessage' : ''

            throw @(
                "Guard: Invoke-Caller did not throw for "
                "Value=$valueDisplay$extraPart - all assertions in "
                "this Context are invalid."
            ) -join ''
        }
    }

    Context "When value is valid and ExtraMessage is absent" {
        # 01
        It "Does not throw" {
            { Invoke-Caller -Name "Environment" -Value "staging" } | `
                Should -Not -Throw
        }
    }

    Context "When value is empty and ExtraMessage is absent" {
        BeforeAll {
            $script:caughtError = $null
            $value = ""

            try {
                Invoke-Caller -Name "Environment" -Value $value
            }
            catch {
                $script:caughtError = $_
            }

            Assert-GuardThrew -CaughtError $script:caughtError -Value $value
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

    Context "When value is empty and ExtraMessage is present" {
        BeforeAll {
            $script:extraMessage = @(
                "Specify a target environment such as 'development', 'testing',"
                " 'staging' or 'production'."
            ) -join ''
            $script:caughtError = $null
            $value = ""

            try {
                Invoke-Caller `
                    -Name "Environment" `
                    -Value $value `
                    -ExtraMessage $script:extraMessage
            }
            catch {
                $script:caughtError = $_
            }

            Assert-GuardThrew `
                -CaughtError $script:caughtError `
                -Value $value `
                -HasExtraMessage
        }

        # 06
        It "ErrorDetails contains extra message" {
            $script:caughtError.ErrorDetails.Message | `
                Should -BeLike "*$($script:extraMessage)"
        }
    }

    Context "When value is whitespace-only and ExtraMessage is absent" {
        BeforeAll {
            $script:caughtError = $null
            $value = "   "

            try {
                Invoke-Caller -Name "Environment" -Value $value
            }
            catch {
                $script:caughtError = $_
            }

            Assert-GuardThrew -CaughtError $script:caughtError -Value $value
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

    Context "When value is whitespace-only and ExtraMessage is present" {
        BeforeAll {
            $script:extraMessage = @(
                "Specify a target environment such as 'development', 'testing',"
                " 'staging' or 'production'."
            ) -join ''
            $script:caughtError = $null
            $value = "   "

            try {
                Invoke-Caller `
                    -Name "Environment" `
                    -Value $value `
                    -ExtraMessage $script:extraMessage
            }
            catch {
                $script:caughtError = $_
            }

            Assert-GuardThrew `
                -CaughtError $script:caughtError `
                -Value $value `
                -HasExtraMessage
        }

        # 11
        It "ErrorDetails contains extra message" {
            $script:caughtError.ErrorDetails.Message | `
                Should -BeLike "*$($script:extraMessage)"
        }
    }
}
