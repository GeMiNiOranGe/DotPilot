Describe "Assert-CliInstalled" -Tag "Assert-CliInstalled", "Assert-*" {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Classes\CliToolNotInstalledException.ps1"
        . "$PSScriptRoot\..\Src\Public\Assert-CliInstalled.ps1"

        # Minimal advanced function to capture $PSCmdlet from a real caller context
        function Invoke-Caller {
            [CmdletBinding()]
            param ([string]$Name)
            Assert-CliInstalled -Name $Name -Cmdlet $PSCmdlet
        }
    }

    Context "When CLI tool is installed" {
        It "Does not throw when CLI tool is installed" {
            {
                Invoke-Caller -Name "pwsh"
            } | Should -Not -Throw
        }
    }

    Context "When CLI tool is not installed" {
        BeforeEach {
            $script:name = "CliToolNameNotInstalled"
        }

        It "Throws CliToolNotInstalledException when CLI tool is not installed" {
            {
                Invoke-Caller -Name $script:name
            } | Should -Throw -ExceptionType ([CliToolNotInstalledException])
        }

        It "Error is attributed to the caller, not to Assert-CliInstalled" {
            try {
                Invoke-Caller -Name $script:name
            }
            catch {
                $_.InvocationInfo.MyCommand.Name | Should -Be "Invoke-Caller"
            }
        }
    }
}
