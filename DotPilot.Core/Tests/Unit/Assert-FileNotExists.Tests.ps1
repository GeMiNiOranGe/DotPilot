<#
Input space
-----------
Param `$Path`:
    Any string representing a file path. Drives the branch:
    file not found -> return; file exists -> throw.

Param `$Cmdlet`:
    Fixed to $PSCmdlet of the synthetic wrapper in all tests. No partitioning
    needed.

Param `$Reason`:
    Absent | Present

################################################################################

Equivalence Partitioning
------------------------
1. For `$Path`
Partition   Representative        Expected
---------   --------------        --------
Not found   "file.txt"            No throw
Exists      (temp file on disk)   Throw FileAlreadyExistsException

Note: $null is excluded; PowerShell's [string] binding coerces it to "",
which does not resolve to a Leaf - same outcome as Not found but is not
a real path domain value; Not found already covers the no-throw path.

2. For `$Reason`
Partition   Representative     Expected
---------   --------------     --------
Absent      (omit)             ErrorDetails is null
Present     "Remove the ..."   ErrorDetails.Message contains $Reason

################################################################################

Decision table
--------------
$Path       $Reason   Expected
-----       -------   --------
Not found   Absent    No throw
Not found   Present   No throw
Exists      Absent    Throw; ErrorDetails = null
Exists      Present   Throw; ErrorDetails contains $Reason

Note:
1.  'Not found + Present' is not tested. $Reason is only reached on the throw
    path; the valid path returns early, so no behavior difference exists.

2.  Exception type, message, attribution, and FullyQualifiedErrorId are tested
    only on 'Absent' combinations. They are determined by path existence alone;
    $Reason only affects ErrorDetails ('Exists + Absent').

################################################################################

Test map
--------
ID   Context    Input                    TDT   Assert
--   -------    -----                    ---   ------
01   NF + Abs   "file.txt", no reason    DT    No throw
02   E + Abs    <temp file>, no reason   DT    Exception type
03   E + Abs    ^                        ^     Message contains file path
04   E + Abs    ^                        ^     Attribution = Invoke-Caller
05   E + Abs    ^                        ^     FullyQualifiedErrorId
06   E + Pre    <temp file>,             DT    ErrorDetails contains $Reason
                "Remove the..."

List of Abbreviations:
'^' - Same capture as previous assertion(s)
TDT - Test Design Technique
DT  - Decision Table
NF  - Not Found
E   - Exists
Abs - Absent
Pre - Present
#>
Describe "Assert-FileNotExists" -Tag @(
    "Assert-FileNotExists"
    "Assert-*"
    "Unit"
) {
    BeforeAll {
        . "$PSScriptRoot\..\..\Src\Classes\FileAlreadyExistsException.ps1"
        . "$PSScriptRoot\..\..\Src\Public\Assert-FileNotExists.ps1"
        . "$PSScriptRoot\..\Helpers\Assert-GuardThrew.ps1"

        function Invoke-Caller {
            [CmdletBinding()]
            param (
                [string]$Path,
                [string]$Reason
            )
            Assert-FileNotExists `
                -Path $Path `
                -Cmdlet $PSCmdlet `
                -Reason $Reason
        }

        $script:fileContext = "Path='<temp.txt>'"
    }

    Context "When file is not found and Reason is absent" {
        BeforeAll {
            $script:file = Join-Path $TestDrive "file.txt"
        }

        # 01
        It "Does not throw" {
            { Invoke-Caller -Path $script:file } | Should -Not -Throw
        }
    }

    Context "When file exists and Reason is absent" {
        BeforeAll {
            $script:tempFile = Join-Path $TestDrive "temp.txt"
            [void](New-Item -Path $script:tempFile -ItemType File)
            $script:caughtError = $null

            try {
                Invoke-Caller -Path $script:tempFile
            }
            catch {
                $script:caughtError = $_
            }

            Assert-GuardThrew `
                -Caller "Invoke-Caller" `
                -CaughtError $script:caughtError `
                -Context $script:fileContext
        }

        # 02
        It "Throws FileAlreadyExistsException" {
            $script:caughtError.Exception | Should -BeOfType (
                [FileAlreadyExistsException]
            )
        }

        # 03
        It "Exception message contains the file path" {
            $filePath = [System.IO.Path]::GetFullPath($script:tempFile)

            $script:caughtError.Exception.Message | `
                Should -BeLike "*'$filePath'*"
        }

        # 04
        It "Error is attributed to the caller" {
            $script:caughtError.InvocationInfo.MyCommand.Name | `
                Should -Be "Invoke-Caller"
        }

        # 05
        It "FullyQualifiedErrorId is 'FileAlreadyExists,Invoke-Caller'" {
            $script:caughtError.FullyQualifiedErrorId | `
                Should -Be "FileAlreadyExists,Invoke-Caller"
        }
    }

    Context "When file exists and Reason is present" {
        BeforeAll {
            $script:tempFile = Join-Path $TestDrive "temp.txt"
            [void](New-Item -Path $script:tempFile -ItemType File)
            $script:reason = @(
                "Remove the existing file or choose a different path before"
                " running this command."
            ) -join ''
            $script:caughtError = $null

            try {
                Invoke-Caller `
                    -Path $script:tempFile `
                    -Reason $script:reason
            }
            catch {
                $script:caughtError = $_
            }

            Assert-GuardThrew `
                -Caller "Invoke-Caller" `
                -CaughtError $script:caughtError `
                -Context "$script:fileContext, with Reason"
        }

        # 06
        It "ErrorDetails contains Reason" {
            $script:caughtError.ErrorDetails.Message | `
                Should -BeLike "*$($script:reason)"
        }
    }
}
