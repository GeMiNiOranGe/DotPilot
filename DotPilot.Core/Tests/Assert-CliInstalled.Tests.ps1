Describe "Assert-CliInstalled" {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Classes\CliToolNotInstalledException.ps1"
        . "$PSScriptRoot\..\Src\Public\Assert-CliInstalled.ps1"
    }

    It "Throws when cli tool is not installed" {
        {
            [CmdletBinding()]
            param()

            Assert-CliInstalled -Name "CliToolNameNotInstalled" -Cmdlet $PSCmdlet
        } | Should -Throw -ExceptionType ([CliToolNotInstalledException])
    }

    It "Does not throw when command is installed" {
        {
            [CmdletBinding()]
            param()

            Assert-CliInstalled -Name "pwsh" -Cmdlet $PSCmdlet
        } | Should -Not -Throw
    }
}
