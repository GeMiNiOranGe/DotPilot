Describe "Write-LogFile" {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Public\Write-LogConsole.ps1"
        . "$PSScriptRoot\..\Src\Public\Write-LogFile.ps1"

        Mock Write-Host {}
    }

    BeforeEach {
        $script:logFile = Join-Path $TestDrive "test.log"
    }

    AfterEach {
        if ($script:logFile -and (Test-Path $script:logFile)) {
            Remove-Item $script:logFile
        }
    }

    Context "File handling" {
        It "Creates log file when it does not exist" {
            Write-LogFile -Level Info -Message "test" -OutputFile $script:logFile

            $script:logFile | Should -Exist
        }

        It "Appends entries to existing log file" {
            Write-LogFile -Level Info -Message "first" -OutputFile $script:logFile
            Write-LogFile -Level Info -Message "second" -OutputFile $script:logFile

            $lines = Get-Content $script:logFile
            $lines.Count | Should -Be 2
        }

        It "Does not create log file when OutputFile is not provided and module variable is not set" {
            Write-LogFile -Level Info -Message "test"

            $script:logFile | Should -Not -Exist
        }
    }

    Context "Log entry format" {
        It "Has timestamp prefix" {
            Write-LogFile -Level Info -Message "test" -OutputFile $script:logFile

            $line = Get-Content $script:logFile
            $line | Should -Match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} '
        }

        It "Contains level '<Level>' in uppercase" -TestCases @(
            @{ Level = "Info"; Expected = "INFO" }
            @{ Level = "Warn"; Expected = "WARN" }
            @{ Level = "Error"; Expected = "ERROR" }
            @{ Level = "Debug"; Expected = "DEBUG" }
        ) {
            Write-LogFile -Level $Level -Message "test" -OutputFile $script:logFile

            $line = Get-Content $script:logFile
            $line | Should -Match " $Expected`t"
        }

        It "Contains the message" {
            Write-LogFile -Level Info -Message "hello world" -OutputFile $script:logFile

            $line = Get-Content $script:logFile
            $line | Should -Match 'hello world$'
        }
    }

    Context "Source label" {
        It "Contains source label when Source is provided" {
            Write-LogFile -Level Info -Message "hello" -OutputFile $script:logFile -Source "MyFunction"

            $line = Get-Content $script:logFile
            $line | Should -Match 'MyFunction: hello$'
        }

        It "Does not contain source label when Source is not provided" {
            Write-LogFile -Level Info -Message "hello" -OutputFile $script:logFile

            $line = Get-Content $script:logFile
            $line | Should -Not -Match '\['
        }
    }

    Context "Input validation" {
        It "Throws on invalid level" {
            { Write-LogFile -Level "Invalid" -Message "test" -OutputFile $script:logFile } | Should -Throw
        }
    }
}
