Describe "Assert-FileExists" -Tag "Assert-FileExists", "Assert-*" {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Public\Assert-FileExists.ps1"

        # Minimal advanced function to capture $PSCmdlet from a real caller context
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
            } | Should -Throw -ExceptionType ([System.IO.FileNotFoundException])
        }

        It "Error message contains the full path" {
            $fullPath = [System.IO.Path]::GetFullPath($script:path)

            {
                Invoke-Caller -Path $script:path
            } | Should -Throw -ExpectedMessage "*$fullPath*"
        }

        It "Error message contains the file name" {
            $fileName = [System.IO.Path]::GetFileName($script:path)

            {
                Invoke-Caller -Path $script:path
            } | Should -Throw -ExpectedMessage "*$fileName*"
        }

        It "Error is attributed to the caller, not to Assert-FileExists" {
            try {
                Invoke-Caller -Path $script:path
            }
            catch {
                $_.InvocationInfo.MyCommand.Name | Should -Be "Invoke-Caller"
            }
        }
    }

    Context "When ExtraMessage is provided" {
        It "Error message contains the extra message" {
            $path = Join-Path $TestDrive "NonExistentFile.txt"
            $extraMessage = "Ensure the file has been created before running this command."

            {
                Invoke-Caller -Path $path -ExtraMessage $extraMessage
            } | Should -Throw -ExpectedMessage "*$extraMessage*"
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
