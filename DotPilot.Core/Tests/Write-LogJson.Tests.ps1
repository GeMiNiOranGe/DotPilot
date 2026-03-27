Describe "Write-LogJson" -Tag "Write-LogJson", "Write-Log*" {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Enums\LogLevel.ps1"
        . "$PSScriptRoot\..\Src\Private\Write-LogJson.ps1"

        Mock Get-Date {
            return "2000-01-01T12:00:00"
        }

        function Get-FirstLogEntry {
            param([string]$Path)
            return Get-Content $Path | Select-Object -First 1 | ConvertFrom-Json
        }
    }

    BeforeEach {
        $script:logFile = Join-Path $TestDrive "test.jsonl"
    }

    AfterEach {
        if ($script:logFile -and (Test-Path $script:logFile)) {
            Remove-Item $script:logFile
        }
    }

    Context "File handling" {
        It "Creates log file when it does not exist" {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $script:logFile | Should -Exist
        }

        It "Appends entries to existing log file" {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $lines = Get-Content $script:logFile
            $lines.Count | Should -Be 2
        }
    }

    Context "Log entry format" {
        It "Each line is valid JSON" {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $firstLine = Get-Content $script:logFile | Select-Object -First 1
            { $firstLine | ConvertFrom-Json } | Should -Not -Throw
        }

        It "Each line is a single line (no pretty-print)" {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $lines = Get-Content $script:logFile
            $lines.Count | Should -Be 1
        }

        It "Contains Timestamp field" {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $entry = Get-FirstLogEntry $script:logFile
            $entry.Timestamp | Should -Not -BeNullOrEmpty
        }

        It "Timestamp matches expected format" {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $firstLine = Get-Content $script:logFile | Select-Object -First 1
            $firstLine | Should -Match '"Timestamp":"2000-01-01T12:00:00"'
        }

        It "Contains the message" {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $entry = Get-FirstLogEntry $script:logFile
            $entry.Message | Should -Be "A test message"
        }

        It "Contains level '<Level>' in PascalCase" -TestCases @(
            @{ Level = "Info"; Expected = "Info" }
            @{ Level = "Warn"; Expected = "Warn" }
            @{ Level = "Error"; Expected = "Error" }
            @{ Level = "Debug"; Expected = "Debug" }
        ) {
            Write-LogJson `
                -Level $Level `
                -Message "A test message" `
                -Path $script:logFile

            $entry = Get-FirstLogEntry $script:logFile
            $entry.Level | Should -Be $Expected
        }

        It "Has correct field order: Timestamp, Level, Message" {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $firstLine = Get-Content $script:logFile | Select-Object -First 1
            $firstLine | Should -Match '"Timestamp".+"Level".+"Message"'
        }

        It "Has correct field order: Timestamp, Level, Message, Source when Source is provided" {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Source "MyFunction" `
                -Path $script:logFile

            $firstLine = Get-Content $script:logFile | Select-Object -First 1
            $firstLine | Should -Match '"Timestamp".+"Level".+"Message".+"Source"'
        }
    }

    Context "Source field" {
        It "Contains Source field when Source is provided" {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Source "MyFunction" `
                -Path $script:logFile

            $entry = Get-FirstLogEntry $script:logFile
            $entry.Source | Should -Be "MyFunction"
        }

        It "Omits Source field when Source is not provided" {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Path $script:logFile

            $entry = Get-FirstLogEntry $script:logFile
            $entry.PSObject.Properties.Name | Should -Not -Contain "Source"
        }

        It "Omits Source field when Source is empty or whitespace" -TestCases @(
            @{ Value = "" }
            @{ Value = "   " }
        ) {
            Write-LogJson `
                -Level Info `
                -Message "A test message" `
                -Source $Value `
                -Path $script:logFile

            $entry = Get-FirstLogEntry $script:logFile
            $entry.PSObject.Properties.Name | Should -Not -Contain "Source"
        }
    }

    Context "Input validation" {
        It "Throws on invalid level" {
            {
                Write-LogJson `
                    -Level "Invalid" `
                    -Message "A test message" `
                    -Path $script:logFile
            } | Should -Throw
        }

        It "Throws when Path is not provided" {
            {
                Write-LogJson -Level Info -Message "A test message" -Path $null
            } | Should -Throw
        }

        It "Throws when Path is empty or whitespace" -TestCases @(
            @{ Value = "" }
            @{ Value = "   " }
        ) {
            {
                Write-LogJson -Level Info -Message "A test message" -Path $Value
            } | Should -Throw
        }
    }

    Context "Rapid sequential writes" {
        It "Preserves all entries across multiple writes" {
            $iterate = 5

            1..$iterate | ForEach-Object {
                Write-LogJson `
                    -Level Info `
                    -Message "A test message" `
                    -Path $script:logFile
            }

            $lines = Get-Content $script:logFile
            $lines.Count | Should -Be $iterate
        }

        It "Each entry is valid JSON across multiple writes" {
            $iterate = 5

            1..$iterate | ForEach-Object {
                Write-LogJson `
                    -Level Info `
                    -Message "A test message" `
                    -Path $script:logFile
            }

            Get-Content $script:logFile | ForEach-Object {
                { $_ | ConvertFrom-Json } | Should -Not -Throw
            }
        }
    }
}
