<#
Input space
-----------
$Path        : Any string representing a directory path. Drives the branch:
               directory exists -> return; not found -> throw.
$Cmdlet      : Fixed to $PSCmdlet of the synthetic wrapper in all tests.
               No partitioning needed.
$ExtraMessage: Absent | Present

################################################################################

Equivalence Partitioning
------------------------
1. For `$Path`
Partition   Representative             Expected
---------   --------------             --------
Exists      (temp directory on disk)   No throw
Not found   "missing_directory"        Throw DirectoryNotFoundException

Note: $null is excluded; PowerShell's [string] binding coerces it to "",
which does not resolve to a Container - same outcome as Not found but is not
a real path domain value; Not found already covers the throw path.

2. For `$ExtraMessage`
Partition   Representative        Expected
---------   --------------        --------
Absent      (omit)                ErrorDetails is null
Present     "Create the dir..."   ErrorDetails.Message contains extra message

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
ID   Context    Input                  Technique   Assert
--   -------    -----                  ---------   ------
01   E + Abs    <temp directory>,      DT          No throw
                no extra
02   NF + Abs   "missing_directory",   DT          Exception type
                no extra
03   NF + Abs   ^                      ^           Message contains full path
04   NF + Abs   ^                      ^           Message contains directory
                                                   name
05   NF + Abs   ^                      ^           Attribution = Invoke-Caller
06   NF + Abs   ^                      ^           FullyQualifiedErrorId
07   NF + Pre   "missing_directory",   DT          ErrorDetails has extra msg
                "Create..."

List of Abbreviations:
'^'  - Same capture as previous assertion(s)
DT   - Decision Table
EP   - Equivalence Partitioning
E    - Exists
NF   - Not Found (directory does not exist on disk)
Abs  - Absent
Pre  - Present
#>
Describe "Assert-DirectoryExists" -Tag @(
    "Assert-DirectoryExists"
    "Assert-*"
    "Unit"
) {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Classes\DirectoryNotFoundException.ps1"
        . "$PSScriptRoot\..\Src\Public\Assert-DirectoryExists.ps1"

        function Invoke-Caller {
            [CmdletBinding()]
            param (
                [string]$Path,
                [string]$ExtraMessage
            )
            Assert-DirectoryExists `
                -Path $Path `
                -Cmdlet $PSCmdlet `
                -ExtraMessage $ExtraMessage
        }
    }

    Context "When directory exists and ExtraMessage is absent" {
        BeforeAll {
            $script:tempDir = Join-Path $TestDrive "temp_directory"
            [void](New-Item -Path $script:tempDir -ItemType Directory)
        }

        # 01
        It "Does not throw" {
            { Invoke-Caller -Path $script:tempDir } | Should -Not -Throw
        }
    }

    Context "When directory does not exist and ExtraMessage is absent" {
        BeforeAll {
            $script:missingDir = Join-Path $TestDrive "missing_directory"
            $script:caughtError = $null

            try {
                Invoke-Caller -Path $script:missingDir
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
        It "Throws DirectoryNotFoundException" {
            $script:caughtError.Exception | Should -BeOfType (
                [DirectoryNotFoundException]
            )
        }

        # 03
        It "Exception message contains the full path" {
            $fullPath = [System.IO.Path]::GetFullPath($script:missingDir)

            $script:caughtError.Exception.Message | `
                Should -BeLike "*'$fullPath'*"
        }

        # 04
        It "Exception message contains the directory name" {
            $directoryName = [System.IO.Path]::GetFileName($script:missingDir)

            $script:caughtError.Exception.Message | `
                Should -BeLike "*'$directoryName'*"
        }

        # 05
        It "Error is attributed to the caller" {
            $script:caughtError.InvocationInfo.MyCommand.Name | `
                Should -Be "Invoke-Caller"
        }

        # 06
        It "FullyQualifiedErrorId is 'DirectoryNotFound,Invoke-Caller'" {
            $script:caughtError.FullyQualifiedErrorId | `
                Should -Be "DirectoryNotFound,Invoke-Caller"
        }
    }

    Context "When directory does not exist and ExtraMessage is present" {
        BeforeAll {
            $script:missingDir = Join-Path $TestDrive "missing_directory"
            $script:extraMessage = "Create the directory first."
            $script:caughtError = $null

            try {
                Invoke-Caller `
                    -Path $script:missingDir `
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
