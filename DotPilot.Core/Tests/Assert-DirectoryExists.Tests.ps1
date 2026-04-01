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
Describe "Assert-DirectoryExists" -Tag "Assert-DirectoryExists", "Assert-*" {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Public\Assert-DirectoryExists.ps1"

        function Invoke-Caller {
            [CmdletBinding()]
            param ([string]$Path, [string]$ExtraMessage)
            Assert-DirectoryExists `
                -Path $Path `
                -Cmdlet $PSCmdlet `
                -ExtraMessage $ExtraMessage
        }
    }

    Context "When directory exists" {
        It "Does not throw when directory exists" {
            {
                Invoke-Caller -Path $TestDrive
            } | Should -Not -Throw
        }
    }

    Context "When directory does not exist" {
        BeforeEach {
            $script:path = Join-Path $TestDrive "NonExistentDir"
        }

        It "Throws DirectoryNotFoundException when directory does not exist" {
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

        It "Error message contains the directory name" {
            $directoryName = [System.IO.Path]::GetFileName($script:path)

            {
                Invoke-Caller -Path $script:path
            } | Should -Throw -ExpectedMessage "*'$directoryName'*"
        }

        It "Error is attributed to the caller, not to Assert-DirectoryExists" {
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
            $script:path = Join-Path $TestDrive "NonExistentDir"
        }

        It "Error message contains the extra message" {
            $extraMessage = "Create the directory first."

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
}
