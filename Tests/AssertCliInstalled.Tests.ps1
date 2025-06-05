Describe "Assert-CliInstalled" {
    It "Throws 'CliToolNotInstalled'" {
        {
            [CmdletBinding()]
            param()

            . "$PSScriptRoot\..\Src\Private\AssertCliInstalled.ps1"
            Assert-CliInstalled -Name "CliToolNameNotInstalled" -Cmdlet $PSCmdlet
        } | Should -Throw -ErrorId "CliToolNotInstalled"
    }
}
