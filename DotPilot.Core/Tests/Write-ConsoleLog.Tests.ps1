Describe "Write-ConsoleLog" {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Public\Write-ConsoleLog.ps1"

        Mock Write-Host {}
    }

    Context "When level is valid" {
        It "Does not throw for level '<Level>'" -TestCases @(
            @{ Level = "Info" }
            @{ Level = "Warn" }
            @{ Level = "Error" }
            @{ Level = "Debug" }
        ) {
            { Write-ConsoleLog -Level $Level -Message "test" } | Should -Not -Throw
        }

        It "Writes label '<Level>' in lowercase" -TestCases @(
            @{ Level = "Info" }
            @{ Level = "Warn" }
            @{ Level = "Error" }
            @{ Level = "Debug" }
        ) {
            Write-ConsoleLog -Level $Level -Message "test"

            Should -Invoke Write-Host -ParameterFilter { $Object -eq $Level.ToLower() }
        }

        It "Writes message to console" {
            Write-ConsoleLog -Level "Info" -Message "hello world"

            Should -Invoke Write-Host -ParameterFilter { $Object -eq " hello world" }
        }

        It "Uses correct background color for level '<Level>'" -TestCases @(
            @{ Level = "Info"; ExpectedBg = "Cyan" }
            @{ Level = "Warn"; ExpectedBg = "Yellow" }
            @{ Level = "Error"; ExpectedBg = "Red" }
            @{ Level = "Debug"; ExpectedBg = "White" }
        ) {
            Write-ConsoleLog -Level $Level -Message "test"

            Should -Invoke Write-Host -ParameterFilter { $BackgroundColor -eq $ExpectedBg }
        }

        It "Uses black foreground color for all levels" -TestCases @(
            @{ Level = "Info" }
            @{ Level = "Warn" }
            @{ Level = "Error" }
            @{ Level = "Debug" }
        ) {
            Write-ConsoleLog -Level $Level -Message "test"

            Should -Invoke Write-Host -ParameterFilter { $ForegroundColor -eq "Black" }
        }
    }

    Context "When level is invalid" {
        It "Throws on invalid level" {
            { Write-ConsoleLog -Level "Invalid" -Message "test" } | Should -Throw
        }
    }
}
