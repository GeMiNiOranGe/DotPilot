<#
Input space
-----------
Param `$Path`:
    Any string representing a file path. Drives the branch:
    no parent -> return; exists -> return; not found -> throw.

Param `$Cmdlet`:
    Fixed to $PSCmdlet of the synthetic wrapper in all tests. No partitioning
    needed.

Param `$Reason`:
    Absent | Present

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

2. For `$Reason`
Partition   Representative           Expected
---------   --------------           --------
Absent      (omit)                   ErrorDetails is null
Present     "Create the parent..."   ErrorDetails.Message contains $Reason

################################################################################

Decision table
--------------
$Path       $Reason   Expected
-----       -------   --------
No parent   Absent    No throw
No parent   Present   No throw
Exists      Absent    No throw
Exists      Present   No throw
Not found   Absent    Throw; ErrorDetails = null
Not found   Present   Throw; ErrorDetails contains $Reason

Note:
1.  'No parent + Present' and 'Exists + Present' are not tested. $Reason is only
    reached on the throw path; the valid path returns early, so no behavior
    difference Exists ('Exists + Absent').

2.  Exception type, message, attribution, and FullyQualifiedErrorId are tested
    only on 'Absent' combinations. They are determined by path status alone;
    $Reason only affects ErrorDetails ('Not found + Absent').

################################################################################

Test map
--------
ID   Context    Input                         TDT   Assert
--   -------    -----                         ---   ------
01   NP + Abs   "<ignored>", no reason        DT    No throw
02   E + Abs    "parent\<ignored>",           DT    No throw
                no reason
03   NF + Abs   "missing_parent\<ignored>",   DT    Exception type
                no reason
04   NF + Abs   ^                             ^     Message contains full path
05   NF + Abs   ^                             ^     Message contains parent
                                                    directory name
06   NF + Abs   ^                             ^     Attribution = Invoke-Caller
07   NF + Abs   ^                             ^     FullyQualifiedErrorId
08   NF + Pre   "missing_parent\<ignored>",   DT    ErrorDetails contains
                "Create the parent..."              $Reason

List of Abbreviations:
'^' - Same capture as previous assertion(s)
TDT - Test Design Technique
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
        . "$PSScriptRoot\..\..\Src\Classes\DirectoryNotFoundException.ps1"
        . "$PSScriptRoot\..\..\Src\Public\Assert-ParentDirectoryExists.ps1"
        . "$PSScriptRoot\..\Helpers\Assert-GuardThrew.ps1"

        function Invoke-Caller {
            [CmdletBinding()]
            param (
                [string]$Path,
                [string]$Reason
            )
            Assert-ParentDirectoryExists `
                -Path $Path `
                -Cmdlet $PSCmdlet `
                -Reason $Reason
        }

        $script:missingParentDirContext = "Path='<missing_parent>'"
    }

    Context "When path contains no parent and Reason is absent" {
        # 01
        It "Does not throw" {
            # "<ignored>" is a bare name with no directory separator.
            # GetDirectoryName("ignored") returns "" -> early return,
            # no filesystem access occurs.
            { Invoke-Caller -Path "<ignored>" } | Should -Not -Throw
        }
    }

    Context "When parent directory exists and Reason is absent" {
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

    Context "When parent directory is not found and Reason is absent" {
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

            Assert-GuardThrew `
                -Caller "Invoke-Caller" `
                -CaughtError $script:caughtError `
                -Context $script:missingParentDirContext
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

    Context "When parent directory is not found and Reason is present" {
        BeforeAll {
            $missingParent = Join-Path $TestDrive "missing_parent"
            $script:missingPath = Join-Path $missingParent "<ignored>"
            $script:reason = "Create the parent directory first."
            $script:caughtError = $null

            try {
                Invoke-Caller `
                    -Path $script:missingPath `
                    -Reason $script:reason
            }
            catch {
                $script:caughtError = $_
            }

            Assert-GuardThrew `
                -Caller "Invoke-Caller" `
                -CaughtError $script:caughtError `
                -Context "$script:missingParentDirContext, with Reason"
        }

        # 08
        It "ErrorDetails contains Reason" {
            $script:caughtError.ErrorDetails.Message | `
                Should -BeLike "*$($script:reason)"
        }
    }
}
