Describe "Assert-DirectoryExists" -Tag "Assert-DirectoryExists" {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Public\Assert-DirectoryExists.ps1"

        # Minimal advanced function to capture $PSCmdlet from a real caller context
        function Invoke-Caller {
            [CmdletBinding()]
            param ([string]$Path)
            Assert-DirectoryExists -Path $Path -Cmdlet $PSCmdlet
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
            } | Should -Throw -ExceptionType ([System.IO.DirectoryNotFoundException])
        }

        It "Error message contains the full path" {
            $fullPath = [System.IO.Path]::GetFullPath($script:path)

            {
                Invoke-Caller -Path $script:path
            } | Should -Throw -ExpectedMessage "*$fullPath*"
        }

        It "Error message contains the directory name" {
            $directoryName = [System.IO.Path]::GetFileName($script:path)

            {
                Invoke-Caller -Path $script:path
            } | Should -Throw -ExpectedMessage "*$directoryName*"
        }

        It "Error is attributed to the caller, not to Assert-DirectoryExists" {
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
}
