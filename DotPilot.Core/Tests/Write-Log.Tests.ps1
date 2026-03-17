Describe "Write-Log" -Tag "Write-Log", "Write-Log*" {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Private\Write-LogConsole.ps1"
        . "$PSScriptRoot\..\Src\Private\Write-LogFile.ps1"
        . "$PSScriptRoot\..\Src\Public\Write-Log.ps1"

        Mock Write-LogConsole {}
        Mock Write-LogFile {}
    }

    BeforeEach {
        $script:logFile = Join-Path $TestDrive "test.log"
    }

    Context "Console logging" {
        It "Calls Write-LogConsole when no file is specified" {
            Write-Log -Level Info -Message "A test message"
            Should -Invoke Write-LogConsole -Times 1 -Exactly
        }

        It "Calls Write-LogConsole even when -File is provided" {
            Write-Log -Level Info -Message "A test message" -File $script:logFile

            Should -Invoke Write-LogConsole -Times 1 -Exactly
            Should -Invoke Write-LogFile -Times 1 -Exactly
        }

        It "Passes correct parameters to Write-LogConsole" {
            Write-Log -Level Error -Message "A test message"

            Should -Invoke Write-LogConsole -ParameterFilter {
                $Level -eq "Error" -and
                $Message -eq "A test message"
            }
        }
    }

    Context "File logging" {
        It "Always calls Write-LogFile when -File is provided" {
            Write-Log -Level Info -Message "A test message" -File $script:logFile
            Should -Invoke Write-LogFile -Times 1 -Exactly
        }

        It "Does not call Write-LogFile when -File is not provided" {
            Write-Log -Level Info -Message "A test message"
            Should -Invoke Write-LogFile -Times 0
        }

        It "Passes correct parameters to Write-LogFile" {
            Write-Log `
                -Level Error `
                -Message "A test message" `
                -Source "MyFunction" `
                -File $script:logFile

            Should -Invoke Write-LogFile -ParameterFilter {
                $Level -eq "Error" -and
                $Message -eq "A test message" -and
                $Source -eq "MyFunction" -and
                $Path -eq $script:logFile
            }
        }

        It "Passes empty Source to Write-LogFile when -Source is not provided" {
            Write-Log `
                -Level Info `
                -Message "A test message" `
                -File $script:logFile

            Should -Invoke Write-LogFile -ParameterFilter {
                [string]::IsNullOrEmpty($Source)
            }
        }
    }

    Context "Input validation" {
        It "Throws on invalid level" {
            {
                Write-Log -Level "Invalid" -Message "A test message"
            } | Should -Throw
        }

        It "Throws when parent directory does not exist" {
            $nonExistentPath = Join-Path $TestDrive "NonExistentDir" "test.log"

            {
                Write-Log `
                    -Level Info `
                    -Message "A test message" `
                    -File $nonExistentPath
            } | Should -Throw -ExceptionType ([System.IO.DirectoryNotFoundException])
        }
    }
}
