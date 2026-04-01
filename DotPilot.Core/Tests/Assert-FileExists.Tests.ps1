<#
Input space
-----------
$Path        : Any string representing a file path. Drives the branch:
               file exists -> return; not found -> throw.
$Cmdlet      : Fixed to $PSCmdlet of the synthetic wrapper in all tests.
               No partitioning needed.
$ExtraMessage: Absent | Present

################################################################################

Equivalence Partitioning
------------------------
1. For `$Path`
Partition   Representative        Expected
---------   --------------        --------
Exists      (temp file on disk)   No throw
Not found   "missing_file.txt"    Throw FileNotFoundException

Note: $null is excluded; PowerShell's [string] binding coerces it to "",
which does not resolve to a Leaf - same outcome as Not found but is not
a real path domain value; Not found already covers the throw path.

2. For `$ExtraMessage`
Partition   Representative      Expected
---------   --------------      --------
Absent      (omit)              ErrorDetails is null
Present     "Ensure that ..."   ErrorDetails.Message contains extra message

################################################################################

Decision table
--------------
$Path       $ExtraMessage   Expected
-----       -------------   --------
Exists      Absent          No throw
Exists      Present         No throw
Not found   Absent          Throw; ErrorDetails = null
Not found   Present         Throw; ErrorDetails has extra message

Note:
1.  'Exists + Present' is not tested. $ExtraMessage is only reached on the
    throw path; the valid path returns early, so no behavior difference exists.

2.  Exception type, message, attribution, and FullyQualifiedErrorId are tested
    only on 'Absent' combinations. They are determined by path existence alone;
    $ExtraMessage only affects ErrorDetails ('Not found + Absent').

################################################################################

Test map
--------
ID   Context    Input                   Technique   Assert
--   -------    -----                   ---------   ------
01   E + Abs    <temp file>, no extra   DT          No throw
02   NF + Abs   "missing_file.txt",     DT          Exception type
                no extra
03   NF + Abs   ^                       ^           Message contains full path
04   NF + Abs   ^                       ^           Message contains file name
05   NF + Abs   ^                       ^           Attribution = Invoke-Caller
06   NF + Abs   ^                       ^           FullyQualifiedErrorId
07   NF + Pre   "missing_file.txt",     DT          ErrorDetails contains
                "Ensure that ..."                   extra message

List of Abbreviations:
'^'  - Same capture as previous assertion(s)
DT   - Decision Table
E    - Exists
NF   - Not Found
Abs  - Absent
Pre  - Present
#>
Describe "Assert-FileExists" -Tag @(
    "Assert-FileExists"
    "Assert-*"
    "Unit"
) {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Classes\FileNotFoundException.ps1"
        . "$PSScriptRoot\..\Src\Public\Assert-FileExists.ps1"

        function Invoke-Caller {
            [CmdletBinding()]
            param (
                [string]$Path,
                [string]$ExtraMessage
            )
            Assert-FileExists `
                -Path $Path `
                -Cmdlet $PSCmdlet `
                -ExtraMessage $ExtraMessage
        }
    }

    Context "When file exists and ExtraMessage is absent" {
        BeforeAll {
            $script:tempFile = Join-Path $TestDrive "temp.txt"
            [void](New-Item -Path $script:tempFile -ItemType File)
        }

        # 01
        It "Does not throw" {
            { Invoke-Caller -Path $script:tempFile } | Should -Not -Throw
        }
    }

    Context "When file is not found and ExtraMessage is absent" {
        BeforeAll {
            $script:missingFile = Join-Path $TestDrive "missing_file.txt"
            $script:caughtError = $null

            try {
                Invoke-Caller -Path $script:missingFile
            }
            catch {
                $script:caughtError = $_
            }

            if ($null -eq $script:caughtError) {
                throw @(
                    "Guard: Invoke-Caller did not throw - all assertions in "
                    "this Context are invalid."
                ) -join ''
            }
        }

        # 02
        It "Throws FileNotFoundException" {
            $script:caughtError.Exception | Should -BeOfType (
                [FileNotFoundException]
            )
        }

        # 03
        It "Exception message contains the full path" {
            $fullPath = [System.IO.Path]::GetFullPath($script:missingFile)

            $script:caughtError.Exception.Message | `
                Should -BeLike "*'$fullPath'*"
        }

        # 04
        It "Exception message contains the file name" {
            $fileName = [System.IO.Path]::GetFileName($script:missingFile)

            $script:caughtError.Exception.Message | `
                Should -BeLike "*'$fileName'*"
        }

        # 05
        It "Error is attributed to the caller" {
            $script:caughtError.InvocationInfo.MyCommand.Name | `
                Should -Be "Invoke-Caller"
        }

        # 06
        It "FullyQualifiedErrorId is 'FileNotFound,Invoke-Caller'" {
            $script:caughtError.FullyQualifiedErrorId | `
                Should -Be "FileNotFound,Invoke-Caller"
        }
    }

    Context "When file is not found and ExtraMessage is present" {
        BeforeAll {
            $script:missingFile = Join-Path $TestDrive "missing_file.txt"
            $script:extraMessage = "Ensure that 'file.txt' exists."
            $script:caughtError = $null

            try {
                Invoke-Caller `
                    -Path $script:missingFile `
                    -ExtraMessage $script:extraMessage
            }
            catch {
                $script:caughtError = $_
            }

            if ($null -eq $script:caughtError) {
                throw @(
                    "Guard: Invoke-Caller did not throw - all assertions in "
                    "this Context are invalid."
                ) -join ''
            }
        }

        # 07
        It "ErrorDetails contains the extra message" {
            $script:caughtError.ErrorDetails.Message | `
                Should -BeLike "*$($script:extraMessage)"
        }
    }
}
