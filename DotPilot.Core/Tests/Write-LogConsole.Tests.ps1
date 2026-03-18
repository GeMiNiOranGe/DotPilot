Describe "Write-LogConsole" -Tag "Write-LogConsole", "Write-Log*" {
    $ValidLevels = @(
        @{ Level = "Info" }
        @{ Level = "Warn" }
        @{ Level = "Error" }
        @{ Level = "Debug" }
    )

    BeforeAll {
        . "$PSScriptRoot\..\Src\Enums\LogLevel.ps1"
        . "$PSScriptRoot\..\Src\Private\Write-LogConsole.ps1"

        Mock Write-Host {}
    }

    Context "Color theming" {
        It "Uses correct background color for level '<Level>'" -TestCases @(
            @{ Level = "Info"; ExpectedBg = "Cyan" }
            @{ Level = "Warn"; ExpectedBg = "Yellow" }
            @{ Level = "Error"; ExpectedBg = "Red" }
            @{ Level = "Debug"; ExpectedBg = "White" }
        ) {
            Write-LogConsole -Level $Level -Message "A test message"

            Should -Invoke Write-Host -ParameterFilter {
                $BackgroundColor -eq $ExpectedBg
            }
        }

        It "Uses black foreground color for level '<Level>'" -TestCases $ValidLevels {
            Write-LogConsole -Level $Level -Message "A test message"

            Should -Invoke Write-Host -ParameterFilter {
                $ForegroundColor -eq "Black"
            }
        }
    }

    Context "Output content" {
        It "Writes label '<Level>' in lowercase" -TestCases $ValidLevels {
            Write-LogConsole -Level $Level -Message "A test message"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq $Level.ToLower()
            }
        }

        It "Writes message to console" {
            Write-LogConsole -Level "Info" -Message "A test message"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "A test message"
            }
        }
    }

    Context "Input validation" {
        It "Does not throw for level '<Level>'" -TestCases $ValidLevels {
            {
                Write-LogConsole -Level $Level -Message "A test message"
            } | Should -Not -Throw
        }

        It "Throws on invalid level" {
            {
                Write-LogConsole -Level "Invalid" -Message "A test message"
            } | Should -Throw
        }
    }
}
