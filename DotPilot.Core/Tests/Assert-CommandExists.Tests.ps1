Describe "Assert-CommandExists" -Tag "Assert-CommandExists", "Assert-*" {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Classes\CommandNotFoundException.ps1"
        . "$PSScriptRoot\..\Src\Public\Assert-CommandExists.ps1"

        function Invoke-Caller {
            [CmdletBinding()]
            param ([string]$Name, [string]$ExtraMessage)
            Assert-CommandExists `
                -Name $Name `
                -Cmdlet $PSCmdlet `
                -ExtraMessage $ExtraMessage
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

        It "Throws CommandNotFoundException when CLI tool is not installed" {
            {
                Invoke-Caller -Name $script:name
            } | Should -Throw -ExceptionType ([CommandNotFoundException])
        }

        It "Error is attributed to the caller, not to Assert-CommandExists" {
            try {
                Invoke-Caller -Name $script:name
            }
            catch {
                $_.InvocationInfo.MyCommand.Name | Should -Be "Invoke-Caller"
            }
        }

        It "Error message contains the CLI tool name" {
            {
                Invoke-Caller -Name $script:name
            } | Should -Throw -ExpectedMessage "*'$($script:name)'*"
        }

        It "ErrorRecord has FullyQualifiedErrorId of 'CommandNotFound'" {
            {
                Invoke-Caller -Name $script:name
            } | Should -Throw -ErrorId "CommandNotFound,Invoke-Caller"
        }
    }

    Context "When ExtraMessage is provided" {
        It "Error message contains the extra message" {
            $extraMessage = "Make sure the .NET SDK is installed."

            {
                Invoke-Caller `
                    -Name "CliToolNameNotInstalled" `
                    -ExtraMessage $extraMessage
            } | Should -Throw -ExpectedMessage "*$extraMessage"
        }
    }
}
