Describe "Assert-ParentDirectoryExists" -Tag "Assert-ParentDirectoryExists", "Assert-*" {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Public\Assert-ParentDirectoryExists.ps1"

        function Invoke-Caller {
            [CmdletBinding()]
            param ([string]$Path)
            Assert-ParentDirectoryExists -Path $Path -Cmdlet $PSCmdlet
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
