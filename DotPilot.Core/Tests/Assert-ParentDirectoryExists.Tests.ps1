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
Describe "Assert-ParentDirectoryExists" -Tag @(
    "Assert-ParentDirectoryExists"
    "Assert-*"
    "Unit"
) {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Classes\DirectoryNotFoundException.ps1"
        . "$PSScriptRoot\..\Src\Public\Assert-ParentDirectoryExists.ps1"

        function Invoke-Caller {
            [CmdletBinding()]
            param (
                [string]$Path,
                [string]$ExtraMessage
            )
            Assert-ParentDirectoryExists `
                -Path $Path `
                -Cmdlet $PSCmdlet `
                -ExtraMessage $ExtraMessage
        }
    }

    Context "When path has no parent and ExtraMessage is absent" {
        # 01
        It "Does not throw" {
            # "<ignored>" is a bare name with no directory separator.
            # GetDirectoryName("ignored") returns "" → early return,
            # no filesystem access occurs.
            { Invoke-Caller -Path "<ignored>" } | Should -Not -Throw
        }
    }

    Context "When parent directory exists and ExtraMessage is absent" {
        BeforeAll {
            # Create a 'parent' directory existing on disk
            $parent = Join-Path $TestDrive "parent"
            [void](New-Item -Path $parent -ItemType Directory)

            # Join a child filename to the parent path,
            # the file itself does not need to exist
            $script:tempPath = Join-Path $parent "<ignored>"
        }

        # 02
        It "Does not throw" {
            { Invoke-Caller -Path $script:tempPath } | Should -Not -Throw
        }
    }

    Context "When parent directory is not found and ExtraMessage is absent" {
        BeforeAll {
            $missingParent = Join-Path $TestDrive "missing_parent"
            $script:missingPath = Join-Path $missingParent "<ignored>"
            $script:caughtError = $null

            try {
                Invoke-Caller -Path $script:missingPath
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

        # 03
        It "Throws DirectoryNotFoundException" {
            $script:caughtError.Exception | Should -BeOfType (
                [DirectoryNotFoundException]
            )
        }

        # 04
        It "Exception message contains the full path" {
            $fullPath = [System.IO.Path]::GetFullPath($script:missingPath)

            $script:caughtError.Exception.Message | `
                Should -BeLike "*'$fullPath'*"
        }

        # 05
        It "Exception message contains the parent directory name" {
            $parentDir = [System.IO.Path]::GetDirectoryName(
                $script:missingPath
            )

            $script:caughtError.Exception.Message | `
                Should -BeLike "*'$parentDir'*"
        }

        # 06
        It "Error is attributed to the caller" {
            $script:caughtError.InvocationInfo.MyCommand.Name | `
                Should -Be "Invoke-Caller"
        }

        # 07
        It "FullyQualifiedErrorId is 'DirectoryNotFound,Invoke-Caller'" {
            $script:caughtError.FullyQualifiedErrorId | `
                Should -Be "DirectoryNotFound,Invoke-Caller"
        }
    }

    Context "When parent directory is not found and ExtraMessage is present" {
        BeforeAll {
            $missingParent = Join-Path $TestDrive "missing_parent"
            $script:missingPath = Join-Path $missingParent "<ignored>"
            $script:extraMessage = "Create the parent directory first."
            $script:caughtError = $null

            try {
                Invoke-Caller `
                    -Path $script:missingPath `
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

        # 08
        It "ErrorDetails contains the extra message" {
            $script:caughtError.ErrorDetails.Message | `
                Should -BeLike "*$($script:extraMessage)"
        }
    }
}
