Describe "Write-LogFile" -Tag "Write-LogFile", "Write-Log*" {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Private\Write-LogFile.ps1"

        Mock Get-Date {
            return "2000-01-01 12:00:00"
        }

        function Get-FirstLogLine {
            param([string]$Path)
            return Get-Content $Path | Select-Object -First 1
        }
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
            Write-LogFile `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $script:logFile | Should -Exist
        }

        It "Appends entries to existing log file" {
            Write-LogFile `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile
            Write-LogFile `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $lines = Get-Content $script:logFile
            $lines.Count | Should -Be 2
        }
    }

    Context "Log entry format" {
        It "Has timestamp prefix" {
            Write-LogFile `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $firstLine = Get-FirstLogLine $script:logFile
            $firstLine | Should -Match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} '
        }

        It "Contains the message" {
            Write-LogFile `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $firstLine = Get-FirstLogLine $script:logFile
            $firstLine | Should -Match 'A test message$'
        }

        It "Contains level '<Level>' in uppercase" -TestCases @(
            @{ Level = "Info"; Expected = "INFO" }
            @{ Level = "Warn"; Expected = "WARN" }
            @{ Level = "Error"; Expected = "ERROR" }
            @{ Level = "Debug"; Expected = "DEBUG" }
        ) {
            Write-LogFile `
                -Level $Level `
                -Message "A test message" `
                -Path $script:logFile

            $firstLine = Get-FirstLogLine $script:logFile
            $firstLine | Should -Match " $Expected`t"
        }

        It "Has correct full format without Source" {
            Write-LogFile `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $firstLine = Get-Content $script:logFile | Select-Object -First 1
            $firstLine | Should -Match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} INFO\tA test message$'
        }

        It "Has correct full format with Source" {
            Write-LogFile `
                -Level Info `
                -Message "A test message" `
                -Source "MyFunction" `
                -Path $script:logFile

            $firstLine = Get-Content $script:logFile | Select-Object -First 1
            $firstLine | Should -Match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} INFO\tMyFunction: A test message$'
        }
    }

    Context "Source label" {
        It "Contains source label when Source is provided" {
            Write-LogFile `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile `
                -Source "MyFunction"

            $firstLine = Get-FirstLogLine $script:logFile
            $firstLine | Should -Match " INFO`tMyFunction: A test message$"
        }

        It "Omits source label when Source is not provided" {
            Write-LogFile `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $firstLine = Get-FirstLogLine $script:logFile
            $firstLine | Should -Match " INFO`tA test message$"
        }

        It "Does not include source label when Source is empty or whitespace" -TestCases @(
            @{ Value = "" }
            @{ Value = "   " }
        ) {
            Write-LogFile `
                -Level Info `
                -Message "A test message" `
                -Source $Value `
                -Path $script:logFile

            $firstLine = Get-Content $script:logFile | Select-Object -First 1
            $firstLine | Should -Match " INFO`tA test message$"
        }
    }

    Context "Input validation" {
        It "Throws on invalid level" {
            {
                Write-LogFile `
                    -Level "Invalid" `
                    -Message "A test message" `
                    -Path $script:logFile
            } | Should -Throw
        }

        It "Throws when Path is not provided" {
            {
                Write-LogFile -Level Info -Message "A test message" -Path $null
            } | Should -Throw
        }

        It "Throws when Path is empty or whitespace" -TestCases @(
            @{ Value = "" }
            @{ Value = "   " }
        ) {
            {
                Write-LogFile -Level Info -Message "A test message" -Path $Value
            } | Should -Throw
        }
    }

    Context "Rapid sequential writes" {
        It "Preserves all entries across multiple writes" {
            $iterate = 5

            1..$iterate | ForEach-Object {
                Write-LogFile `
                    -Level Info `
                    -Message "A test message" `
                    -Path $script:logFile
            }

            $lines = Get-Content $script:logFile
            $lines.Count | Should -Be $iterate
        }
    }
}
