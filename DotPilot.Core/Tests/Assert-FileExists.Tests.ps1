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
EP   - Equivalence Partitioning
NF   - Not Found (file does not exist on disk)
E    - Exists
Abs  - Absent
Pre  - Present
#>
Describe "Assert-FileExists" -Tag "Assert-FileExists", "Assert-*" {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Classes\FileNotFoundException.ps1"
        . "$PSScriptRoot\..\Src\Public\Assert-FileExists.ps1"

        function Invoke-Caller {
            [CmdletBinding()]
            param ([string]$Path, [string]$ExtraMessage)
            Assert-FileExists `
                -Path $Path `
                -Cmdlet $PSCmdlet `
                -ExtraMessage $ExtraMessage
        }
    }

    Context "When file exists" {
        BeforeEach {
            $script:path = Join-Path $TestDrive "test.txt"
            [void](New-Item -Path $script:path -ItemType File -Force)
        }

        It "Does not throw when file exists" {
            {
                Invoke-Caller -Path $script:path
            } | Should -Not -Throw
        }
    }

    Context "When file does not exist" {
        BeforeEach {
            $script:path = Join-Path $TestDrive "NonExistentFile.txt"
        }

        It "Throws FileNotFoundException when file does not exist" {
            {
                Invoke-Caller -Path $script:path
            } | Should -Throw -ExceptionType ([FileNotFoundException])
        }

        It "Error message contains the full path" {
            $fullPath = [System.IO.Path]::GetFullPath($script:path)

            {
                Invoke-Caller -Path $script:path
            } | Should -Throw -ExpectedMessage "*'$fullPath'*"
        }

        It "Error message contains the file name" {
            $fileName = [System.IO.Path]::GetFileName($script:path)

            {
                Invoke-Caller -Path $script:path
            } | Should -Throw -ExpectedMessage "*'$fileName'*"
        }

        It "Error is attributed to the caller, not to Assert-FileExists" {
            try {
                Invoke-Caller -Path $script:path
            }
            catch {
                $_.InvocationInfo.MyCommand.Name | Should -Be "Invoke-Caller"
            }
        }

        It "ErrorRecord has FullyQualifiedErrorId of 'FileNotFound'" {
            {
                Invoke-Caller -Path $script:path
            } | Should -Throw -ErrorId "FileNotFound,Invoke-Caller"
        }
    }

    Context "When ExtraMessage is provided" {
        It "Error message contains the extra message" {
            $path = Join-Path $TestDrive "NonExistentFile.txt"
            $extraMessage = "Create the file first."

            try {
                Invoke-Caller -Path $path -ExtraMessage $extraMessage
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
