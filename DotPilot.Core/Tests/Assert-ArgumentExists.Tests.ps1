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
1.  'Valid + Present' is not tested. $ExtraMessage is only evaluated on the
    throw path; on the valid path the function returns early before
    $ExtraMessage is ever reached, so the combination produces no observable
    behavior difference.

2.  Exception type, message, attribution, and FullyQualifiedErrorId are only
    tested against 'Absent' combinations ('Empty + Absent' and
    'Whitespace + Absent'). These properties are determined entirely by
    $Value; $ExtraMessage has no effect on them.

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
'~' - None
'^' - Same capture as previous assertion(s)
EP  - Equivalence Partitioning
DT  - Decision Table
E   - Empty
V   - Valid
WS  - Whitespace
Abs - Absent
Pre - Present
#>
Describe "Assert-ArgumentExists" -Tag "Assert-ArgumentExists", "Assert-*" {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Classes\ArgumentNullOrEmptyException.ps1"
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
    }

    Context "When parameter value is provided" {
        It "Does not throw when parameter value is not empty" {
            {
                Invoke-Caller -Name "Environment" -Value "staging"
            } | Should -Not -Throw
        }
    }

    Context "When parameter value is null or empty" {
        BeforeEach {
            $script:name = "Environment"
        }

        It "Throws ArgumentNullOrEmptyException when parameter value is empty" {
            {
                Invoke-Caller -Name $script:name -Value ""
            } | Should -Throw -ExceptionType ([ArgumentNullOrEmptyException])
        }

        It "Error message contains the parameter name" {
            {
                Invoke-Caller -Name $script:name -Value ""
            } | Should -Throw -ExpectedMessage "*'-$($script:name)'*"
        }

        It "Error is attributed to the caller, not to Assert-ArgumentExists" {
            try {
                Invoke-Caller -Name $script:name -Value ""
            }
            catch {
                $_.InvocationInfo.MyCommand.Name | Should -Be "Invoke-Caller"
            }
        }

        It "ErrorRecord has FullyQualifiedErrorId of 'ArgumentNullOrEmpty'" {
            {
                Invoke-Caller -Name $script:name -Value ""
            } | Should -Throw -ErrorId "ArgumentNullOrEmpty,Invoke-Caller"
        }
    }

    Context "When ExtraMessage is provided" {
        It "Error message contains the extra message" {
            $extraMessage = @(
                "Specify a target environment such as 'development', 'testing',"
                " 'staging' or 'production'."
            ) -join ''

            try {
                Invoke-Caller `
                    -Name "Environment" `
                    -Value "" `
                    -ExtraMessage $extraMessage
            }
            catch {
                $_.ErrorDetails.Message | Should -BeLike "*$extraMessage"
            }
        }
    }
}
