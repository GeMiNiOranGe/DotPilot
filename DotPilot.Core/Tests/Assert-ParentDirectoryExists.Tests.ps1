<#
Input space
-----------
$Path        : Any string representing a file path. Drives the branch:
               no parent -> return; Exists -> return;
               parent not found -> throw.
$Cmdlet      : Fixed to $PSCmdlet of the synthetic wrapper in all tests.
               No partitioning needed.
$ExtraMessage: Absent | Present

################################################################################

Equivalence Partitioning
------------------------
1. For `$Path`
Partition   Representative               Expected
---------   --------------               --------
No parent   "<ignored>"                  No throw
Exists      "parent\<ignored>"           No throw
Not found   "missing_parent\<ignored>"   Throw DirectoryNotFoundException

Note: $null is coerced to "" by PowerShell's [string] binding, which has no
parent. Same outcome as No parent partition; skip duplicate.

2. For `$ExtraMessage`
Partition   Representative           Expected
---------   --------------           --------
Absent      (omit)                   ErrorDetails is null
Present     "Create the parent..."   ErrorDetails.Message has extra

################################################################################

Decision table
--------------
$Path       $ExtraMessage   Expected
-----       -------------   --------
No parent   Absent          No throw
No parent   Present         No throw
Exists      Absent          No throw
Exists      Present         No throw
Not found   Absent          Throw; ErrorDetails = null
Not found   Present         Throw; ErrorDetails has extra

Note:
1.  'No parent + Present' and 'Exists + Present' are not tested.
    $ExtraMessage is only reached on the throw path; the valid path returns
    early, so no behavior difference Exists ('Exists + Absent').

2.  Exception type, message, attribution, and FullyQualifiedErrorId are tested
    only on 'Absent' combinations. They are determined by path status alone;
    $ExtraMessage only affects ErrorDetails ('Not found + Absent').

################################################################################

Test map
--------
ID   Context    Input                         Technique   Assert
--   -------    -----                         ---------   ------
01   NP + Abs   "<ignored>", no extra         DT          No throw
02   E + Abs    "parent\<ignored>",           DT          No throw
                no extra
03   NF + Abs   "missing_parent\<ignored>",   DT          Exception type
                no extra
04   NF + Abs   ^                             ^           Message has full path
05   NF + Abs   ^                             ^           Message has parent
                                                          directory name
06   NF + Abs   ^                             ^           Attribution =
                                                          Invoke-Caller
07   NF + Abs   ^                             ^           FullyQualifiedErrorId
08   NF + Pre   "missing_parent\<ignored>",   DT          ErrorDetails has extra
                "Create the parent..."                    message

List of Abbreviations:
'^' - Same capture as previous assertion(s)
DT  - Decision Table
NP  - No Parent
E   - Exists
NF  - Not Found
Abs - Absent
Pre - Present
#>
Describe "Assert-ParentDirectoryExists" -Tag "Assert-ParentDirectoryExists", "Assert-*" {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Public\Assert-ParentDirectoryExists.ps1"

        function Invoke-Caller {
            [CmdletBinding()]
            param ([string]$Path, [string]$ExtraMessage)
            Assert-ParentDirectoryExists `
                -Path $Path `
                -Cmdlet $PSCmdlet `
                -ExtraMessage $ExtraMessage
        }
    }

    Context "When parent directory exists" {
        It "Does not throw when parent directory exists" {
            $path = Join-Path $TestDrive "test.log"

            {
                Invoke-Caller -Path $path
            } | Should -Not -Throw
        }
    }

    Context "When parent directory does not exist" {
        BeforeEach {
            $script:path = Join-Path $TestDrive "NonExistentDir" "test.log"
        }

        It "Throws DirectoryNotFoundException when parent directory does not exist" {
            {
                Invoke-Caller -Path $script:path
            } | Should -Throw -ExceptionType (
                [System.IO.DirectoryNotFoundException]
            )
        }

        It "Error message contains the full path" {
            $fullPath = [System.IO.Path]::GetFullPath($script:path)

            {
                Invoke-Caller -Path $script:path
            } | Should -Throw -ExpectedMessage "*'$fullPath'*"
        }

        It "Error message contains the parent directory" {
            $parentDir = [System.IO.Path]::GetDirectoryName($script:path)

            {
                Invoke-Caller -Path $script:path
            } | Should -Throw -ExpectedMessage "*'$parentDir'*"
        }

        It "Error is attributed to the caller, not to Assert-ParentDirectoryExists" {
            try {
                Invoke-Caller -Path $script:path
            }
            catch {
                $_.InvocationInfo.MyCommand.Name | Should -Be "Invoke-Caller"
            }
        }

        It "ErrorRecord has FullyQualifiedErrorId of 'DirectoryNotFound'" {
            {
                Invoke-Caller -Path $script:path
            } | Should -Throw -ErrorId "DirectoryNotFound,Invoke-Caller"
        }
    }

    Context "When ExtraMessage is provided" {
        BeforeEach {
            $script:path = Join-Path $TestDrive "NonExistentDir" "test.log"
        }

        It "Error message contains the extra message" {
            $extraMessage = "Create the parent directory first."

            try {
                Invoke-Caller -Path $script:path -ExtraMessage $extraMessage
            }
            catch {
                $_.ErrorDetails.Message | Should -BeLike "*$extraMessage"
            }
        }
    }

    Context "Input validation" {
        It "Throws when Path is null or empty" {
            {
                Invoke-Caller -Path ""
            } | Should -Throw
        }
    }

    Context "When path has no parent directory" {
        It "Does not throw when path has no parent (e.g., a bare filename)" {
            {
                Invoke-Caller -Path "test.log"
            } | Should -Not -Throw
        }

        It "Does not throw when path is a root drive" {
            {
                Invoke-Caller -Path "C:\"
            } | Should -Not -Throw
        }
    }
}
