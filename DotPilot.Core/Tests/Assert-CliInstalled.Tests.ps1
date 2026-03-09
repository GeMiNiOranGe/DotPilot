Describe "Assert-CliInstalled" {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Classes\CliToolNotInstalledException.ps1"
    }

    It "Throws 'CliToolNotInstalled'" {
        {
            [CmdletBinding()]
            param()

            . "$PSScriptRoot\..\Src\Public\Assert-CliInstalled.ps1"
            Assert-CliInstalled -Name "CliToolNameNotInstalled" -Cmdlet $PSCmdlet
        } | Should -Throw -ErrorId "CliToolNotInstalled"
    }

    It "Does not throw when command is installed" {
        {
            [CmdletBinding()]
            param()

            . "$PSScriptRoot\..\Src\Public\Assert-CliInstalled.ps1"
            Assert-CliInstalled -Name "pwsh" -Cmdlet $PSCmdlet
        } | Should -Not -Throw
    }
}
